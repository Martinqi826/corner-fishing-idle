extends SceneTree
## 无头回归测试：鱼数据完整性 + 抽取分布 + 钓鱼/经济端到端 + 鱼竿数值。
## 运行: godot_console --headless -s tools/validate_game.gd

var failures := 0


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	print("=== 数据检查 ===")
	_check_data()

	print("=== 抽取分布（rod=1，3000 次）===")
	_check_distribution()

	print("=== 端到端：钓鱼 / 经济 ===")
	await _check_gameplay()

	print("=== 鱼竿数值 ===")
	_check_rod()

	print("=== 存档 / 离线 ===")
	await _check_save()

	print("=== 结果: %d 失败 ===" % failures)
	quit(1 if failures > 0 else 0)


func _check_data() -> void:
	_assert(FishData.RARITY_NAMES.size() == 4, "应有 4 档稀有度")
	_assert(FishData.RARITY_COLORS.size() == 4, "应有 4 个稀有度颜色")
	var by_rarity := {0: 0, 1: 0, 2: 0, 3: 0}
	for id in FishData.FISH:
		var f: Dictionary = FishData.FISH[id]
		_assert(f.has("name") and f.has("rarity") and f.has("vmin") and f.has("vmax"),
			"%s 字段不全" % id)
		_assert(int(f["vmin"]) <= int(f["vmax"]), "%s vmin 应 <= vmax" % id)
		by_rarity[int(f["rarity"])] += 1
	for r in by_rarity:
		_assert(by_rarity[r] > 0, "稀有度 %d 至少应有一种鱼" % r)
	print("  鱼种数 %d，按稀有度分布 %s" % [FishData.FISH.size(), str(by_rarity)])


func _check_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts := {0: 0, 1: 0, 2: 0, 3: 0}
	var weights := FishData.weights_for_rod(1)
	for i in 3000:
		var id := FishData.roll_fish(weights, rng)
		counts[int(FishData.FISH[id]["rarity"])] += 1
	print("  分布 %s" % str(counts))
	_assert(counts[0] > counts[1], "普通应多于稀有")
	_assert(counts[1] > counts[3], "稀有应多于传说")
	_assert(counts[3] > 0, "3000 次内应至少出 1 次传说")


func _check_gameplay() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	_assert(game.coins == 0, "起始金币应为 0")

	# 直接驱动 200 次上鱼，验证经济与图鉴
	for i in 200:
		game._do_catch()
	_assert(game.coins > 0, "钓鱼 200 次后金币应 > 0")
	_assert(game.lifetime_catches == 200, "终身渔获应为 200，实际 %d" % game.lifetime_catches)
	_assert(game.lifetime_coins == game.coins, "终身金币应等于当前金币（无消费）")
	_assert(game.dex.size() >= 4, "图鉴至少收录 4 种鱼，实际 %d" % game.dex.size())
	print("  200 次渔获共得 %d 金币，图鉴收录 %d 种" % [game.coins, game.dex.size()])

	# 状态机：强制等待结束应进入咬钩
	game._begin_wait()
	game._state_t = 0.0
	game._process(0.016)
	_assert(game._state == game.ST_BITE, "等待结束应进入咬钩状态")

	game.queue_free()
	await process_frame


func _check_rod() -> void:
	var w1 := FishData.weights_for_rod(1)
	var w5 := FishData.weights_for_rod(5)
	_assert(w5[3] > w1[3], "鱼竿升级应提高传说权重")
	_assert(w5[0] < w1[0], "鱼竿升级应降低普通权重占比")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	# 同一条鱼，高等级竿增值更高（多次取均值）
	var sum1 := 0
	var sum5 := 0
	for i in 400:
		sum1 += FishData.value_of("carp", rng, 1)
		sum5 += FishData.value_of("carp", rng, 5)
	_assert(sum5 > sum1, "鱼竿升级应提高鱼价值")
	print("  鲤鱼均价 rod1=%.1f rod5=%.1f" % [sum1 / 400.0, sum5 / 400.0])


func _check_save() -> void:
	var path := ProjectSettings.globalize_path("user://corner_fishing_save.json")
	if FileAccess.file_exists("user://corner_fishing_save.json"):
		DirAccess.remove_absolute(path)
	# 写档
	var g1: Node = load("res://main.tscn").instantiate()
	g1.save_enabled = true
	root.add_child(g1)
	await process_frame
	g1.coins = 999
	g1.rod_level = 3
	g1.lifetime_coins = 5000
	g1.lifetime_catches = 120
	g1.dex = {"koi": true, "carp": true}
	g1._save()
	g1.queue_free()
	await process_frame
	# 读档（_ready 内自动 _load_save）
	var g2: Node = load("res://main.tscn").instantiate()
	g2.save_enabled = true
	root.add_child(g2)
	await process_frame
	_assert(g2.rod_level == 3, "存档应恢复鱼竿 Lv.3，实际 %d" % g2.rod_level)
	_assert(g2.coins >= 999, "存档应恢复金币 ≥999，实际 %d" % g2.coins)
	_assert(g2.dex.has("koi"), "存档应恢复图鉴 koi")
	print("  往返：金币 %d 鱼竿 Lv.%d 图鉴 %d 种" % [g2.coins, g2.rod_level, g2.dex.size()])
	_assert(g2._expected_value() > 0.0, "单条期望金币应 > 0")
	_assert(g2._offline_gain(3600.0) > 0, "离线 1 小时应有收益")
	print("  期望金币/条=%.1f，离线1h≈%d" % [g2._expected_value(), g2._offline_gain(3600.0)])
	g2.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("失败: " + msg)
