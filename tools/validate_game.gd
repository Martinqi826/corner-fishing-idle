extends SceneTree
## 无头回归测试：鱼数据 / 抽取分布 / 体重价格 / 背包与卖鱼 / 满包暂停 / 存档v2+v1迁移 / 离线产鱼。
## 运行: godot_console --headless -s tools/validate_game.gd

var failures := 0


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	print("=== 数据检查 ===")
	_check_data()

	print("=== 抽取分布（rod=1，20000 次）===")
	_check_distribution()

	print("=== 体重→价格 ===")
	_check_weight_value()

	print("=== 端到端：上鱼入包 / 满包暂停 ===")
	await _check_gameplay()

	print("=== 卖鱼 / 扩容 ===")
	await _check_sell_expand()

	print("=== 鱼竿数值 ===")
	_check_rod()

	print("=== 鱼饵 / 星级品质 ===")
	_check_quality()

	print("=== 成就系统 ===")
	await _check_achievements_feature()

	print("=== 流动鱼贩 ===")
	await _check_merchant()

	print("=== 存档 v2 往返 ===")
	await _check_save_v2()

	print("=== v1 老存档迁移 ===")
	await _check_migration_v1()

	print("=== 离线产鱼 ===")
	await _check_offline()

	print("=== 动态美术层 ===")
	await _check_effects()

	print("=== 结果: %d 失败 ===" % failures)
	quit(1 if failures > 0 else 0)


func _check_data() -> void:
	_assert(FishData.TIER_NAMES.size() == 6, "应有 6 档品阶")
	_assert(FishData.TIER_COLORS.size() == 6, "应有 6 个品阶颜色")
	var by_tier := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	for id in FishData.FISH:
		var f: Dictionary = FishData.FISH[id]
		for k in ["name", "tier", "wmin", "wmax", "vmin", "vmax"]:
			_assert(f.has(k), "%s 缺字段 %s" % [id, k])
		_assert(float(f["wmin"]) <= float(f["wmax"]), "%s wmin 应 <= wmax" % id)
		_assert(int(f["vmin"]) <= int(f["vmax"]), "%s vmin 应 <= vmax" % id)
		by_tier[int(f["tier"])] += 1
	for t in by_tier:
		_assert(by_tier[t] > 0, "品阶 %d 至少应有一种鱼" % t)
	print("  鱼种数 %d，按品阶分布 %s" % [FishData.FISH.size(), str(by_tier)])


func _check_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	var weights := FishData.weights_for_rod(1)
	for i in 20000:
		var id := FishData.roll_fish(weights, rng)
		counts[FishData.tier_of(id)] += 1
	print("  分布 %s" % str(counts))
	_assert(counts[0] > counts[1] and counts[1] > counts[2], "低阶应多于高阶")
	_assert(counts[4] > 0, "20000 次内应至少出 1 次传说")
	_assert(counts[5] > 0, "20000 次内应至少出 1 次神话")
	_assert(counts[5] < counts[4], "神话应少于传说")


func _check_weight_value() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var in_range := true
	var light_sum := 0.0
	var light_n := 0
	var heavy_sum := 0.0
	var heavy_n := 0
	for i in 2000:
		var c := FishData.roll_catch(rng, 1)
		var f: Dictionary = FishData.FISH[c["id"]]
		if c["w"] < float(f["wmin"]) - 0.011 or c["w"] > float(f["wmax"]) + 0.011:
			in_range = false
		_assert(int(c["v"]) >= 1, "鱼价值应 ≥1")
		# 只用鲤鱼对比轻重价差
		if c["id"] == "carp":
			var mid := (float(f["wmin"]) + float(f["wmax"])) * 0.5
			if c["w"] < mid:
				light_sum += c["v"]
				light_n += 1
			else:
				heavy_sum += c["v"]
				heavy_n += 1
	_assert(in_range, "体重应在鱼种区间内")
	if light_n > 10 and heavy_n > 10:
		_assert(heavy_sum / heavy_n > light_sum / light_n, "大鱼应比小鱼值钱")
		print("  鲤鱼均价：轻 %.1f (n=%d) vs 重 %.1f (n=%d)" % [
			light_sum / light_n, light_n, heavy_sum / heavy_n, heavy_n])


func _check_gameplay() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	_assert(game.coins == 0, "起始金币应为 0")
	_assert(game.inventory.is_empty(), "起始背包应为空")
	_assert(game._bag_capacity() == 20, "初始容量应为 20")

	# 上鱼入包，不产金币（lifetime_coins 只统计卖鱼；成就奖励单独计 coins 不计此）
	for i in 5:
		game._do_catch()
	_assert(game.inventory.size() == 5, "钓 5 条应入包 5 条，实际 %d" % game.inventory.size())
	_assert(game.lifetime_coins == 0, "钓鱼不应产生卖鱼收入")
	_assert(game.lifetime_catches == 5, "终身渔获应为 5")
	_assert(game.dex.size() >= 1, "图鉴应有收录")

	# 钓满
	for i in 25:
		game._do_catch()
	_assert(game.inventory.size() == 20, "背包应止步于容量 20，实际 %d" % game.inventory.size())
	_assert(game._bag_full(), "背包应为满")

	# 满包时等待结束不应进入咬钩
	game._begin_wait()
	game._state_t = 0.0
	game._process(0.016)
	_assert(game._state == game.ST_WAIT, "满包时应暂停（不进入咬钩）")

	# 腾出一格后恢复咬钩
	game._sell_one(0)
	game._state_t = 0.0
	game._process(0.016)
	_assert(game._state == game.ST_BITE, "腾格后应恢复咬钩")
	print("  入包/满包暂停/恢复 通过")

	game.queue_free()
	await process_frame


func _check_sell_expand() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame

	for i in 6:
		game._do_catch()
	# 收藏锁：锁两条，全卖应跳过
	game._toggle_lock(0)
	game._toggle_lock(2)
	_assert(bool(game.inventory[0]["lock"]), "上锁应生效")
	var locked_id: String = game.inventory[0]["id"]
	var total := 0
	for c in game.inventory:
		if not bool(c.get("lock", false)):
			total += int(c["v"])
	game._sell_one(0)
	_assert(game.inventory.size() == 6, "锁定的鱼不应被单卖")
	game._sell_all()
	# 用 lifetime_coins 校验卖鱼收入（不含成就奖励），避免被成就金币干扰
	_assert(game.lifetime_coins == total, "全卖应只卖未锁定，卖鱼收入应为 %d，实际 %d" % [total, game.lifetime_coins])
	_assert(game.inventory.size() == 2, "全卖后应留 2 条收藏，实际 %d" % game.inventory.size())
	_assert(str(game.inventory[0]["id"]) == locked_id, "留下的应是锁定那条")
	_assert(game.lifetime_coins == total, "累计卖鱼金额应为 %d" % total)
	game._toggle_lock(0)
	game._toggle_lock(1)
	game._sell_all()
	_assert(game.inventory.is_empty(), "解锁后全卖应清空")
	total = game.coins

	# 扩容
	game.coins = 200
	game._try_expand_bag()
	_assert(game.bag_level == 2, "扩容后 bag_level 应为 2")
	_assert(game._bag_capacity() == 25, "扩容后容量应为 25")
	_assert(game.coins == 200 - 100, "扩容应扣 100 金币，余 %d" % game.coins)
	# 钱不够不能扩
	game.coins = 0
	game._try_expand_bag()
	_assert(game.bag_level == 2, "金币不足不应扩容")
	print("  卖鱼/扩容 通过（容量 20→25，费用 100）")

	game.queue_free()
	await process_frame


func _check_rod() -> void:
	var w1 := FishData.weights_for_rod(1)
	var w8 := FishData.weights_for_rod(8)
	_assert(w8[4] > w1[4] and w8[5] > w1[5], "鱼竿升级应提高传说/神话权重")
	_assert(w8[0] < w1[0], "鱼竿升级应降低普通权重")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var sum1 := 0
	var sum8 := 0
	for i in 600:
		sum1 += int(FishData.roll_catch(rng, 1)["v"])
		sum8 += int(FishData.roll_catch(rng, 8)["v"])
	_assert(sum8 > sum1, "高级竿整体产出应更高")
	print("  整体均价 rod1=%.1f rod8=%.1f" % [sum1 / 600.0, sum8 / 600.0])


const TEST_SAVE := "user://test_save.json"


func _check_quality() -> void:
	_assert(FishData.QUALITY_NAMES.size() == 4 and FishData.QUALITY_MULTS.size() == 4,
		"星级应为 4 档")
	_assert(FishData.BAITS.size() == 4, "鱼饵应为 4 档")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var q0 := {0: 0, 1: 0, 2: 0, 3: 0}
	var q3 := {0: 0, 1: 0, 2: 0, 3: 0}
	for i in 8000:
		q0[FishData.roll_quality(0, rng)] += 1
		q3[FishData.roll_quality(3, rng)] += 1
	print("  星级分布(8000)：蚯蚓 %s ｜ 秘制饵 %s" % [str(q0), str(q3)])
	_assert(q0[0] > q3[0], "高级饵应减少无星渔获")
	_assert(q3[1] + q3[2] + q3[3] > q0[1] + q0[2] + q0[3], "高级饵应提高星级率")
	_assert(q3[3] > 0, "秘制饵 8000 次内应出完美★★★")
	_assert(q0[1] > q0[2] and q3[1] > q3[3], "星级越高越稀有")
	var v0 := 0
	var v3 := 0
	for i in 1500:
		v0 += int(FishData.roll_catch(rng, 1, 0)["v"])
		v3 += int(FishData.roll_catch(rng, 1, 3)["v"])
	_assert(v3 > v0, "高级饵整体产出应更高")
	print("  均价：蚯蚓 %.1f → 秘制饵 %.1f" % [v0 / 1500.0, v3 / 1500.0])


func _check_merchant() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	_assert(not game._merchant_active, "起始鱼贩不在场")
	# 放一条已知价值的鱼，平时按原价卖
	game.inventory = [{"id": "carp", "w": 2.0, "v": 100, "q": 0}]
	game._merchant_active = false
	_assert(game._sell_value(game.inventory[0]) == 100, "平时卖价应为原价")
	# 鱼贩在场 → ×1.5
	game._merchant_active = true
	_assert(game._sell_value(game.inventory[0]) == 150, "鱼贩在场卖价应 ×1.5")
	game._sell_one(0)
	_assert(game.lifetime_coins == 150, "鱼贩在场单卖应得 150，实际 %d" % game.lifetime_coins)
	# 计时切换：在场倒计时归零应离场并排下次
	game._merchant_active = true
	game._merchant_t = 0.0
	game._tick_merchant(0.1)
	_assert(not game._merchant_active, "在场结束应离场")
	_assert(game._merchant_t >= game.MERCHANT_GAP.x, "离场后应排下次出现")
	# 不在场倒计时归零应到场
	game._merchant_t = 0.0
	game._tick_merchant(0.1)
	_assert(game._merchant_active, "间隔结束应到场")
	_assert(game._merchant_t >= game.MERCHANT_DUR.x, "到场后应设停留时长")
	print("  鱼贩：×1.5 卖价 / 到场离场计时切换 通过")
	game.queue_free()
	await process_frame


func _check_achievements_feature() -> void:
	_assert(AchievementData.LIST.size() >= 12, "成就至少 12 项")
	var ids := {}
	for a in AchievementData.LIST:
		_assert(not ids.has(a["id"]), "成就 id 不应重复：%s" % a["id"])
		ids[a["id"]] = true
		for k in ["name", "desc", "kind", "n"]:
			_assert(a.has(k), "成就 %s 缺字段 %s" % [a["id"], k])
	var game: Node = load("res://main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	_assert(game.achievements_done.is_empty(), "起始无成就")
	# 钓一条 → first_cast 达成
	game._do_catch()
	_assert(game.achievements_done.has("first_cast"), "钓第一条应解锁初次垂钓")
	# 累计渔获里程碑（直接设计数，避开背包上限）
	game.lifetime_catches = 60
	game._check_achievements()
	_assert(game.achievements_done.has("catch_50"), "渔获 50+ 应解锁")
	# 鱼竿/鱼饵里程碑
	game.coins = 999999
	game.rod_level = 4
	game._try_upgrade_rod()  # → 5
	_assert(game.achievements_done.has("rod_5"), "鱼竿 Lv.5 应解锁")
	game.bait_level = 2
	game._try_upgrade_bait()  # → 3 秘制饵
	_assert(game.achievements_done.has("bait_master"), "秘制饵应解锁")
	# 奖励发放：清掉 species_10 已达成态，凑满 10 种再校验恰好 +500
	game.achievements_done.erase("species_10")
	game.dex.clear()
	for id in FishData.FISH.keys().slice(0, 10):
		game.dex[id] = {"n": 1, "w": 1.0}
	var before: int = game.coins
	game._check_achievements()
	_assert(game.achievements_done.has("species_10"), "图鉴 10 种应解锁")
	_assert(game.coins == before + 500, "species_10 应发 500 奖励，实得 %d" % (game.coins - before))
	game.queue_free()
	await process_frame
	# 静默补登：老存档（无 ach 字段）回屏不应触发成就 toast，但应标记已达成
	var path := ProjectSettings.globalize_path(TEST_SAVE)
	var old := {
		"ver": 4, "coins": 0, "rod_level": 6, "bag_level": 5, "bait": 0, "inv": [],
		"lt_coins": 0, "lt_catches": 400, "dex": {}, "opacity": 1.0,
		"ts": Time.get_unix_time_from_system() - 5.0,
	}
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f = null
	var g2: Node = load("res://main.tscn").instantiate()
	g2.save_enabled = true
	g2.save_path = TEST_SAVE
	root.add_child(g2)
	await process_frame
	_assert(g2.achievements_done.has("catch_300") and g2.achievements_done.has("rod_5"),
		"老存档回屏应静默补登已满足成就")
	_assert(g2.coins == 0, "静默补登不应补发奖励（金币应仍为 0）")
	print("  成就：解锁/奖励/老存档静默补登 通过（共 %d 项）" % AchievementData.LIST.size())
	g2.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)


func _check_save_v2() -> void:
	var path := ProjectSettings.globalize_path(TEST_SAVE)
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(path)
	var g1: Node = load("res://main.tscn").instantiate()
	g1.save_enabled = true
	g1.save_path = TEST_SAVE
	root.add_child(g1)
	await process_frame
	g1.coins = 777
	g1.rod_level = 4
	g1.bag_level = 3
	g1.bait_level = 2
	g1.inventory = [
		{"id": "koi", "w": 3.5, "v": 880, "q": 3, "lock": true},
		{"id": "crucian", "w": 0.4, "v": 5, "q": 0},
	]
	g1.dex = {"koi": {"n": 3, "w": 5.5}, "crucian": {"n": 12, "w": 0.58}}
	g1._save()
	g1.queue_free()
	await process_frame

	var g2: Node = load("res://main.tscn").instantiate()
	g2.save_enabled = true
	g2.save_path = TEST_SAVE
	root.add_child(g2)
	await process_frame
	_assert(g2.coins == 777, "v2 应恢复金币 777，实际 %d" % g2.coins)
	_assert(g2.bag_level == 3, "v2 应恢复 bag_level 3")
	_assert(g2.inventory.size() == 2, "v2 应恢复背包 2 条鱼，实际 %d" % g2.inventory.size())
	_assert(str(g2.inventory[0]["id"]) == "koi" and int(g2.inventory[0]["v"]) == 880,
		"背包条目应完整恢复")
	_assert(int(g2.inventory[0]["q"]) == 3, "星级应随存档恢复")
	_assert(bool(g2.inventory[0]["lock"]) and not bool(g2.inventory[1].get("lock", false)),
		"收藏锁应随存档恢复")
	_assert(g2.bait_level == 2, "鱼饵等级应随存档恢复")
	_assert(int(g2.dex["crucian"]["n"]) == 12 and absf(float(g2.dex["koi"]["w"]) - 5.5) < 0.01,
		"图鉴纪录（捕获数/最大体重）应随存档恢复")
	print("  v2 往返：金币 %d 背包 %d 条 容量 %d" % [g2.coins, g2.inventory.size(), g2._bag_capacity()])
	g2.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func _check_migration_v1() -> void:
	# 构造一份 v1 老存档（无 ver/inv/bag_level，dex 含已移除鱼种 arowana），ts=刚刚 → 不触发离线
	var v1 := {
		"coins": 321, "rod_level": 2, "lt_coins": 500, "lt_catches": 60,
		"dex": ["crucian", "carp", "arowana"], "opacity": 0.9,
		"ts": Time.get_unix_time_from_system() - 5.0,
	}
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(v1))
	f = null

	var g: Node = load("res://main.tscn").instantiate()
	g.save_enabled = true
	g.save_path = TEST_SAVE
	root.add_child(g)
	await process_frame
	_assert(g.coins == 321, "v1 迁移应保留金币 321，实际 %d" % g.coins)
	_assert(g.rod_level == 2, "v1 迁移应保留鱼竿 Lv.2")
	_assert(g.bag_level == 1, "v1 迁移 bag_level 应默认 1")
	_assert(g.inventory.is_empty(), "v1 迁移背包应为空")
	_assert(g.dex.has("crucian") and g.dex.has("carp"), "v1 迁移应保留有效图鉴")
	_assert(not g.dex.has("arowana"), "v1 迁移应丢弃已移除鱼种")
	_assert(int(g.dex["crucian"]["n"]) == 1 and float(g.dex["crucian"]["w"]) == 0.0,
		"旧版 id 列表应迁移为纪录结构（n=1, w=0）")
	# 纪录逻辑：前 5 条不播报，第 6 条更重才算破纪录
	g.dex["carp"] = {"n": 5, "w": 3.0}
	_assert(not g._dex_record("carp", 2.0), "未超纪录不应播报")
	_assert(g._dex_record("carp", 4.2), "超纪录且 n≥5 应播报")
	_assert(absf(float(g.dex["carp"]["w"]) - 4.2) < 0.01 and int(g.dex["carp"]["n"]) == 7,
		"纪录应更新（w=4.2, n=7）")
	g.dex["bass"] = {"n": 1, "w": 1.0}
	_assert(not g._dex_record("bass", 2.0), "n<5 即使超纪录也不播报")
	_assert(g.lifetime_coins == 500 and g.lifetime_catches == 60, "v1 迁移应保留终身统计")
	print("  v1→v2 迁移通过（金币/鱼竿/图鉴保留，背包默认空）")
	g.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func _check_offline() -> void:
	# ts=1 小时前 → 离线产鱼入篓，受容量限制
	var old := {
		"ver": 2, "coins": 0, "rod_level": 1, "bag_level": 1,
		"inv": [["ghostfish", 1.0, 10], ["carp", 2.0, 30]],  # 未知鱼种过滤；v2 三元组 → q=0
		"lt_coins": 0, "lt_catches": 0, "dex": [], "opacity": 1.0,
		"ts": Time.get_unix_time_from_system() - 3600.0,
	}
	var f := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f = null

	var g: Node = load("res://main.tscn").instantiate()
	g.save_enabled = true
	g.save_path = TEST_SAVE
	root.add_child(g)
	await process_frame
	_assert(g.inventory.size() > 0, "离线 1h 应有渔获")
	_assert(g.inventory.size() <= g._bag_capacity(), "离线渔获不应超过容量")
	_assert(g.coins == 0, "离线不应直接产金币")
	for c in g.inventory:
		_assert(str(c["id"]) != "ghostfish", "未知鱼种应在载入时被过滤")
	_assert(int(g.inventory[0].get("q", -1)) == 0, "v2 三元组迁移后 q 应为 0")
	print("  离线 1h 入篓 %d 条（容量 %d）" % [g.inventory.size(), g._bag_capacity()])
	g.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func _check_effects() -> void:
	var game: Node = load("res://main.tscn").instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	var p: Node2D = game.painter
	_assert(p.use_composite, "应处于合成主图模式")
	_assert(p._shimmer_tex.size() == 6, "水流高光应 6 帧，实际 %d" % p._shimmer_tex.size())
	_assert(p._mist_tex.size() == 3, "雾气应 3 层，实际 %d" % p._mist_tex.size())
	_assert(p._snow_tex.size() == 3, "雪粒应 3 层，实际 %d" % p._snow_tex.size())
	_assert(p._ripple_tex.size() == 4, "浮漂涟漪应 4 帧，实际 %d" % p._ripple_tex.size())
	_assert(p._glow_tex.size() == 4, "灯光呼吸应 4 帧，实际 %d" % p._glow_tex.size())
	_assert(p._wild_tex.size() == 4, "小动物应 4 种，实际 %d" % p._wild_tex.size())
	_assert(p._lantern.x > 440.0 and p._lantern.x < 490.0 and p._lantern.y > 300.0 and p._lantern.y < 355.0,
		"灯笼锚点应自动定位到主图灯笼区域，实际 %s" % str(p._lantern))
	# 小动物事件生命周期：fish 时长 0.7~1.1s，推进 2s 应结束并重排下次计时
	p._start_wild("fish")
	_assert(p._wild_kind == "fish", "应启动 fish 事件")
	_assert(not p._ripples.is_empty(), "鱼跃应触发涟漪")
	p._process(2.0)
	_assert(p._wild_kind == "", "事件应在时长结束后清除")
	_assert(p._wild_timer >= 45.0 and p._wild_timer <= 120.0, "下次事件应排在 45~120s 后")
	print("  动态层资源齐全（水光6/雾3/雪3/涟漪4/灯光4/动物4），事件生命周期通过")
	game.queue_free()
	await process_frame


func _assert(cond: bool, msg: String) -> void:
	if not cond:
		failures += 1
		printerr("失败: " + msg)
