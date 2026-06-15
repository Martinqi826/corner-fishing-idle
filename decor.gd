class_name Decor
## 陈列/装饰系统（新模块）：把心爱渔获摆上「陈列架」做桌面小景。
## 设计取向（见 docs/fishing-design-inspiration-20260614.html）：最契合"桌面摆件"本质的
## 健康非数值长线 + 收集深度 + 未来外观变现点；带一个小而封顶的卖价加成给参与理由（靠玩earned，非付费）。
## 状态在主节点 g 上（g.display：已陈列的鱼，最多 NUM_SLOTS 个）；纯静态 + g。

const NUM_SLOTS := 5
const VALUE_BONUS_PER := 0.01   # 每件陈列 +1% 全局卖价
const VALUE_BONUS_CAP := 0.05   # 封顶 +5%（防数值膨胀）


## 当前陈列加成（全局卖价系数增量），封顶。
static func value_bonus(g) -> float:
	return minf(VALUE_BONUS_CAP, VALUE_BONUS_PER * float(g.display.size()))


static func is_full(g) -> bool:
	return g.display.size() >= NUM_SLOTS


## 把鱼篓第 idx 条鱼移上陈列架（离开鱼篓、永久展示，可再取下）。带反馈/存档。
static func add_from_inventory(g, idx: int) -> void:
	if idx < 0 or idx >= g.inventory.size():
		return
	if is_full(g):
		g._play_ui("ui_error")
		g._toast("陈列架满了（最多 %d 件），先取下一件" % NUM_SLOTS, 2.0, Color(1.0, 0.6, 0.4))
		return
	var c: Dictionary = g.inventory[idx]
	g.inventory.remove_at(idx)
	g.display.append(c)
	g._play_sfx("upgrade")
	g._toast("把 %s 摆上了陈列架" % FishData.display_name(str(c["id"])), 2.0, Color(0.6, 0.82, 0.95))
	g._check_achievements()
	g._update_hud()
	g._refresh_panel()
	g._save()


## 取下陈列架第 slot 件，放回鱼篓（鱼篓满则提示，不丢失）。带反馈/存档。
static func remove_to_inventory(g, slot: int) -> void:
	if slot < 0 or slot >= g.display.size():
		return
	if g.inventory.size() >= g._bag_capacity():
		g._play_ui("ui_error")
		g._toast("鱼篓满了，先腾出一格再取下", 2.0, Color(1.0, 0.6, 0.4))
		return
	var c: Dictionary = g.display[slot]
	g.display.remove_at(slot)
	g.inventory.append(c)
	g._play_ui("ui_click")
	g._toast("把 %s 收回了鱼篓" % FishData.display_name(str(c["id"])), 1.8, Color(0.78, 0.74, 0.66))
	g._update_hud()
	g._refresh_panel()
	g._save()
