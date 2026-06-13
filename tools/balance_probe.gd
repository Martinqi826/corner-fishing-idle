extends SceneTree
## 数值平衡探针（只读分析，不改存档）：打印各鱼竿/鱼饵下的产出曲线与升级回本时间。
## 运行: godot_console --headless -s tools/balance_probe.gd

func _init() -> void:
	_run()


func _avg_interval(rod: int) -> float:
	return 5.25 * maxf(0.4, 1.0 - float(rod - 1) * 0.06) + 0.9


func _quality_mult(bait: int) -> float:
	var p: Array = FishData.BAITS[bait]["probs"]
	var p1 := float(p[1])
	var p2 := float(p[2])
	var p3 := float(p[3])
	var P0 := 1.0 - p1
	var P1 := p1 - p1 * p2
	var P2 := p1 * p2 - p1 * p2 * p3
	var P3 := p1 * p2 * p3
	return P0 * 1.0 + P1 * 1.8 + P2 * 4.0 + P3 * 8.0


func _base_ev(rod: int) -> float:
	var w := FishData.weights_for_rod(rod)
	var total := 0.0
	for r in w:
		total += w[r]
	var count := {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
	for id in FishData.FISH:
		count[FishData.tier_of(str(id))] += 1
	var ev := 0.0
	for id in FishData.FISH:
		var f: Dictionary = FishData.FISH[id]
		var r := int(f["tier"])
		var pr: float = (float(w[r]) / total) / float(count[r])
		ev += pr * (float(f["vmin"]) + float(f["vmax"])) * 0.5
	return ev * (1.0 + float(rod - 1) * 0.08)


func _rod_cost(level: int) -> int:
	return int(round(200.0 * pow(2.0, level - 1)))


func _run() -> void:
	await process_frame
	print("=== 产出曲线（金币/分钟，含品质期望）===")
	print("rod | bait蚯蚓 | bait秘制 | 间隔s")
	for rod in [1, 3, 5, 8]:
		var iv := _avg_interval(rod)
		var per_min := 60.0 / iv
		var ev0 := _base_ev(rod) * _quality_mult(0)
		var ev3 := _base_ev(rod) * _quality_mult(3)
		print("  %d | %6.1f | %6.1f | %.2f" % [rod, ev0 * per_min, ev3 * per_min, iv])

	print("=== 鱼竿升级回本（蚯蚓，纯主动）===")
	var cum := 0
	for lv in range(1, 9):
		var cost := _rod_cost(lv)
		cum += cost
		var gain_per_min := _base_ev(lv) * _quality_mult(0) * 60.0 / _avg_interval(lv)
		print("  Lv%d→%d 花费 %d（累计 %d）｜该级 %.1f 金/分 ｜单级回本 %.1f 分" % [
			lv, lv + 1, cost, cum, gain_per_min, float(cost) / maxf(gain_per_min, 1.0)])

	print("=== 鱼饵回本（rod=3 基准）===")
	var base_min := _base_ev(3) * 60.0 / _avg_interval(3)
	for bait in range(FishData.BAITS.size()):
		var b: Dictionary = FishData.BAITS[bait]
		var gain := base_min * _quality_mult(bait)
		var delta := gain - base_min * _quality_mult(0)
		var payback := float(int(b["cost"])) / maxf(delta, 0.01) if bait > 0 else 0.0
		print("  %s 花费 %d ｜ %.1f 金/分（比蚯蚓 +%.1f）｜回本 %.1f 分" % [
			str(b["name"]), int(b["cost"]), gain, delta, payback])

	print("=== 鱼钩回本（rod=5 秘制饵基准）===")
	var hbase := _base_ev(5) * _quality_mult(3) * 60.0 / _avg_interval(5)
	for hk in range(FishData.HOOKS.size()):
		var h: Dictionary = FishData.HOOKS[hk]
		var gain := hbase * (1.0 + float(h["double"]))
		var delta := gain - hbase
		var payback := float(int(h["cost"])) / maxf(delta, 0.01) if hk > 0 else 0.0
		print("  %s 花费 %d ｜双钩 %d%% ｜ %.0f 金/分（+%.0f）｜回本 %.1f 分" % [
			str(h["name"]), int(h["cost"]), int(float(h["double"]) * 100.0), gain, delta, payback])

	print("=== 背包扩容 vs 离线 8h 产出（rod=3 蚯蚓）===")
	var off8 := _base_ev(3) * _quality_mult(0) * (8.0 * 3600.0 / _avg_interval(3)) * 0.5
	print("  离线 8h 估值上限 ≈ %d 金币（实际受背包格数截断）" % int(off8))
	print("  背包容量/扩容费：20→25(100) 25→30(250) ... 50→55(25000)")

	print("=== 全装满 vs 全裸 产出对比 ===")
	var bare := _base_ev(1) * _quality_mult(0) * 60.0 / _avg_interval(1)
	var maxed := _base_ev(10) * _quality_mult(3) * (1.0 + float(FishData.HOOKS[FishData.HOOKS.size() - 1]["double"])) * 60.0 / _avg_interval(10)
	print("  全裸(rod1/蚯蚓/基础钩) %.0f 金/分 → 全满(rod10/秘制/双叉) %.0f 金/分（×%.1f）" % [
		bare, maxed, maxed / bare])
	quit()
