class_name UIPanels
## 面板/卡片/页签 UI 构建（从 main.gd 拆出，瘦身 + 为并行铺路）。
## 纯静态函数，状态仍在主节点 g 上（_panel/_catch_tab/_bag_sort 等）；main 留薄壳 wrapper。
## 约定与 SaveSystem 一致：第一参数 g = 主节点；样式工厂函数无需 g。
## 行为与原 main.gd 内嵌实现完全一致（仅做位置迁移 + g. 前缀）。

const CARD_SIZE := Vector2(520, 476)


# ============================ 面板开关 ============================

static func open_panel(g: CornerFishing, kind: String) -> void:
	if is_instance_valid(g._panel):
		g._panel_saved_pos = g._panel.position
	close_panel(g)
	var titles := {"catch": "垂钓手册", "rod": "鱼竿 · 升级", "set": "设置", "offline": "离线小结", "intro": "欢迎来到角落垂钓"}
	var card := make_card(g, str(titles.get(kind, "")))
	if kind != "offline" and kind != "intro" and g._panel_saved_pos != null:
		card.position = clamp_panel_position(g, g._panel_saved_pos, card.custom_minimum_size)
	var v: VBoxContainer = card.get_node("M/V")
	match kind:
		"catch": fill_bag_panel(g, v)
		"rod": fill_upgrades(g, v)
		"set": fill_settings(g, v)
		"offline": fill_offline_report(g, v)
		"intro": fill_intro(g, v)
	g.ui_root.add_child(card)
	g._panel = card
	g._panel_kind = kind
	set_interactive_full(g, true)


static func close_panel(g: CornerFishing) -> void:
	if is_instance_valid(g._panel):
		g._panel_saved_pos = g._panel.position
		g._panel.queue_free()
	g._panel = null
	g._panel_kind = ""
	g._panel_dragging = false
	set_interactive_full(g, false)


static func set_interactive_full(g: CornerFishing, full: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if full:
		var ws := Vector2(DisplayServer.window_get_size())
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array([
			Vector2(0, 0), Vector2(ws.x, 0), ws, Vector2(0, ws.y)]))
	else:
		g._update_passthrough()


# ============================ 样式工厂 ============================

static func panel_bg_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.13, 0.12, 0.94)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.88, 0.84, 0.74, 0.72)
	sb.shadow_color = Color(0, 0, 0, 0.32)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 6)  # 柔化：更大模糊、纯垂直（设计令牌 --shadow-panel 22px）
	return sb


static func paper_style(alpha := 0.88) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.91, 0.88, 0.78, alpha)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.96, 0.84, 0.46)
	return sb


static func dark_row_style(alpha := 0.52) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.21, 0.19, alpha)
	sb.set_corner_radius_all(9)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.86, 0.82, 0.70, 0.16)
	return sb


static func button_style(primary := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.66, 0.49, 0.25, 0.92) if primary else Color(0.36, 0.36, 0.32, 0.84)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.87, 0.55, 0.28) if primary else Color(0.84, 0.80, 0.68, 0.22)
	return sb


static func apply_button_skin(b: Button, primary := false) -> void:
	b.focus_mode = Control.FOCUS_NONE
	var normal := button_style(primary)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.78, 0.59, 0.31, 0.98) if primary else Color(0.46, 0.46, 0.40, 0.92)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.50, 0.36, 0.18, 0.98) if primary else Color(0.25, 0.25, 0.22, 0.95)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_color_override("font_color", Color(0.96, 0.91, 0.80) if not primary else Color(0.18, 0.15, 0.10))
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.46, 0.75))
	b.pressed.connect(func() -> void: Audio.play_ui("ui_click"))


# ============================ 卡片骨架 ============================

static func make_card(g: CornerFishing, title: String) -> Control:
	var p := PanelContainer.new()
	p.z_index = 50
	p.position = ((Vector2(g.WIN) - CARD_SIZE) * 0.5).round()
	p.custom_minimum_size = CARD_SIZE
	p.add_theme_stylebox_override("panel", panel_bg_style())
	var m := MarginContainer.new()
	m.name = "M"
	m.add_theme_constant_override("margin_left", 18)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_right", 18)
	m.add_theme_constant_override("margin_bottom", 16)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_STOP
	hb.custom_minimum_size = Vector2(0, 26)
	hb.add_theme_constant_override("separation", 8)
	hb.gui_input.connect(func(e: InputEvent) -> void: panel_drag_input(g, e, p))
	var tl := Label.new()
	tl.text = title
	tl.add_theme_font_size_override("font_size", 20)
	tl.add_theme_font_override("font", g._serif)  # 面板标题用衬线（设计令牌 --font-display）
	tl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78))
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(tl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(sp)
	var cb := Button.new()
	cb.text = "×"
	cb.flat = true
	cb.focus_mode = Control.FOCUS_NONE
	cb.tooltip_text = "关闭"
	cb.custom_minimum_size = Vector2(28, 26)
	cb.add_theme_font_size_override("font_size", 18)
	cb.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	cb.pressed.connect(func() -> void: Audio.play_ui("ui_click"))
	cb.pressed.connect(g._close_panel)
	hb.add_child(cb)
	v.add_child(hb)
	return p


static func clamp_panel_position(g: CornerFishing, pos: Vector2, size: Vector2) -> Vector2:
	var max_pos := Vector2(g.WIN) - size
	return Vector2(clampf(pos.x, 0.0, maxf(0.0, max_pos.x)),
		clampf(pos.y, 0.0, maxf(0.0, max_pos.y)))


static func panel_drag_input(g: CornerFishing, event: InputEvent, panel: Control) -> void:
	if not is_instance_valid(panel):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			g._panel_dragging = true
			g._panel_drag_offset = panel.get_global_mouse_position() - panel.position
		else:
			g._panel_dragging = false
			g._panel_saved_pos = panel.position
	elif event is InputEventMouseMotion and g._panel_dragging:
		panel.position = clamp_panel_position(g, panel.get_global_mouse_position() - g._panel_drag_offset,
			panel.custom_minimum_size)


# ============================ 鱼篓主面板 + 页签 ============================

static func fill_bag_panel(g: CornerFishing, v: VBoxContainer) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	var names := ["背包", "图鉴", "订单", "成就", "统计", "钓点", "鱼缸", "装备", "设置"]
	for i in range(names.size()):
		var tb := Button.new()
		tb.text = names[i]
		tb.custom_minimum_size = Vector2(40, 28)
		tb.add_theme_font_size_override("font_size", 13)
		apply_button_skin(tb, i == g._catch_tab)
		if i != g._catch_tab:
			tb.pressed.connect(g._set_catch_tab.bind(i))
		tabs.add_child(tb)
	v.add_child(tabs)
	match g._catch_tab:
		0: fill_bag_tab(g, v)
		1: fill_dex_tab(g, v)
		2: fill_order_tab(g, v)
		3: fill_ach_tab(g, v)
		4: fill_stats_tab(g, v)
		5: fill_spot_tab(g, v)
		6: fill_decor_tab(g, v)
		7: fill_upgrades(g, v)   # 装备：鱼竿/鱼饵/鱼钩升级（原主界面「竿」面板）
		_: fill_settings(g, v)   # 8 设置：音量/专注/不透明度/退出（原主界面「设」面板）


## 统计页：长期成长看板（只读）。
static func fill_stats_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var big_id := ""
	var big_w := 0.0
	for id in g.dex:
		if float(g.dex[id]["w"]) > big_w:
			big_w = float(g.dex[id]["w"])
			big_id = str(id)
	var biggest := "—"
	if big_id != "":
		biggest = "%s %.2fkg" % [FishData.display_name(big_id), big_w]
	# 🏆 英雄数字（设计令牌 --fs-numeral）：史上最大体重，衬线 + 等宽大号，仪式感。
	if big_id != "":
		var hero := PanelContainer.new()
		hero.add_theme_stylebox_override("panel", paper_style(0.95))
		var hm := MarginContainer.new()
		for s in ["left", "right"]:
			hm.add_theme_constant_override("margin_" + s, 10)
		for s in ["top", "bottom"]:
			hm.add_theme_constant_override("margin_" + s, 7)
		hero.add_child(hm)
		var hr := HBoxContainer.new()
		hr.add_theme_constant_override("separation", 10)
		hm.add_child(hr)
		hr.add_child(g._fish_icon(big_id, 52))
		var hinfo := VBoxContainer.new()
		hinfo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hinfo.add_theme_constant_override("separation", 1)
		var hd := Label.new()
		hd.text = "🏆 个人最佳 · 史上最大一条"
		hd.add_theme_font_size_override("font_size", 12)
		hd.add_theme_color_override("font_color", Color(0.80, 0.62, 0.26))
		hinfo.add_child(hd)
		var ht := FishData.tier_of(big_id)
		var wrow := HBoxContainer.new()
		wrow.add_theme_constant_override("separation", 3)
		var wnum := Label.new()
		wnum.text = "%.2f" % big_w
		wnum.add_theme_font_override("font", g._serif_num)
		wnum.add_theme_font_size_override("font_size", 30)
		wnum.add_theme_color_override("font_color", g._ui_tier_color(ht, true))
		wnum.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		wrow.add_child(wnum)
		var wunit := Label.new()
		wunit.text = "kg"
		wunit.add_theme_font_size_override("font_size", 13)
		wunit.add_theme_color_override("font_color", Color(0.46, 0.43, 0.37))
		wunit.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		wrow.add_child(wunit)
		hinfo.add_child(wrow)
		var hnm := Label.new()
		hnm.text = "%s%s" % [FishData.TIER_NAMES[ht], FishData.display_name(big_id)]
		hnm.add_theme_font_size_override("font_size", 13)
		hnm.add_theme_color_override("font_color", g._ui_tier_color(ht, true))
		hinfo.add_child(hnm)
		hr.add_child(hinfo)
		v.add_child(hero)
	var q := g.best_quality
	var q_txt: String = (str(FishData.QUALITY_NAMES[clampi(q, 0, 3)]) + "★".repeat(q)) if q > 0 else "普通"
	var rows := [
		["今日渔获", "%d 条" % g._today_catches()],
		["今日卖鱼收入", "%d 金币" % g._today_income()],
		["终身渔获", "%d 条" % g.lifetime_catches],
		["终身卖鱼收入", "%d 金币" % g.lifetime_coins],
		["当前金币", "%d" % g.coins],
		["图鉴收集", "%d / %d 种" % [g.dex.size(), FishData.FISH.size()]],
		["成就达成", "%d / %d" % [g.achievements_done.size(), AchievementData.LIST.size()]],
		["最高品相", q_txt],
		["最大渔获", biggest],
		["巨物纪录", "已钓到" if g.caught_giant else "尚无"],
		["累计专注", "%d 分钟" % int(g.focus_minutes_total)],
		["猫税", "被叼走 %d 条" % g.pet_steals],
		["鱼篓容量", "%d 格" % g._bag_capacity()],
		["当前装备", "鱼竿 Lv.%d · %s · %s" % [
			g.rod_level, FishData.BAITS[g.bait_level]["name"], FishData.HOOKS[g.hook_level]["name"]]],
	]
	var sc0 := ScrollContainer.new()
	sc0.custom_minimum_size = Vector2(0, 360)
	sc0.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	for r in rows:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", paper_style(0.86))
		var mg := MarginContainer.new()
		for s in ["left", "right"]:
			mg.add_theme_constant_override("margin_" + s, 10)
		for s in ["top", "bottom"]:
			mg.add_theme_constant_override("margin_" + s, 5)
		panel.add_child(mg)
		var row := HBoxContainer.new()
		mg.add_child(row)
		var nm := Label.new()
		nm.text = str(r[0])
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.add_theme_color_override("font_color", Color(0.46, 0.43, 0.37))
		row.add_child(nm)
		var val := Label.new()
		val.text = str(r[1])
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.add_theme_color_override("font_color", Color(0.26, 0.25, 0.22))
		row.add_child(val)
		list.add_child(panel)
	sc0.add_child(list)
	v.add_child(sc0)


# ============================ 钓点页 ============================

static func spot_species_progress(g: CornerFishing, sid: String) -> Array:
	var pool: Array = SpotData.pool_for(sid)
	var got := 0
	for fid in pool:
		if g.dex.has(fid):
			got += 1
	return [got, pool.size()]


static func fill_spot_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var stat := Label.new()
	stat.text = "钓点 · 已解锁 %d/%d" % [g.unlocked_spots.size(), SpotData.SPOTS.size()]
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 7)
	for sid in SpotData.SPOT_ORDER:
		list.add_child(spot_card(g, sid))
	sc.add_child(list)
	v.add_child(sc)


static func spot_card(g: CornerFishing, sid: String) -> Control:
	var unlocked := sid in g.unlocked_spots
	var is_cur := sid == g.current_spot
	var s: Dictionary = SpotData.get_spot(sid)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", paper_style(0.92) if unlocked else dark_row_style(0.44))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10 if side in ["left", "right"] else 8)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var nm := Label.new()
	nm.text = ("📍 " if is_cur else "") + str(s["name"])
	nm.add_theme_font_size_override("font_size", 17)
	nm.add_theme_font_override("font", g._serif)  # 钓点名用衬线（设计令牌 --font-display）
	nm.add_theme_color_override("font_color",
		Color(0.24, 0.30, 0.40) if unlocked else Color(0.70, 0.66, 0.58))
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(70, 32)
	if is_cur:
		btn.text = "当前"
		btn.disabled = true
		apply_button_skin(btn, false)
	elif unlocked:
		btn.text = "前往"
		apply_button_skin(btn, true)
		btn.pressed.connect(g._switch_spot.bind(sid))
	else:
		btn.text = "未解锁"
		btn.disabled = true
		apply_button_skin(btn, false)
	head.add_child(btn)
	box.add_child(head)
	var desc := Label.new()
	desc.text = str(s["desc"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(440, 0)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color",
		Color(0.46, 0.43, 0.37) if unlocked else Color(0.60, 0.57, 0.50))
	box.add_child(desc)
	var info := Label.new()
	info.add_theme_font_size_override("font_size", 12)
	if unlocked:
		var prog := spot_species_progress(g, sid)
		var line := "鱼种收集 %d/%d" % [prog[0], prog[1]]
		if is_cur:
			if g.active_event != "":
				line += "　·　当前事件：%s" % EventData.display_name(g.active_event)
			else:
				line += "　·　风平浪静"
		info.text = line
		info.add_theme_color_override("font_color", Color(0.40, 0.50, 0.40))
	else:
		info.text = "🔒 %s" % SpotData.unlock_text(sid)
		info.add_theme_color_override("font_color", Color(0.72, 0.58, 0.28))
	box.add_child(info)
	return panel


# ============================ 鱼缸页（活水族箱）============================

static func fill_decor_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var stat := Label.new()
	stat.text = "🐟 水族箱 · %d/%d 条　观赏卖价加成 +%d%%" % [
		g.display.size(), Decor.NUM_SLOTS, int(round(Decor.value_bonus(g) * 100.0))]
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)
	# 活水族箱视图：缸内鱼沿平滑路径游动，点鱼看纪录
	var aq := Aquarium.new()
	aq.name = "Aquarium"
	aq.setup(g)
	v.add_child(aq)
	var tip := Label.new()
	tip.text = "点缸里的鱼看它的纪录，也能把它捞回鱼篓。鎏金/七彩会发光。"
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", Color(0.70, 0.66, 0.58))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(440, 0)
	v.add_child(tip)
	v.add_child(HSeparator.new())
	# 从鱼篓放入
	var pick_lbl := Label.new()
	if Decor.is_full(g):
		pick_lbl.text = "水族箱满了（%d 条），先捞回一条再放新的。" % Decor.NUM_SLOTS
	else:
		pick_lbl.text = "从鱼篓挑一条放进缸（离开鱼篓、永久展示，可再捞回）："
	pick_lbl.add_theme_font_size_override("font_size", 12)
	pick_lbl.add_theme_color_override("font_color", Color(0.70, 0.66, 0.58))
	pick_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pick_lbl.custom_minimum_size = Vector2(440, 0)
	v.add_child(pick_lbl)
	if not Decor.is_full(g) and not g.inventory.is_empty():
		var sc := ScrollContainer.new()
		sc.custom_minimum_size = Vector2(0, 144)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 4)
		# 价值降序，便于挑“最值得养”的
		var idxs := g._sorted_bag_indices(false)
		for i in idxs:
			list.add_child(decor_pick_row(g, g.inventory[i], i))
		sc.add_child(list)
		v.add_child(sc)


static func decor_pick_row(g: CornerFishing, c: Dictionary, idx: int) -> Control:
	var tier := FishData.tier_of(str(c["id"]))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", dark_row_style(0.46))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6 if side in ["left", "right"] else 3)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	row.add_child(g._fish_icon(str(c["id"]), 32))
	var nm := Label.new()
	nm.text = "%s%s%s" % [FishData.size_tag(str(c["id"]), float(c["w"])),
		FishData.display_name(str(c["id"])), "★".repeat(int(c.get("q", 0)))]
	nm.clip_text = true
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.add_theme_font_size_override("font_size", 12)
	nm.add_theme_color_override("font_color", g._ui_tier_color(tier, false))
	row.add_child(nm)
	var meta := Label.new()
	meta.text = "%.2fkg" % float(c["w"])
	meta.add_theme_font_size_override("font_size", 11)
	meta.add_theme_color_override("font_color", Color(0.78, 0.68, 0.45))
	row.add_child(meta)
	var btn := Button.new()
	btn.text = "放入"
	btn.custom_minimum_size = Vector2(48, 28)
	apply_button_skin(btn, true)
	btn.pressed.connect(func() -> void: Decor.add_from_inventory(g, idx))
	row.add_child(btn)
	return panel


# ============================ 成就页 ============================

static func fill_ach_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var stat := Label.new()
	stat.text = "已达成 %d/%d" % [g.achievements_done.size(), AchievementData.LIST.size()]
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 330)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	var sorted: Array = AchievementData.LIST.duplicate()
	sorted.sort_custom(func(a, b):
		return g.achievements_done.has(a["id"]) and not g.achievements_done.has(b["id"]))
	for a in sorted:
		list.add_child(ach_row(g, a))
	sc.add_child(list)
	v.add_child(sc)


static func ach_row(g: CornerFishing, a: Dictionary) -> Control:
	var done: bool = g.achievements_done.has(a["id"])
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", paper_style(0.88) if done else dark_row_style(0.42))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 7 if side in ["left", "right"] else 5)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var mark := Label.new()
	mark.text = "✓" if done else "○"
	mark.custom_minimum_size = Vector2(20, 0)
	mark.add_theme_color_override("font_color",
		Color(0.45, 0.72, 0.40) if done else Color(0.5, 0.48, 0.43))
	row.add_child(mark)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	var nm := Label.new()
	nm.text = str(a["name"])
	nm.add_theme_font_size_override("font_size", 14)
	nm.add_theme_color_override("font_color",
		Color(0.28, 0.27, 0.24) if done else Color(0.74, 0.70, 0.62))
	info.add_child(nm)
	var ds := Label.new()
	ds.text = str(a["desc"])
	ds.add_theme_font_size_override("font_size", 11)
	ds.add_theme_color_override("font_color",
		Color(0.5, 0.47, 0.40) if done else Color(0.55, 0.52, 0.46))
	info.add_child(ds)
	row.add_child(info)
	var rw := int(a.get("reward", 0))
	if rw > 0:
		var rwl := Label.new()
		rwl.text = "+%d" % rw
		rwl.add_theme_font_size_override("font_size", 12)
		rwl.add_theme_color_override("font_color", Color(0.72, 0.58, 0.28))
		row.add_child(rwl)
	return panel


# ============================ 订单页 + 周目标 ============================

static func fill_order_tab(g: CornerFishing, v: VBoxContainer) -> void:
	g._ensure_daily_order()
	var target := str(g.daily_order.get("fish", ""))
	if not FishData.FISH.has(target):
		var bad := Label.new()
		bad.text = "今日订单生成失败。"
		bad.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
		v.add_child(bad)
		return
	var done := bool(g.daily_order.get("done", false))
	var need := int(g.daily_order.get("need", 1))
	var indices := g._daily_order_indices()
	var have := indices.size()
	var reward := g._daily_order_reward(indices)
	var kind := str(g.daily_order.get("kind", "species"))

	var stat := Label.new()
	stat.text = "每日订单 · %s" % str(g.daily_order.get("date", ""))
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 150)
	panel.add_theme_stylebox_override("panel", paper_style(0.90) if not done else dark_row_style(0.44))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10 if side in ["left", "right"] else 9)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	row.add_child(g._fish_icon(target, 64))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = g._order_title()
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color",
		Color(0.28, 0.25, 0.20) if not done else Color(0.74, 0.70, 0.62))
	info.add_child(title)
	var kind_label: String = {"species": "指定鱼种", "tier": "指定品阶", "weight": "大物", "perfect": "完美品质"}.get(kind, "")
	var desc := Label.new()
	var mtxt := "（收鱼郎在场 ×%.1f！）" % g.MERCHANT_MULT if g._merchant_active else ""
	desc.text = "%s订单 · 交付未上锁的符合渔获，按鱼价 ×%.1f 结算%s" % [kind_label, g.DAILY_ORDER_MULT, mtxt]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(220, 0)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color",
		Color(0.85, 0.6, 0.2) if g._merchant_active and not done
		else (Color(0.46, 0.42, 0.34) if not done else Color(0.64, 0.60, 0.54)))
	info.add_child(desc)
	var progress := Label.new()
	if done:
		progress.text = "今日已完成"
	else:
		progress.text = "可交付 %d/%d%s" % [have, need, " · 预计 +%d 金币" % reward if have >= need else ""]
	progress.add_theme_color_override("font_color",
		Color(0.84, 0.58, 0.18) if have >= need and not done else Color(0.56, 0.51, 0.42))
	info.add_child(progress)
	var sug := str(g.daily_order.get("spot", ""))
	if not done and have < need and SpotData.has(sug) and sug != g.current_spot and (sug in g.unlocked_spots):
		var sl := Label.new()
		sl.text = "建议去「%s」钓这条" % SpotData.display_name(sug)
		sl.add_theme_font_size_override("font_size", 12)
		sl.add_theme_color_override("font_color", Color(0.42, 0.56, 0.74))
		info.add_child(sl)
	row.add_child(info)

	var btn := Button.new()
	btn.text = "已完成" if done else "交付"
	btn.custom_minimum_size = Vector2(64, 34)
	btn.disabled = done or have < need
	apply_button_skin(btn, have >= need and not done)
	btn.pressed.connect(g._try_complete_daily_order)
	row.add_child(btn)
	v.add_child(panel)

	var hint := Label.new()
	hint.text = "锁定的目标鱼会留在鱼篓里，不会被订单交付。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.70, 0.66, 0.58))
	v.add_child(hint)
	fill_weekly_panel(g, v)


static func fill_weekly_panel(g: CornerFishing, v: VBoxContainer) -> void:
	g._ensure_weekly()
	v.add_child(HSeparator.new())
	var wdone := bool(g.weekly.get("done", false))
	var prog := g._weekly_progress()
	var target := int(g.weekly.get("target", 1))
	var stat := Label.new()
	stat.text = "本周挑战"
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", paper_style(0.90) if not wdone else dark_row_style(0.44))
	var mg := MarginContainer.new()
	for s in ["left", "right"]:
		mg.add_theme_constant_override("margin_" + s, 10)
	for s in ["top", "bottom"]:
		mg.add_theme_constant_override("margin_" + s, 9)
	panel.add_child(mg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	mg.add_child(box)
	var title := Label.new()
	title.text = g._weekly_desc()
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color",
		Color(0.28, 0.25, 0.20) if not wdone else Color(0.74, 0.70, 0.62))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(330, 0)
	box.add_child(title)
	var bar := ProgressBar.new()
	bar.max_value = target
	bar.value = mini(prog, target)
	bar.custom_minimum_size = Vector2(0, 18)
	box.add_child(bar)
	var row := HBoxContainer.new()
	var pl := Label.new()
	pl.text = "%d / %d　奖励 %d 金币" % [mini(prog, target), target, int(g.weekly.get("reward", 0))]
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.add_theme_font_size_override("font_size", 12)
	pl.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4) if not wdone else Color(0.6, 0.56, 0.5))
	row.add_child(pl)
	var btn := Button.new()
	btn.text = "已领取" if wdone else "领取"
	btn.custom_minimum_size = Vector2(64, 30)
	btn.disabled = wdone or prog < target
	apply_button_skin(btn, prog >= target and not wdone)
	btn.pressed.connect(g._try_claim_weekly)
	row.add_child(btn)
	box.add_child(row)
	v.add_child(panel)


# ============================ 背包页 ============================

static func fill_bag_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var cap := Label.new()
	cap.text = "%d/%d" % [g.inventory.size(), g._bag_capacity()]
	cap.custom_minimum_size = Vector2(46, 0)
	cap.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42) if g._bag_full() else Color(0.78, 0.74, 0.66))
	head.add_child(cap)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var total := 0
	var unlocked := 0
	var junk := 0
	for c in g.inventory:
		if not bool(c.get("lock", false)):
			total += g._sell_value(c)
			unlocked += 1
			if not g._order_matches(c):
				junk += 1
	var sell_junk := Button.new()
	sell_junk.text = "卖杂鱼"
	sell_junk.custom_minimum_size = Vector2(64, 28)
	sell_junk.disabled = junk == 0
	sell_junk.tooltip_text = "卖出 %d 条非订单、非收藏的鱼（保留订单目标鱼与锁定）" % junk
	apply_button_skin(sell_junk, false)
	sell_junk.pressed.connect(g._sell_junk)
	head.add_child(sell_junk)
	var sell_all := Button.new()
	sell_all.text = "全部卖出"
	sell_all.custom_minimum_size = Vector2(76, 28)
	sell_all.disabled = unlocked == 0
	sell_all.tooltip_text = "卖出 %d 条未上锁的鱼，+%d 金币%s（锁定的会留下）" % [
		unlocked, total, "（收鱼郎×1.5）" if g._merchant_active else ""]
	apply_button_skin(sell_all, true)
	sell_all.pressed.connect(g._sell_all)
	head.add_child(sell_all)
	if g.bag_level <= g.BAG_COSTS.size():
		var cost: int = g.BAG_COSTS[g.bag_level - 1]
		var expand := Button.new()
		expand.text = "扩容"
		expand.custom_minimum_size = Vector2(52, 28)
		expand.disabled = g.coins < cost
		expand.tooltip_text = "扩到 %d 格，花费 %d 金币" % [g.BAG_CAPS[g.bag_level], cost]
		apply_button_skin(expand, false)
		expand.pressed.connect(g._try_expand_bag)
		head.add_child(expand)
	v.add_child(head)

	if g.inventory.is_empty():
		var empty_panel := PanelContainer.new()
		empty_panel.custom_minimum_size = Vector2(0, 86)
		empty_panel.add_theme_stylebox_override("panel", paper_style(0.86))
		var empty_margin := MarginContainer.new()
		empty_margin.add_theme_constant_override("margin_left", 14)
		empty_margin.add_theme_constant_override("margin_top", 14)
		empty_margin.add_theme_constant_override("margin_right", 14)
		empty_margin.add_theme_constant_override("margin_bottom", 14)
		empty_panel.add_child(empty_margin)
		var empty := Label.new()
		empty.text = "鱼篓还是空的，等浮漂动一动。"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", Color(0.42, 0.40, 0.34))
		empty_margin.add_child(empty)
		v.add_child(empty_panel)
		return

	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 4)
	var sort_lbl := Label.new()
	sort_lbl.text = "排序"
	sort_lbl.add_theme_font_size_override("font_size", 12)
	sort_lbl.add_theme_color_override("font_color", Color(0.6, 0.57, 0.5))
	tools.add_child(sort_lbl)
	for m in g.BAG_SORT_NAMES.size():
		var sb := Button.new()
		sb.text = g.BAG_SORT_NAMES[m]
		sb.custom_minimum_size = Vector2(44, 24)
		sb.add_theme_font_size_override("font_size", 12)
		apply_button_skin(sb, m == g._bag_sort)
		if m != g._bag_sort:
			sb.pressed.connect(func(mm = m) -> void:
				g._bag_sort = mm
				g._open_panel("catch"))
		tools.add_child(sb)
	var fsp := Control.new()
	fsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(fsp)
	var filt := Button.new()
	filt.text = "订单鱼"
	filt.custom_minimum_size = Vector2(56, 24)
	filt.add_theme_font_size_override("font_size", 12)
	filt.tooltip_text = "只看今日订单的目标鱼"
	apply_button_skin(filt, g._bag_filter_order)
	filt.pressed.connect(func() -> void:
		g._bag_filter_order = not g._bag_filter_order
		g._open_panel("catch"))
	tools.add_child(filt)
	v.add_child(tools)

	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 306)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	var idxs := g._sorted_bag_indices(g._bag_filter_order)
	if idxs.is_empty():
		var none := Label.new()
		none.text = "没有符合条件的鱼"
		none.add_theme_color_override("font_color", Color(0.6, 0.57, 0.5))
		grid.add_child(none)
	for i in idxs:
		grid.add_child(fish_entry(g, g.inventory[i], i, false, true))
	sc.add_child(grid)
	v.add_child(sc)


static func fish_entry(g: CornerFishing, c: Dictionary, idx: int, featured := false, compact := false) -> Control:
	# 简约卡片：品阶由名字颜色编码（不再重复文字）；体型降为小角标；
	# 售价并入卖出键（「卖 17」一控件兼表价值与操作）；收藏锁为轻量幽灵钮，不抢权重。
	var tier := FishData.tier_of(c["id"])
	var vr := int(c.get("var", 0))
	var locked: bool = bool(c.get("lock", false))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(232, 54)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", dark_row_style(0.42))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)

	row.add_child(g._fish_icon(str(c["id"]), 34))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 1)
	# 名字行：变体只用一颗品色宝石「◆」标记（不再拼长前缀），鱼名最长 5 字双列也放得下；
	# 品阶由名字颜色编码，星级移到副行。
	var nm := Label.new()
	nm.text = ("◆" + FishData.display_name(c["id"])) if vr >= 1 else FishData.display_name(c["id"])
	nm.clip_text = true
	nm.add_theme_font_size_override("font_size", 13)
	nm.add_theme_color_override("font_color",
		FishData.variant_color(vr) if vr >= 1 else g._ui_tier_color(tier, false))
	if vr >= 1:
		nm.tooltip_text = "%s变体（价值 ×%.0f）" % [
			FishData.variant_label(vr).replace("·", ""), FishData.VARIANT_MULTS[vr]]
	info.add_child(nm)
	var meta := Label.new()
	var parts: Array[String] = []
	var q := int(c.get("q", 0))
	if q > 0:
		parts.append("★".repeat(q))
	var sztag := FishData.size_tag(c["id"], c["w"]).replace("·", "").strip_edges()
	if sztag != "":
		parts.append(sztag)
	parts.append("%.2fkg" % c["w"])
	meta.text = " · ".join(parts)
	meta.clip_text = true
	meta.add_theme_font_size_override("font_size", 11)
	meta.add_theme_color_override("font_color", Color(0.64, 0.61, 0.53))
	info.add_child(meta)
	row.add_child(info)

	# 收藏锁：幽灵切换钮，幽暗时退到背景，上锁时点亮金色
	var lk := Button.new()
	lk.text = "锁"
	lk.tooltip_text = "解除收藏锁" if locked else "上锁收藏（不会被卖出 / 交付）"
	lk.custom_minimum_size = Vector2(22, 40)
	lk.focus_mode = Control.FOCUS_NONE
	var lk_empty := StyleBoxEmpty.new()
	var lk_hover := dark_row_style(0.5)
	lk.add_theme_stylebox_override("normal", lk_empty)
	lk.add_theme_stylebox_override("pressed", lk_empty)
	lk.add_theme_stylebox_override("hover", lk_hover)
	lk.add_theme_stylebox_override("focus", lk_empty)
	lk.add_theme_color_override("font_color",
		Color(0.95, 0.78, 0.42) if locked else Color(0.50, 0.48, 0.43))
	lk.add_theme_color_override("font_hover_color", Color(0.95, 0.88, 0.70))
	lk.pressed.connect(func() -> void: Audio.play_ui("ui_click"))
	lk.pressed.connect(g._toggle_lock.bind(idx))
	row.add_child(lk)

	# 卖出键：金色主操作，价格直接写在键上
	var sell := Button.new()
	sell.text = "锁定" if locked else "卖 %d" % g._sell_value(c)
	sell.disabled = locked
	sell.custom_minimum_size = Vector2(54, 38)
	sell.add_theme_font_size_override("font_size", 13)
	apply_button_skin(sell, true)
	sell.pressed.connect(g._sell_one.bind(idx))
	row.add_child(sell)
	return panel


# ============================ 图鉴页 ============================

static func fill_dex_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var stat := Label.new()
	var vc := 0  # 已收集稀有变体数（每种鱼 ×3 稀有）
	for id in g.dex:
		var vm := int(g.dex[id].get("vmask", 0))
		for vi in range(1, FishData.VARIANT_NAMES.size()):
			if vm & (1 << vi):
				vc += 1
	var vtotal := FishData.FISH.size() * (FishData.VARIANT_NAMES.size() - 1)
	stat.text = "收集 %d/%d  ·  变体 %d/%d  ·  渔获 %d" % [
		g.dex.size(), FishData.FISH.size(), vc, vtotal, g.lifetime_catches]
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 330)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var ids := FishData.FISH.keys()
	ids.sort_custom(func(a, b): return FishData.tier_of(a) < FishData.tier_of(b))
	for id in ids:
		grid.add_child(dex_card(g, str(id)))
	sc.add_child(grid)
	v.add_child(sc)


static func dex_card(g: CornerFishing, id: String) -> Control:
	var known := g.dex.has(id)
	var tier := FishData.tier_of(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 98)
	panel.add_theme_stylebox_override("panel", paper_style(0.88) if known else dark_row_style(0.40))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)
	var icon := g._fish_icon(id, 42)
	icon.modulate = Color(1, 1, 1, 1.0 if known else 0.28)
	box.add_child(icon)
	var name := Label.new()
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.clip_text = true
	name.text = FishData.display_name(id) if known else "未发现"
	name.add_theme_font_size_override("font_size", 12)
	name.add_theme_color_override("font_color", g._ui_tier_color(tier, true) if known else Color(0.58, 0.56, 0.50))
	if known:
		badge_legible(name)   # 品阶色（尤其优良绿）在米黄纸背景上对比不足，加暖墨描边托起
	box.add_child(name)
	if known:
		var r: Dictionary = g.dex[id]
		var rec := Label.new()
		rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rec.clip_text = true
		rec.text = "×%d · 最大 %.2fkg" % [int(r["n"]), float(r["w"])] \
			if float(r["w"]) > 0.0 else "×%d" % int(r["n"])
		rec.add_theme_font_size_override("font_size", 10)
		rec.add_theme_color_override("font_color", Color(0.40, 0.36, 0.30))
		badge_legible(rec)
		box.add_child(rec)
		box.add_child(dex_badges(r))
	return panel


## 卡片小字描边：彩色徽章/纪录叠在浅米黄纸背景上时一眼可读
## （保留各自颜色语义，只补一圈暖墨细描边把字「托」起来）。
static func badge_legible(lbl: Label) -> void:
	lbl.add_theme_color_override("font_outline_color", Color(0.16, 0.12, 0.08, 0.92))
	lbl.add_theme_constant_override("outline_size", 2)


static func dex_badges(r: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	var n := int(r["n"])
	var col10 := Label.new()
	col10.add_theme_font_size_override("font_size", 10)
	if n >= 10:
		col10.text = "✦集齐"
		col10.add_theme_color_override("font_color", Color(0.97, 0.82, 0.38))
	else:
		col10.text = "%d/10" % n
		col10.add_theme_color_override("font_color", Color(0.62, 0.58, 0.50))
	badge_legible(col10)
	row.add_child(col10)
	if bool(r.get("big", false)):
		var b := Label.new()
		b.text = "巨"
		b.add_theme_font_size_override("font_size", 10)
		b.add_theme_color_override("font_color", Color(0.95, 0.70, 0.36))
		badge_legible(b)
		row.add_child(b)
	if bool(r.get("perf", false)):
		var p := Label.new()
		p.text = "完★"
		p.add_theme_font_size_override("font_size", 10)
		p.add_theme_color_override("font_color", Color(0.84, 0.66, 0.95))
		badge_legible(p)
		row.add_child(p)
	# 稀有变体收集点（斑斓/鎏金/七彩）：已见亮色圆点
	var vm := int(r.get("vmask", 0))
	for vi in range(1, FishData.VARIANT_NAMES.size()):
		if vm & (1 << vi):
			var d := Label.new()
			d.text = "●"
			d.add_theme_font_size_override("font_size", 10)
			d.add_theme_color_override("font_color", FishData.variant_color(vi))
			badge_legible(d)
			row.add_child(d)
	return row


# ============================ 升级页（鱼竿/鱼饵/鱼钩）============================

static func fill_upgrades(g: CornerFishing, v: VBoxContainer) -> void:
	var info := Label.new()
	info.text = "当前：鱼竿 Lv.%d" % g.rod_level
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.3, 0.3, 0.28))
	v.add_child(info)
	var desc := Label.new()
	desc.text = "升级效果：等待更短 · 稀有鱼更易上钩 · 鱼价 +%d%%" % int((g.rod_level - 1) * 8)
	desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.38))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(238, 0)
	v.add_child(desc)
	var cost := g._rod_cost()
	var costlbl := Label.new()
	costlbl.text = "升级费用：%d 金币" % cost
	costlbl.add_theme_color_override("font_color",
		Color(0.85, 0.6, 0.2) if g.coins >= cost else Color(0.7, 0.4, 0.4))
	v.add_child(costlbl)
	var btn := Button.new()
	btn.text = "升级鱼竿"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 34)
	apply_button_skin(btn, true)
	btn.pressed.connect(g._try_upgrade_rod)
	v.add_child(btn)
	v.add_child(HSeparator.new())
	var bait: Dictionary = FishData.BAITS[g.bait_level]
	var binfo := Label.new()
	binfo.text = "鱼饵：%s（%s）" % [bait["name"], bait["desc"]]
	binfo.add_theme_font_size_override("font_size", 16)
	binfo.add_theme_color_override("font_color", Color(0.3, 0.3, 0.28))
	v.add_child(binfo)
	var bdesc := Label.new()
	var p: Array = bait["probs"]
	bdesc.text = "上品★ %d%% · 极品★★ %.1f%% · 完美★★★ %.2f%%（价值 ×1.8/×4/×8）" % [
		int(float(p[1]) * 100.0), float(p[1]) * float(p[2]) * 100.0,
		float(p[1]) * float(p[2]) * float(p[3]) * 100.0]
	bdesc.add_theme_font_size_override("font_size", 12)
	bdesc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.38))
	bdesc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bdesc.custom_minimum_size = Vector2(238, 0)
	v.add_child(bdesc)
	if g.bait_level < FishData.BAITS.size() - 1:
		var nxt: Dictionary = FishData.BAITS[g.bait_level + 1]
		var bcost := int(nxt["cost"])
		var bcostlbl := Label.new()
		bcostlbl.text = "换用 %s：%d 金币" % [nxt["name"], bcost]
		bcostlbl.add_theme_color_override("font_color",
			Color(0.85, 0.6, 0.2) if g.coins >= bcost else Color(0.7, 0.4, 0.4))
		v.add_child(bcostlbl)
		var bbtn := Button.new()
		bbtn.text = "升级鱼饵"
		bbtn.focus_mode = Control.FOCUS_NONE
		bbtn.custom_minimum_size = Vector2(0, 34)
		apply_button_skin(bbtn, false)
		bbtn.pressed.connect(g._try_upgrade_bait)
		v.add_child(bbtn)
	v.add_child(HSeparator.new())
	var hook: Dictionary = FishData.HOOKS[g.hook_level]
	var hinfo := Label.new()
	hinfo.text = "鱼钩：%s（%s）" % [hook["name"], hook["desc"]]
	hinfo.add_theme_font_size_override("font_size", 16)
	hinfo.add_theme_color_override("font_color", Color(0.3, 0.3, 0.28))
	v.add_child(hinfo)
	var hdesc := Label.new()
	hdesc.text = "双钩几率 %d%%（一次钓上两条）" % int(float(hook["double"]) * 100.0)
	hdesc.add_theme_font_size_override("font_size", 12)
	hdesc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.38))
	v.add_child(hdesc)
	if g.hook_level < FishData.HOOKS.size() - 1:
		var hnxt: Dictionary = FishData.HOOKS[g.hook_level + 1]
		var hcost := int(hnxt["cost"])
		var hcostlbl := Label.new()
		hcostlbl.text = "换用 %s（双钩 %d%%）：%d 金币" % [
			hnxt["name"], int(float(hnxt["double"]) * 100.0), hcost]
		hcostlbl.add_theme_color_override("font_color",
			Color(0.85, 0.6, 0.2) if g.coins >= hcost else Color(0.7, 0.4, 0.4))
		v.add_child(hcostlbl)
		var hbtn := Button.new()
		hbtn.text = "升级鱼钩"
		hbtn.focus_mode = Control.FOCUS_NONE
		hbtn.custom_minimum_size = Vector2(0, 34)
		apply_button_skin(hbtn, false)
		hbtn.pressed.connect(g._try_upgrade_hook)
		v.add_child(hbtn)


# ============================ 设置 / 引导 / 离线小结 ============================

static func audio_slider(v: VBoxContainer, label: String, value: float, setter: Callable) -> void:
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.32))
	v.add_child(lbl)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = value
	sl.custom_minimum_size = Vector2(220, 18)
	sl.value_changed.connect(func(x: float) -> void: setter.call(x))
	v.add_child(sl)


static func fill_settings(g: CornerFishing, v: VBoxContainer) -> void:
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 8)
	var auto_lbl := Label.new()
	auto_lbl.text = "🔒 自动卖鱼"
	auto_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.46))
	auto_row.add_child(auto_lbl)
	var auto_tag := Label.new()
	auto_tag.text = "高级功能 · 敬请期待"
	auto_tag.add_theme_font_size_override("font_size", 12)
	auto_tag.add_theme_color_override("font_color", Color(0.72, 0.58, 0.28))
	auto_row.add_child(auto_tag)
	v.add_child(auto_row)
	v.add_child(HSeparator.new())
	var mute_row := HBoxContainer.new()
	mute_row.add_theme_constant_override("separation", 8)
	var mute_lbl := Label.new()
	mute_lbl.text = "静音"
	mute_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.32))
	mute_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mute_row.add_child(mute_lbl)
	var mute_btn := CheckButton.new()
	mute_btn.button_pressed = Audio.muted
	mute_btn.focus_mode = Control.FOCUS_NONE
	mute_btn.toggled.connect(func(on: bool) -> void:
		Audio.set_muted(on)
		if not on:
			Audio.start_ambience())
	mute_row.add_child(mute_btn)
	v.add_child(mute_row)
	audio_slider(v, "主音量", Audio.master_volume, Audio.set_master_volume)
	audio_slider(v, "音效", Audio.sfx_volume, Audio.set_sfx_volume)
	audio_slider(v, "环境音", Audio.ambience_volume, Audio.set_ambience_volume)
	v.add_child(HSeparator.new())
	var focus_row := HBoxContainer.new()
	focus_row.add_theme_constant_override("separation", 8)
	var focus_lbl := Label.new()
	focus_lbl.text = "专注模式（少打扰）"
	focus_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.32))
	focus_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_row.add_child(focus_lbl)
	var focus_btn := CheckButton.new()
	focus_btn.button_pressed = g.focus_mode
	focus_btn.focus_mode = Control.FOCUS_NONE
	focus_btn.toggled.connect(func(on: bool) -> void:
		g._set_focus(on)
		g._save())
	focus_row.add_child(focus_btn)
	v.add_child(focus_row)
	v.add_child(HSeparator.new())
	var ol := Label.new()
	ol.text = "不透明度"
	ol.add_theme_color_override("font_color", Color(0.35, 0.35, 0.32))
	v.add_child(ol)
	var sl := HSlider.new()
	sl.min_value = 0.3
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = g._opacity
	sl.custom_minimum_size = Vector2(220, 18)
	sl.value_changed.connect(g._set_opacity)
	v.add_child(sl)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	v.add_child(gap)
	var reset := Button.new()
	reset.text = "回到右下角"
	reset.focus_mode = Control.FOCUS_NONE
	apply_button_skin(reset, false)
	reset.pressed.connect(g._place_corner)
	v.add_child(reset)
	var quit := Button.new()
	quit.text = "退出游戏"
	quit.focus_mode = Control.FOCUS_NONE
	apply_button_skin(quit, false)
	quit.pressed.connect(g._quit_game)
	v.add_child(quit)


static func fill_intro(g: CornerFishing, v: VBoxContainer) -> void:
	var tips := [
		"· 浮标会自动钓鱼，钓到的鱼进「鱼篓」。",
		"· 点右下角 🐟 鱼篓：卖鱼换金币，还能看图鉴 / 订单 / 成就 / 统计。",
		"· 点 🎣 鱼竿：升级鱼竿(稀有度)、鱼饵(星级)、鱼钩(双钩)。",
		"· 点 ⚙ 设置：调音量、专注模式、退出。",
		"· 按住场景空白处，可把窗口拖到屏幕任意角落。",
		"· 留意金色「收鱼郎」和蓝色「鱼汛」——限时高收益时刻！",
	]
	for t in tips:
		var l := Label.new()
		l.text = t
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(360, 0)
		l.add_theme_color_override("font_color", Color(0.34, 0.32, 0.28))
		v.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	v.add_child(gap)
	var btn := Button.new()
	btn.text = "开始钓鱼"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 36)
	apply_button_skin(btn, true)
	btn.pressed.connect(func() -> void:
		g.seen_intro = true
		g._save()
		g._close_panel())
	v.add_child(btn)


static func fill_offline_report(g: CornerFishing, v: VBoxContainer) -> void:
	var rep := g._offline_report
	var hi := Label.new()
	hi.text = "欢迎回来，钓友"
	hi.add_theme_font_size_override("font_size", 16)
	hi.add_theme_color_override("font_color", Color(0.30, 0.30, 0.27))
	v.add_child(hi)
	var line := Label.new()
	line.text = "离线 %s，挂竿钓得 %d 条入篓%s" % [
		str(rep.get("dur", "")), int(rep.get("count", 0)),
		"（鱼篓已满）" if bool(rep.get("full", false)) else ""]
	line.add_theme_color_override("font_color", Color(0.42, 0.42, 0.38))
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size = Vector2(360, 0)
	v.add_child(line)
	var top: Dictionary = rep.get("top", {})
	if not top.is_empty():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", paper_style(0.9))
		var mg := MarginContainer.new()
		for s in ["left", "top", "right", "bottom"]:
			mg.add_theme_constant_override("margin_" + s, 8 if s in ["left", "right"] else 6)
		card.add_child(mg)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		mg.add_child(row)
		row.add_child(g._fish_icon(str(top["id"]), 48))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		var t := FishData.tier_of(str(top["id"]))
		var nm := Label.new()
		nm.text = "最值钱 · %s %s%s" % [FishData.TIER_NAMES[t],
			FishData.size_tag(str(top["id"]), float(top["w"])), FishData.display_name(str(top["id"]))]
		nm.add_theme_color_override("font_color", g._ui_tier_color(t, true))
		info.add_child(nm)
		var meta := Label.new()
		meta.text = "%.2fkg · %d 金币" % [float(top["w"]), int(top["v"])]
		meta.add_theme_font_size_override("font_size", 12)
		meta.add_theme_color_override("font_color", Color(0.5, 0.46, 0.4))
		info.add_child(meta)
		row.add_child(info)
		v.add_child(card)
	var total := Label.new()
	total.text = "合计可卖 ≈ %d 金币（已入鱼篓，去卖出变现）" % int(rep.get("value", 0))
	total.add_theme_color_override("font_color", Color(0.72, 0.58, 0.28))
	total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	total.custom_minimum_size = Vector2(360, 0)
	v.add_child(total)
	var ov_n := int(rep.get("overflow_n", 0))
	if ov_n > 0:
		var ov := Label.new()
		ov.text = "鱼篓装满后，另有 %d 条折价兑成 +%d 金币（已自动入账）" % [ov_n, int(rep.get("overflow_v", 0))]
		ov.add_theme_font_size_override("font_size", 12)
		ov.add_theme_color_override("font_color", Color(0.6, 0.52, 0.34))
		ov.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ov.custom_minimum_size = Vector2(360, 0)
		v.add_child(ov)
	var notable: Array = rep.get("notable", [])
	if not notable.is_empty():
		var nlbl := Label.new()
		nlbl.text = "其中珍稀 %d 条：" % notable.size()
		nlbl.add_theme_font_size_override("font_size", 12)
		nlbl.add_theme_color_override("font_color", Color(0.5, 0.47, 0.42))
		v.add_child(nlbl)
		var shown := 0
		for c in notable:
			if shown >= 6:
				break
			var t2 := FishData.tier_of(str(c["id"]))
			var rl := Label.new()
			rl.text = "· %s%s%s %.2fkg" % [FishData.quality_label(int(c.get("q", 0))),
				FishData.TIER_NAMES[t2] + "·", FishData.display_name(str(c["id"])), float(c["w"])]
			rl.add_theme_font_size_override("font_size", 12)
			rl.add_theme_color_override("font_color", g._ui_tier_color(t2, false))
			v.add_child(rl)
			shown += 1
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	v.add_child(gap)
	var go := Button.new()
	go.text = "去鱼篓看看"
	go.focus_mode = Control.FOCUS_NONE
	go.custom_minimum_size = Vector2(0, 34)
	apply_button_skin(go, true)
	go.pressed.connect(func() -> void:
		g._offline_report = {}
		g._catch_tab = 0
		g._open_panel("catch"))
	v.add_child(go)
