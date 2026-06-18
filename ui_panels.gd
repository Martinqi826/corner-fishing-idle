class_name UIPanels
## 面板/卡片/页签 UI 构建（从 main.gd 拆出，瘦身 + 为并行铺路）。
## 纯静态函数，状态仍在主节点 g 上（_panel/_catch_tab/_bag_sort 等）；main 留薄壳 wrapper。
## 约定与 SaveSystem 一致：第一参数 g = 主节点；样式工厂函数无需 g。
## 行为与原 main.gd 内嵌实现完全一致（仅做位置迁移 + g. 前缀）。

const CARD_SIZE := Vector2(520, 476)

static var font_bold: Font = null   # 由 main._setup_theme 注入：系统字体假粗体（CD 按钮/页签 weight 600-700）


# ============================ 面板开关 ============================

static func open_panel(g: CornerFishing, kind: String) -> void:
	var was_open := is_instance_valid(g._panel)   # 区分"首次打开"vs"切页签重建"
	if was_open:
		g._panel_saved_pos = g._panel.position
	# 重建面板时保持「全窗可交互」穿透不变——不要切回羽化椭圆。
	# 否则透明窗会被裁成椭圆一帧 → 点任意按钮都闪一下、露出场景羽化弧边。
	close_panel(g, true)
	var titles := {"catch": "垂钓手册", "rod": "鱼竿 · 升级", "set": "设置", "offline": "离线小结", "intro": "欢迎来到角落垂钓"}
	var title_str := str(titles.get(kind, ""))
	if kind == "fishdetail":
		title_str = FishData.display_name(str(g._detail_fish)) + " · 详情"
	elif kind == "catch" and g.display_mode != "immersive":
		title_str = _section_name(g._catch_tab)   # 带框 sheet 标题=区名（CD）
	var card := make_card(g, title_str)
	# 沉浸模式恢复拖拽位置；带框 sheet 固定锚位不恢复。
	if g.display_mode == "immersive" and kind != "offline" and kind != "intro" and g._panel_saved_pos != null:
		card.position = clamp_panel_position(g, g._panel_saved_pos, card.custom_minimum_size)
	var v: VBoxContainer = card.get_node("M/V")
	match kind:
		"catch": fill_bag_panel(g, v)
		"rod": fill_upgrades(g, v)
		"set": fill_settings(g, v)
		"offline": fill_offline_report(g, v)
		"intro": fill_intro(g, v)
		"fishdetail": fill_fish_detail(g, v)
	g.ui_root.add_child(card)
	g._panel = card
	g._panel_kind = kind
	set_interactive_full(g, true)
	# 带框 sheet 定位：首次打开从下方滑入；切页签直接就位（不重播动画，否则会停在屏下看不见）。
	if g.display_mode != "immersive":
		g._set_nav_solid(true)   # 底栏变暗，与 sheet 连成一片（无断裂）
		if was_open:
			card.position.y = 0.0
		else:
			_animate_sheet_in(g, card)


static func close_panel(g: CornerFishing, keep_interactive := false) -> void:
	if is_instance_valid(g._panel):
		g._panel_saved_pos = g._panel.position
		g._panel.queue_free()
	g._panel = null
	g._panel_kind = ""
	g._panel_dragging = false
	# keep_interactive=true 用于「重建面板」过渡，避免穿透 全窗→椭圆→全窗 抖动闪屏。
	# 真正关闭面板（× 按钮）走默认 false，恢复羽化椭圆穿透（窗外可穿透到桌面）。
	if not keep_interactive:
		set_interactive_full(g, false)
		if g.display_mode != "immersive":
			g._set_nav_solid(false)   # 真关闭 → 底栏恢复透明（浮场景）


static func set_interactive_full(g: CornerFishing, full: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	# 带框模式：整窗永远可交互、不做羽化椭圆裁剪。
	# （否则关面板会 set_interactive_full(false)→裁成椭圆，带框窗"显示不全"复发。）
	if g.display_mode != "immersive":
		var wsf := Vector2(DisplayServer.window_get_size())
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array([
			Vector2(0, 0), Vector2(wsf.x, 0), wsf, Vector2(0, wsf.y)]))
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
	sb.bg_color = DT.GLASS
	sb.set_corner_radius_all(DT.R_PANEL)
	sb.set_border_width_all(1)
	sb.border_color = DT.GLASS_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.32)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 6)  # --shadow-panel：软、纯垂直
	return sb


static func paper_style(alpha := 0.88) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(DT.PAPER_SOLID.r, DT.PAPER_SOLID.g, DT.PAPER_SOLID.b, alpha)
	sb.set_corner_radius_all(DT.R_CARD)
	sb.set_border_width_all(1)
	sb.border_color = DT.PAPER_BORDER
	return sb


static func dark_row_style(alpha := 0.52) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(DT.GLASS_ROW.r, DT.GLASS_ROW.g, DT.GLASS_ROW.b, alpha)
	sb.set_corner_radius_all(DT.R_CELL)
	sb.set_border_width_all(1)
	sb.border_color = DT.GLASS_ROW_BORDER
	return sb


static func button_style(primary := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = DT.BRONZE if primary else DT.BTN_SEC_BG
	sb.set_corner_radius_all(DT.R_ROW)
	sb.set_border_width_all(0)
	return sb


static func apply_button_skin(b: Button, primary := false) -> void:
	b.focus_mode = Control.FOCUS_NONE
	if font_bold != null:
		b.add_theme_font_override("font", font_bold)   # CD .btn weight 700
	var normal := button_style(primary)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = DT.BRONZE_HOVER if primary else DT.BTN_SEC_BG_HOVER
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = DT.BRONZE_PRESS if primary else Color(0.25, 0.25, 0.22, 0.95)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = DT.BTN_DISABLED_BG
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_color_override("font_color", DT.INK_ON_GOLD if primary else DT.BTN_SEC_FG)
	b.add_theme_color_override("font_disabled_color", DT.TEXT_FAINT_GLASS)
	b.pressed.connect(func() -> void: Audio.play_ui("ui_click"))


# CD .seg .tab —— pill 页签：未选=暗行+次字；选中=铜底深字（accent 可传品阶色）
static func apply_tab_skin(b: Button, active: bool, accent := DT.BRONZE) -> void:
	b.focus_mode = Control.FOCUS_NONE
	if font_bold != null:
		b.add_theme_font_override("font", font_bold)   # CD .seg .tab weight 600
	var normal := StyleBoxFlat.new()
	normal.set_corner_radius_all(DT.R_CHIP)
	normal.content_margin_left = 11
	normal.content_margin_right = 11
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	normal.bg_color = accent if active else DT.GLASS_ROW
	if not active:
		normal.set_border_width_all(1)
		normal.border_color = Color(0, 0, 0, 0)
	var hover := normal.duplicate() as StyleBoxFlat
	if not active:
		hover.bg_color = DT.GLASS_ROW_HOVER
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", normal)
	b.add_theme_color_override("font_color", DT.INK_ON_GOLD if active else DT.TEXT_MUTED_GLASS)
	b.add_theme_font_size_override("font_size", DT.FS_XS)
	b.pressed.connect(func() -> void: Audio.play_ui("ui_click"))


# CD .pill —— 小状态标签（非按钮）
static func make_pill(text: String, bg: Color, fg: Color, fs := DT.FS_2XS) -> Control:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(DT.R_CHIP)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", fg)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(l)
	return pc


# CD .progress —— 细进度条（圆角，金色填充）
static func make_progress(frac: float, fill := DT.GOLD, h := 7) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.show_percentage = false
	pb.min_value = 0.0
	pb.max_value = 1.0
	pb.value = clampf(frac, 0.0, 1.0)
	pb.custom_minimum_size = Vector2(0, h)
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = DT.GLASS_ROW
	bgs.set_corner_radius_all(DT.R_CHIP)
	var fgs := StyleBoxFlat.new()
	fgs.bg_color = fill
	fgs.set_corner_radius_all(DT.R_CHIP)
	pb.add_theme_stylebox_override("background", bgs)
	pb.add_theme_stylebox_override("fill", fgs)
	return pb


# ============================ 卡片骨架 ============================

## CD 式 sheet（带框模式）：覆盖舞台（底部导航以上）、从下方滑出、不可拖，内容居中列。
static func _make_sheet(g: CornerFishing, title: String) -> Control:
	var stage_h := float(g.WIN.y) - g.FRAMED_CONSOLE_H
	var p := PanelContainer.new()
	p.z_index = 50
	p.custom_minimum_size = Vector2(float(g.WIN.x), stage_h)
	p.size = Vector2(float(g.WIN.x), stage_h)
	p.position = Vector2(0, stage_h)   # 起始在舞台下方；open_panel 里 tween 滑上来
	var sb := StyleBoxFlat.new()
	sb.bg_color = DT.GLASS
	sb.corner_radius_top_left = DT.R_PANEL
	sb.corner_radius_top_right = DT.R_PANEL
	sb.border_width_top = 1
	sb.border_color = DT.GLASS_BORDER
	sb.shadow_color = Color(0, 0, 0, 0.30)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, -4)
	p.add_theme_stylebox_override("panel", sb)
	var m := MarginContainer.new()
	m.name = "M"
	m.add_theme_constant_override("margin_left", 28)   # 铺满整宽（CD 式 full-bleed），只留舒适内边距
	m.add_theme_constant_override("margin_right", 28)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 18)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", 10)
	m.add_child(v)
	# 头：衬线标题 + 关闭（sheet 不可拖）
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(0, 30)
	hb.add_theme_constant_override("separation", 8)
	var tl := Label.new()
	tl.text = title
	tl.add_theme_font_size_override("font_size", DT.FS_TITLE)
	tl.add_theme_font_override("font", g._serif)
	tl.add_theme_color_override("font_color", DT.TEXT_TITLE)
	tl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(tl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	var cb := Button.new()
	cb.text = "×"
	cb.flat = true
	cb.focus_mode = Control.FOCUS_NONE
	cb.custom_minimum_size = Vector2(30, 30)
	cb.add_theme_font_size_override("font_size", 18)
	cb.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	cb.pressed.connect(func() -> void: Audio.play_ui("ui_click"))
	cb.pressed.connect(g._close_panel)
	hb.add_child(cb)
	v.add_child(hb)
	return p


## 面板滑入动画：从舞台下方滑到顶部（CD .sheet 展开动画）。
static func _animate_sheet_in(g: CornerFishing, sheet: Control) -> void:
	var stage_h := float(g.WIN.y) - g.FRAMED_CONSOLE_H
	sheet.position = Vector2(0, stage_h)
	var tw := g.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(sheet, "position:y", 0.0, 0.30)


## 带框 sheet 标题（区名）：_catch_tab → 区名
static func _section_name(tab: int) -> String:
	match tab:
		0: return "鱼篓"
		1: return "图鉴"
		2: return "任务"
		5: return "钓点"
		6: return "鱼缸"
		7: return "装备"
		8: return "设置"
		_: return "垂钓手册"


static func make_card(g: CornerFishing, title: String) -> Control:
	if g.display_mode != "immersive":
		return _make_sheet(g, title)
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
	# 顶部页签仅沉浸模式保留；带框模式由底部导航唯一切区（CD：sheet 无顶部页签，标题=区名）。
	if g.display_mode == "immersive":
		var tabs := HBoxContainer.new()
		tabs.add_theme_constant_override("separation", DT.CHIP_GAP)
		var defs := [["鱼篓", 0], ["装备", 7], ["图鉴", 1], ["任务", 2], ["钓点", 5], ["鱼缸", 6], ["设置", 8]]
		for d in defs:
			var id: int = d[1]
			var tb := Button.new()
			tb.text = d[0]
			tb.add_theme_font_size_override("font_size", DT.FS_XS)
			apply_tab_skin(tb, id == g._catch_tab)
			if id != g._catch_tab:
				tb.pressed.connect(g._set_catch_tab.bind(id))
			tabs.add_child(tb)
		v.add_child(tabs)
	match g._catch_tab:
		0: fill_bag_tab(g, v)
		1: fill_dex_tab(g, v)
		2: fill_tasks_tab(g, v)
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
	stat.add_theme_font_size_override("font_size", DT.FS_XS)
	stat.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	v.add_child(stat)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 326)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL   # 填满 sheet 高度
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", DT.ROW_GAP)
	for sid in SpotData.SPOT_ORDER:
		list.add_child(spot_card(g, sid))
	sc.add_child(list)
	v.add_child(sc)


static func spot_card(g: CornerFishing, sid: String) -> Control:
	var unlocked := sid in g.unlocked_spots
	var is_cur := sid == g.current_spot
	var s: Dictionary = SpotData.get_spot(sid)
	var cell := PanelContainer.new()
	cell.clip_contents = true
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := dark_row_style(0.5)
	sb.set_corner_radius_all(DT.R_CARD)
	sb.set_border_width_all(2)
	sb.border_color = DT.GOLD if is_cur else DT.GLASS_ROW_BORDER
	cell.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	cell.add_child(col)

	# —— 顶部场景大图横幅（CD .sc-img）——
	var banner := Control.new()
	banner.custom_minimum_size = Vector2(0, 96)
	banner.clip_contents = true
	var imgpath := "res://assets/art/background/spot_%s.png" % str(s.get("bg_key", sid))
	if ResourceLoader.exists(imgpath):
		var img := TextureRect.new()
		img.texture = load(imgpath)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			img.modulate = Color(0.46, 0.46, 0.46)  # 锁定=灰暗
		banner.add_child(img)
	col.add_child(banner)

	# —— 下方信息体（CD .sc-body）——
	var body := MarginContainer.new()
	body.add_theme_constant_override("margin_left", 12)
	body.add_theme_constant_override("margin_right", 12)
	body.add_theme_constant_override("margin_top", 9)
	body.add_theme_constant_override("margin_bottom", 10)
	col.add_child(body)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	body.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var nm := Label.new()
	nm.text = str(s["name"])
	nm.add_theme_font_size_override("font_size", DT.FS_HEAD)
	nm.add_theme_font_override("font", g._serif)  # 钓点名衬线
	nm.add_theme_color_override("font_color", DT.TEXT_TITLE if unlocked else DT.TEXT_MUTED_GLASS)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(nm)
	if is_cur:
		head.add_child(make_pill("当前", DT.GOLD, DT.INK_ON_GOLD))
	elif unlocked:
		var btn := Button.new()
		btn.text = "前往"
		btn.custom_minimum_size = Vector2(64, 30)
		apply_button_skin(btn, true)
		btn.pressed.connect(g._switch_spot.bind(sid))
		head.add_child(btn)
	box.add_child(head)
	var desc := Label.new()
	desc.text = str(s["desc"])
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", DT.FS_2XS)
	desc.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS if unlocked else DT.TEXT_FAINT_GLASS)
	box.add_child(desc)
	var info := Label.new()
	info.add_theme_font_size_override("font_size", DT.FS_2XS)
	if unlocked:
		var prog := spot_species_progress(g, sid)
		var line := "鱼种收集 %d/%d" % [prog[0], prog[1]]
		if is_cur:
			if g.active_event != "":
				line += "　·　当前事件：%s" % EventData.display_name(g.active_event)
			else:
				line += "　·　风平浪静"
		info.text = line
		info.add_theme_color_override("font_color", DT.POSITIVE)
	else:
		info.text = "🔒 %s" % SpotData.unlock_text(sid)
		info.add_theme_color_override("font_color", DT.BAG_FULL)
	box.add_child(info)
	return cell


# ============================ 鱼缸页（活水族箱）============================

static func fill_decor_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var stat := Label.new()
	stat.text = "🐟 水族箱 · %d/%d 条　观赏卖价加成 +%d%%" % [
		g.display.size(), Decor.NUM_SLOTS, int(round(Decor.value_bonus(g) * 100.0))]
	stat.add_theme_font_size_override("font_size", DT.FS_XS)
	stat.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
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
	var sb := dark_row_style(0.5 if done else 0.4)
	if done:
		sb.set_border_width_all(1)
		sb.border_color = Color(DT.GOLD.r, DT.GOLD.g, DT.GOLD.b, 0.5)
	panel.add_theme_stylebox_override("panel", sb)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 11)
	margin.add_theme_constant_override("margin_right", 11)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)
	var mark := Label.new()
	mark.text = "✓" if done else "○"
	mark.custom_minimum_size = Vector2(18, 0)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.add_theme_font_size_override("font_size", DT.FS_HEAD)
	mark.add_theme_color_override("font_color", DT.POSITIVE if done else DT.TEXT_FAINT_GLASS)
	row.add_child(mark)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 0)
	var nm := Label.new()
	nm.text = str(a["name"])
	nm.add_theme_font_size_override("font_size", DT.FS_LABEL)
	nm.add_theme_color_override("font_color", DT.TEXT_ON_GLASS if done else DT.TEXT_MUTED_GLASS)
	info.add_child(nm)
	var ds := Label.new()
	ds.text = str(a["desc"])
	ds.add_theme_font_size_override("font_size", DT.FS_2XS)
	ds.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS if done else DT.TEXT_FAINT_GLASS)
	info.add_child(ds)
	row.add_child(info)
	if done:
		row.add_child(make_pill("达成", DT.GOLD, DT.INK_ON_GOLD))
	else:
		var rw := int(a.get("reward", 0))
		if rw > 0:
			var rwl := Label.new()
			rwl.text = "+%d" % rw
			rwl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			rwl.add_theme_font_size_override("font_size", DT.FS_XS)
			rwl.add_theme_color_override("font_color", DT.GOLD)
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
	stat.add_theme_font_size_override("font_size", DT.FS_XS)
	stat.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	v.add_child(stat)

	var panel := PanelContainer.new()
	var osb := dark_row_style(0.5)             # CD：暗行底（非浅纸）
	if have >= need and not done:
		osb.set_border_width_all(2)
		osb.border_color = DT.GOLD             # 可交付 → 金边
	panel.add_theme_stylebox_override("panel", osb)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12 if side in ["left", "right"] else 10)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	margin.add_child(row)
	row.add_child(g._fish_icon(target, 48))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = g._order_title()
	title.add_theme_font_override("font", g._font_bold)
	title.add_theme_font_size_override("font_size", DT.FS_HEAD)
	title.add_theme_color_override("font_color", DT.TEXT_ON_GLASS if not done else DT.TEXT_MUTED_GLASS)
	info.add_child(title)
	var kind_label: String = {"species": "指定鱼种", "tier": "指定品阶", "weight": "大物", "perfect": "完美品质"}.get(kind, "")
	var desc := Label.new()
	var mtxt := "（收鱼郎在场 ×%.1f！）" % g.MERCHANT_MULT if g._merchant_active else ""
	desc.text = "%s订单 · 交付未上锁的符合渔获，按鱼价 ×%.1f 结算%s" % [kind_label, g.DAILY_ORDER_MULT, mtxt]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(220, 0)
	desc.add_theme_font_size_override("font_size", DT.FS_2XS)
	desc.add_theme_color_override("font_color", DT.GOLD if g._merchant_active and not done else DT.TEXT_MUTED_GLASS)
	info.add_child(desc)
	var progress := Label.new()
	if done:
		progress.text = "今日已完成"
	else:
		progress.text = "进度 %d/%d%s" % [have, need, " · 可交付 +%s" % g._coin_str(reward) if have >= need else ""]
	progress.add_theme_font_size_override("font_size", DT.FS_XS)
	progress.add_theme_color_override("font_color", DT.GOLD if have >= need and not done else DT.TEXT_MUTED_GLASS)
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


## CD 统计卡（hero 数字 + 标签）
static func _stat_card(g: CornerFishing, value: String, key: String) -> Control:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", dark_row_style(0.5))
	var mg := MarginContainer.new()
	mg.add_theme_constant_override("margin_left", 13)
	mg.add_theme_constant_override("margin_right", 13)
	mg.add_theme_constant_override("margin_top", 11)
	mg.add_theme_constant_override("margin_bottom", 11)
	pc.add_child(mg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	mg.add_child(box)
	var vl := Label.new()
	vl.text = value
	vl.add_theme_font_override("font", g._font_bold)       # CD .stat .v weight 800 → embolden
	vl.add_theme_font_size_override("font_size", 20)
	vl.add_theme_color_override("font_color", DT.TEXT_TITLE)
	box.add_child(vl)
	var kl := Label.new()
	kl.text = key
	kl.add_theme_font_size_override("font_size", DT.FS_2XS)
	kl.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	box.add_child(kl)
	return pc


## 紧凑标签:值 行
static func _kv_row(k: String, val: String) -> Control:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", dark_row_style(0.4))
	var mg := MarginContainer.new()
	mg.add_theme_constant_override("margin_left", 11)
	mg.add_theme_constant_override("margin_right", 11)
	mg.add_theme_constant_override("margin_top", 6)
	mg.add_theme_constant_override("margin_bottom", 6)
	pc.add_child(mg)
	var row := HBoxContainer.new()
	mg.add_child(row)
	var kl := Label.new()
	kl.text = k
	kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kl.add_theme_font_size_override("font_size", DT.FS_XS)
	kl.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	row.add_child(kl)
	var vl := Label.new()
	vl.text = val
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vl.add_theme_font_size_override("font_size", DT.FS_XS)
	vl.add_theme_color_override("font_color", DT.TEXT_ON_GLASS)
	row.add_child(vl)
	return pc


## CD 任务页：每日订单 + 周挑战 + 统计 + 成就，合并为一个滚动页（保留全部功能）。
static func fill_tasks_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 384)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", DT.SP_2)
	sc.add_child(list)

	# 订单 + 周挑战（复用现有渲染）
	fill_order_tab(g, list)

	# —— 统计：hero 卡格 + 详细行 ——
	_section(list, "统计")
	var big_id := ""
	var big_w := 0.0
	for id in g.dex:
		if float(g.dex[id]["w"]) > big_w:
			big_w = float(g.dex[id]["w"])
			big_id = id
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", DT.SP_3)
	grid.add_theme_constant_override("v_separation", DT.SP_3)
	grid.add_child(_stat_card(g, g._coin_str(g.lifetime_catches), "累计渔获"))
	grid.add_child(_stat_card(g, g._coin_str(g.lifetime_coins), "累计收入"))
	grid.add_child(_stat_card(g, g._coin_str(g._today_catches()), "今日渔获"))
	grid.add_child(_stat_card(g, g._coin_str(g._today_income()), "今日收入"))
	grid.add_child(_stat_card(g, ("%.2fkg" % big_w) if big_id != "" else "—", "最大个体"))
	grid.add_child(_stat_card(g, g._coin_str(g.coins), "当前金币"))
	list.add_child(grid)
	var q := g.best_quality
	var rows := [
		["图鉴收集", "%d / %d 种" % [g.dex.size(), FishData.FISH.size()]],
		["成就达成", "%d / %d" % [g.achievements_done.size(), AchievementData.LIST.size()]],
		["最高品相", (str(FishData.QUALITY_NAMES[clampi(q, 0, 3)]) + "★".repeat(q)) if q > 0 else "普通"],
		["巨物纪录", "已钓到" if g.caught_giant else "尚无"],
		["累计专注", "%d 分钟" % int(g.focus_minutes_total)],
		["猫税", "被叼走 %d 条" % g.pet_steals],
		["鱼篓容量", "%d 格" % g._bag_capacity()],
		["当前装备", "鱼竿 Lv.%d · %s · %s" % [
			g.rod_level, FishData.BAITS[g.bait_level]["name"], FishData.HOOKS[g.hook_level]["name"]]],
	]
	for r in rows:
		list.add_child(_kv_row(str(r[0]), str(r[1])))

	# —— 成就 ——
	_section(list, "成就 %d/%d" % [g.achievements_done.size(), AchievementData.LIST.size()])
	var sorted: Array = AchievementData.LIST.duplicate()
	sorted.sort_custom(func(a, b):
		return g.achievements_done.has(a["id"]) and not g.achievements_done.has(b["id"]))
	for a in sorted:
		list.add_child(ach_row(g, a))
	v.add_child(sc)


static func fill_weekly_panel(g: CornerFishing, v: VBoxContainer) -> void:
	g._ensure_weekly()
	v.add_child(HSeparator.new())
	var wdone := bool(g.weekly.get("done", false))
	var prog := g._weekly_progress()
	var target := int(g.weekly.get("target", 1))
	var stat := Label.new()
	stat.text = "本周挑战"
	stat.add_theme_font_size_override("font_size", DT.FS_XS)
	stat.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	v.add_child(stat)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", dark_row_style(0.5))   # CD：暗行底（非浅纸）
	var mg := MarginContainer.new()
	for s in ["left", "right"]:
		mg.add_theme_constant_override("margin_" + s, 11)
	for s in ["top", "bottom"]:
		mg.add_theme_constant_override("margin_" + s, 9)
	panel.add_child(mg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	mg.add_child(box)
	var title := Label.new()
	title.text = g._weekly_desc()
	title.add_theme_font_override("font", g._font_bold)
	title.add_theme_font_size_override("font_size", DT.FS_SM)
	title.add_theme_color_override("font_color", DT.TEXT_ON_GLASS if not wdone else DT.TEXT_MUTED_GLASS)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(330, 0)
	box.add_child(title)
	var bar := make_progress(float(mini(prog, target)) / maxf(1.0, float(target)), DT.GOLD, 8)
	box.add_child(bar)
	var row := HBoxContainer.new()
	var pl := Label.new()
	pl.text = "%d / %d　奖励 %s 金币" % [mini(prog, target), target, g._coin_str(int(g.weekly.get("reward", 0)))]
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.add_theme_font_size_override("font_size", DT.FS_XS)
	pl.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
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
	# —— 排序 + 订单筛选（CD .seg pill）——
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", DT.CHIP_GAP)
	for m in g.BAG_SORT_NAMES.size():
		var sb := Button.new()
		sb.text = g.BAG_SORT_NAMES[m]
		apply_tab_skin(sb, m == g._bag_sort)
		if m != g._bag_sort:
			sb.pressed.connect(func(mm = m) -> void:
				g._bag_sort = mm
				g._open_panel("catch"))
		seg.add_child(sb)
	var seg_sp := Control.new()
	seg_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seg.add_child(seg_sp)
	var filt := Button.new()
	filt.text = "订单鱼"
	filt.tooltip_text = "只看今日订单的目标鱼"
	apply_tab_skin(filt, g._bag_filter_order, DT.GOLD)
	filt.pressed.connect(func() -> void:
		g._bag_filter_order = not g._bag_filter_order
		g._open_panel("catch"))
	seg.add_child(filt)
	v.add_child(seg)

	# —— 容量 + 批量操作 ——
	var total := 0
	var unlocked := 0
	var junk := 0
	for c in g.inventory:
		if not bool(c.get("lock", false)):
			total += g._sell_value(c)
			unlocked += 1
			if not g._order_matches(c):
				junk += 1
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", DT.CHIP_GAP)
	var cap := Label.new()
	cap.text = "%d/%d" % [g.inventory.size(), g._bag_capacity()]
	cap.add_theme_font_size_override("font_size", DT.FS_XS)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.add_theme_color_override("font_color", DT.BAG_FULL if g._bag_full() else DT.TEXT_MUTED_GLASS)
	head.add_child(cap)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var sell_junk := Button.new()
	sell_junk.text = "卖杂鱼"
	sell_junk.custom_minimum_size = Vector2(0, 28)
	sell_junk.disabled = junk == 0
	sell_junk.tooltip_text = "卖出 %d 条非订单、非收藏的鱼（保留订单目标鱼与锁定）" % junk
	sell_junk.add_theme_font_size_override("font_size", DT.FS_XS)
	apply_button_skin(sell_junk, false)
	sell_junk.pressed.connect(g._sell_junk)
	head.add_child(sell_junk)
	var sell_all := Button.new()
	sell_all.text = "全部兑换 +%d" % total
	sell_all.custom_minimum_size = Vector2(0, 28)
	sell_all.disabled = unlocked == 0
	sell_all.tooltip_text = "卖出 %d 条未上锁的鱼%s（锁定的会留下）" % [
		unlocked, "（收鱼郎×1.5）" if g._merchant_active else ""]
	sell_all.add_theme_font_size_override("font_size", DT.FS_XS)
	apply_button_skin(sell_all, true)
	sell_all.pressed.connect(g._sell_all)
	head.add_child(sell_all)
	if g.bag_level <= g.BAG_COSTS.size():
		var cost: int = g.BAG_COSTS[g.bag_level - 1]
		var expand := Button.new()
		expand.text = "扩容"
		expand.custom_minimum_size = Vector2(0, 28)
		expand.disabled = g.coins < cost
		expand.tooltip_text = "扩到 %d 格，花费 %d 金币" % [g.BAG_CAPS[g.bag_level], cost]
		expand.add_theme_font_size_override("font_size", DT.FS_XS)
		apply_button_skin(expand, false)
		expand.pressed.connect(g._try_expand_bag)
		head.add_child(expand)
	v.add_child(head)

	if g.inventory.is_empty():
		v.add_child(_empty_note("鱼篓还是空的，\n等浮漂动一动。"))
		return

	# —— 网格（CD .bgrid）：4 列鱼卡，点卡身=卖，右上「锁」角标 ——
	var idxs := g._sorted_bag_indices(g._bag_filter_order)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 300)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL   # 填满 sheet 高度（带框）
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if idxs.is_empty():
		v.add_child(_empty_note("没有符合条件的鱼。"))
		return
	var grid := GridContainer.new()
	grid.columns = 8 if g.display_mode != "immersive" else 4   # 带框全宽 sheet → 更密
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", DT.SP_3)
	grid.add_theme_constant_override("v_separation", DT.SP_3)
	for i in idxs:
		grid.add_child(fish_cell(g, g.inventory[i], i))
	sc.add_child(grid)
	v.add_child(sc)


## CD .empty —— 暗行空态提示卡
static func _empty_note(text: String) -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(0, 92)
	pc.add_theme_stylebox_override("panel", dark_row_style(0.4))
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", DT.FS_SM)
	l.add_theme_color_override("font_color", DT.TEXT_FAINT_GLASS)
	pc.add_child(l)
	return pc


## CD .fishcell —— 鱼篓网格卡：品阶/变体色边框 + 图 + 名 + 「卖N」；右上「锁」可点；点卡身=卖。
## 保留全部功能：单条卖/锁、星级品质、巨物前缀、变体◆、品阶色编码。
static func fish_cell(g: CornerFishing, c: Dictionary, idx: int) -> Control:
	var id := str(c["id"])
	var tier := FishData.tier_of(id)
	var vr := int(c.get("var", 0))
	var locked: bool = bool(c.get("lock", false))
	var edge := FishData.variant_color(vr) if vr >= 1 else g._ui_tier_color(tier, false)
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(0, 106)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := dark_row_style(0.42)
	sb.set_border_width_all(2)
	sb.border_color = Color(edge.r, edge.g, edge.b, 0.85)
	cell.add_theme_stylebox_override("panel", sb)
	cell.tooltip_text = "%s · %.2fkg · 点击卖出" % [FishData.display_name(id), float(c["w"])]
	cell.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			if locked:
				g._toast("已锁定收藏，先点右上「锁」解锁再卖", 1.5, DT.BAG_FULL)
			else:
				g._sell_one(idx))
	var mg := MarginContainer.new()
	mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mg.add_theme_constant_override("margin_left", 6)
	mg.add_theme_constant_override("margin_right", 6)
	mg.add_theme_constant_override("margin_top", 4)
	mg.add_theme_constant_override("margin_bottom", 6)
	cell.add_child(mg)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 1)
	mg.add_child(box)
	# 顶行：右上「锁」幽灵角标
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.custom_minimum_size = Vector2(0, 15)
	var tsp := Control.new()
	tsp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tsp)
	var lk := Button.new()
	lk.text = "锁"
	lk.tooltip_text = "解除收藏锁" if locked else "上锁收藏（不被卖出 / 交付）"
	lk.custom_minimum_size = Vector2(20, 15)
	lk.focus_mode = Control.FOCUS_NONE
	var lk_empty := StyleBoxEmpty.new()
	lk.add_theme_stylebox_override("normal", lk_empty)
	lk.add_theme_stylebox_override("pressed", lk_empty)
	lk.add_theme_stylebox_override("hover", lk_empty)
	lk.add_theme_stylebox_override("focus", lk_empty)
	lk.add_theme_font_size_override("font_size", DT.FS_2XS)
	lk.add_theme_color_override("font_color", DT.GOLD_BRIGHT if locked else DT.TEXT_FAINT_GLASS)
	lk.add_theme_color_override("font_hover_color", DT.GOLD_BRIGHT)
	lk.pressed.connect(func() -> void: Audio.play_ui("ui_click"))
	lk.pressed.connect(g._toggle_lock.bind(idx))
	top.add_child(lk)
	box.add_child(top)
	# 图标
	var icon := g._fish_icon(id, 44)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)
	# 名字（品阶/变体色编码，◆=变体）
	var nm := Label.new()
	nm.text = ("◆" + FishData.display_name(id)) if vr >= 1 else FishData.display_name(id)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm.add_theme_font_override("font", g._font_bold)        # CD .fn weight 700
	nm.add_theme_font_size_override("font_size", DT.FS_2XS + 1)
	nm.add_theme_color_override("font_color", edge)
	box.add_child(nm)
	# meta：星级 / 巨物 / 重量
	var meta := Label.new()
	var parts: Array[String] = []
	var q := int(c.get("q", 0))
	if q > 0:
		parts.append("★".repeat(q))
	var sztag := FishData.size_tag(id, c["w"]).replace("·", "").strip_edges()
	if sztag != "":
		parts.append(sztag)
	parts.append("%.2fkg" % float(c["w"]))
	meta.text = " ".join(parts)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meta.clip_text = true
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.add_theme_font_size_override("font_size", DT.FS_MICRO)
	meta.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	box.add_child(meta)
	# 价值 / 卖出提示
	var val := Label.new()
	val.text = "已锁" if locked else "卖 %s" % g._coin_str(g._sell_value(c))
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	val.add_theme_font_override("font", g._font_bold)        # CD .fv weight 800
	val.add_theme_font_size_override("font_size", DT.FS_XS)
	val.add_theme_color_override("font_color", DT.TEXT_FAINT_GLASS if locked else DT.GOLD_BRIGHT)
	box.add_child(val)
	return cell


# ============================ 图鉴页 ============================

# ============================ 鱼种详情卡（点击图鉴的鱼弹出）============================

static func fill_fish_detail(g: CornerFishing, v: VBoxContainer) -> void:
	var id := str(g._detail_fish)
	if not FishData.FISH.has(id):
		return
	var info: Dictionary = FishData.FISH[id]
	var tier := FishData.tier_of(id)
	var rec: Dictionary = g.dex.get(id, {})
	var lore: Dictionary = FishLore.LORE.get(id, {})

	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 404)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	sc.add_child(col)
	v.add_child(sc)

	# —— 照片：有真实照片则显示，否则回退水彩鱼图 ——
	var photo_path := "res://assets/art/fish_photos/%s.jpg" % id
	var has_photo := ResourceLoader.exists(photo_path)
	var pcard := PanelContainer.new()
	pcard.add_theme_stylebox_override("panel", paper_style(0.95))
	var pm := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pm.add_theme_constant_override("margin_" + s, 8)
	pcard.add_child(pm)
	var pbox := VBoxContainer.new()
	pbox.add_theme_constant_override("separation", 4)
	pm.add_child(pbox)
	var img := TextureRect.new()
	img.custom_minimum_size = Vector2(0, 224 if has_photo else 132)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.texture = (load(photo_path) as Texture2D) if has_photo else g._fish_texture(id)
	pbox.add_child(img)
	var cap := Label.new()
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.custom_minimum_size = Vector2(460, 0)
	cap.add_theme_font_size_override("font_size", 10)
	cap.add_theme_color_override("font_color", Color(0.46, 0.43, 0.37))
	cap.text = _photo_credit(id) if has_photo else "（暂用示意水彩图，真实照片待补）"
	pbox.add_child(cap)
	col.add_child(pcard)

	# —— 名 · 品阶（衬线）——
	var nm := Label.new()
	nm.text = "%s · %s" % [FishData.TIER_NAMES[tier], FishData.display_name(id)]
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_font_override("font", g._serif)
	nm.add_theme_color_override("font_color", g._ui_tier_color(tier, false))
	col.add_child(nm)

	# —— 品种描述 + 冷知识 ——
	if lore.has("desc"):
		var d := Label.new()
		d.text = str(lore["desc"])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(470, 0)
		d.add_theme_font_size_override("font_size", 13)
		d.add_theme_color_override("font_color", Color(0.86, 0.83, 0.74))
		col.add_child(d)
	if lore.has("fact"):
		var fa := Label.new()
		fa.text = "💡 " + str(lore["fact"])
		fa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fa.custom_minimum_size = Vector2(470, 0)
		fa.add_theme_font_size_override("font_size", 12)
		fa.add_theme_color_override("font_color", Color(0.82, 0.70, 0.42))
		col.add_child(fa)

	# —— 真实档案 ——
	var tags_cn := []
	for t in info.get("tags", []):
		tags_cn.append(str(FishLore.TAG_CN.get(t, t)))
	col.add_child(_kv_card([
		["生态", "　".join(tags_cn)],
		["体重", "%.2f – %.2f kg" % [float(info["wmin"]), float(info["wmax"])]],
		["卖价", "%d – %d 金币" % [int(info["vmin"]), int(info["vmax"])]],
	]))

	# —— 个人纪录 ——
	if not rec.is_empty():
		var fd := str(rec.get("fd", ""))
		col.add_child(_kv_card([
			["累计钓获", "×%d" % int(rec.get("n", 1))],
			["最大纪录", "%.2f kg" % float(rec.get("w", 0.0))],
			["首次捕获", fd if fd != "" else "很久以前"],
		]))

	# —— 按钮：百科外链 + 返回图鉴 ——
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	if lore.has("wiki"):
		var wb := Button.new()
		wb.text = "百科 ↗"
		wb.custom_minimum_size = Vector2(0, 32)
		wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		apply_button_skin(wb, true)
		var wurl := "https://zh.wikipedia.org/wiki/" + str(lore["wiki"])
		wb.pressed.connect(func() -> void:
			Audio.play_ui("ui_click")
			OS.shell_open(wurl))
		btns.add_child(wb)
	var bb := Button.new()
	bb.text = "← 返回图鉴"
	bb.custom_minimum_size = Vector2(0, 32)
	bb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button_skin(bb, false)
	bb.pressed.connect(func() -> void:
		Audio.play_ui("ui_click")
		g._set_catch_tab(1))
	btns.add_child(bb)
	col.add_child(btns)


static func _kv_card(rows: Array) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", paper_style(0.90))
	var mg := MarginContainer.new()
	for s in ["left", "right"]:
		mg.add_theme_constant_override("margin_" + s, 10)
	for s in ["top", "bottom"]:
		mg.add_theme_constant_override("margin_" + s, 7)
	card.add_child(mg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	mg.add_child(box)
	for r in rows:
		var row := HBoxContainer.new()
		var k := Label.new()
		k.text = str(r[0])
		k.custom_minimum_size = Vector2(74, 0)
		k.add_theme_font_size_override("font_size", 12)
		k.add_theme_color_override("font_color", Color(0.50, 0.47, 0.40))
		row.add_child(k)
		var val := Label.new()
		val.text = str(r[1])
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val.add_theme_font_size_override("font_size", 13)
		val.add_theme_color_override("font_color", Color(0.26, 0.25, 0.22))
		row.add_child(val)
		box.add_child(row)
	return card


static func _photo_credit(id: String) -> String:
	var path := "res://assets/art/fish_photos/CREDITS.json"
	if not FileAccess.file_exists(path):
		return "📷 Wikimedia Commons"
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return "📷 Wikimedia Commons"
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY and data.has(id):
		var c: Dictionary = data[id]
		var author := str(c.get("author", "")).split("\n")[0]
		return "📷 %s · %s · 维基共享资源" % [author, str(c.get("license", ""))]
	return "📷 Wikimedia Commons"


static var _dex_tier := -1   # 图鉴品阶筛选：-1=全部，0-5=各品阶

static func fill_dex_tab(g: CornerFishing, v: VBoxContainer) -> void:
	var vc := 0  # 已收集稀有变体数（每种鱼 ×3 稀有）
	for id in g.dex:
		var vm := int(g.dex[id].get("vmask", 0))
		for vi in range(1, FishData.VARIANT_NAMES.size()):
			if vm & (1 << vi):
				vc += 1
	var vtotal := FishData.FISH.size() * (FishData.VARIANT_NAMES.size() - 1)
	var stat := Label.new()
	stat.text = "收集 %d/%d　·　变体 %d/%d　·　渔获 %d" % [
		g.dex.size(), FishData.FISH.size(), vc, vtotal, g.lifetime_catches]
	stat.add_theme_font_size_override("font_size", DT.FS_XS)
	stat.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	v.add_child(stat)

	# 品阶筛选 seg（CD：全部 + 6 品阶，品阶 pill 用品阶色）
	var tier_names := ["普通", "优良", "稀有", "史诗", "传说", "神话"]
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", DT.CHIP_GAP)
	var allb := Button.new()
	allb.text = "全部"
	apply_tab_skin(allb, _dex_tier == -1)
	if _dex_tier != -1:
		allb.pressed.connect(func() -> void:
			_dex_tier = -1
			g._open_panel("catch"))
	seg.add_child(allb)
	for t in range(6):
		var tb := Button.new()
		tb.text = tier_names[t]
		apply_tab_skin(tb, _dex_tier == t, DT.tier_color(t))
		if _dex_tier != t:
			tb.pressed.connect(func(tt = t) -> void:
				_dex_tier = tt
				g._open_panel("catch"))
		seg.add_child(tb)
	v.add_child(seg)

	var ids := FishData.FISH.keys()
	ids.sort_custom(func(a, b): return FishData.tier_of(a) < FishData.tier_of(b))
	if _dex_tier >= 0:
		ids = ids.filter(func(id): return FishData.tier_of(id) == _dex_tier)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 296)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL   # 填满 sheet 高度（带框）
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var grid := GridContainer.new()
	grid.columns = 10 if g.display_mode != "immersive" else 5   # 带框全宽 sheet → 更密
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", DT.SP_2)
	grid.add_theme_constant_override("v_separation", DT.SP_2)
	for id in ids:
		grid.add_child(dex_card(g, str(id)))
	sc.add_child(grid)
	v.add_child(sc)


static func dex_card(g: CornerFishing, id: String) -> Control:
	var known := g.dex.has(id)
	var tier := FishData.tier_of(id)
	var tc := g._ui_tier_color(tier, false)
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(0, 82)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := dark_row_style(0.40)
	sb.set_border_width_all(1)
	sb.border_color = Color(tc.r, tc.g, tc.b, 0.7) if known else DT.GLASS_ROW_BORDER
	cell.add_theme_stylebox_override("panel", sb)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	cell.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)
	var icon := g._fish_icon(id, 38)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.modulate = Color(1, 1, 1, 1.0) if known else Color(0, 0, 0, 0.34)  # 未发现=黑剪影
	box.add_child(icon)
	var nm := Label.new()
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.text = FishData.display_name(id) if known else "？？？"
	nm.add_theme_font_size_override("font_size", DT.FS_MICRO)
	nm.add_theme_color_override("font_color", tc if known else DT.TEXT_FAINT_GLASS)
	box.add_child(nm)
	# 变体收集圆点（CD .vdots：斑斓/鎏金/七彩）
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 3)
	dots.custom_minimum_size = Vector2(0, 8)
	var vm := int(g.dex.get(id, {}).get("vmask", 0)) if known else 0
	for vi in range(1, FishData.VARIANT_NAMES.size()):
		var d := Label.new()
		d.text = "●"
		d.add_theme_font_size_override("font_size", DT.FS_MICRO - 1)
		var on := (vm & (1 << vi)) != 0
		d.add_theme_color_override("font_color", FishData.variant_color(vi) if on else Color(1, 1, 1, 0.14))
		dots.add_child(d)
	box.add_child(dots)
	if known:
		var r: Dictionary = g.dex[id]
		var tip := "%s · ×%d" % [FishData.display_name(id), int(r["n"])]
		if float(r["w"]) > 0.0:
			tip += " · 最大 %.2fkg" % float(r["w"])
		if int(r["n"]) >= 10:
			tip += " · ✦集齐"
		if bool(r.get("big", false)):
			tip += " · 巨"
		if bool(r.get("perf", false)):
			tip += " · 完★"
		cell.tooltip_text = tip
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cell.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				Audio.play_ui("ui_click")
				g._open_fish_detail(id))
	return cell


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

# CD .row —— 带缩略图的列表行；返回 [panel, hbox]，调用方往 hbox 追加右侧控件（pill/按钮）
static func list_row(thumb_path: String, title: String, sub: String, highlight := false) -> Array:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := dark_row_style(0.52)
	sb.set_corner_radius_all(DT.R_CELL)
	if highlight:
		sb.set_border_width_all(2)
		sb.border_color = DT.GOLD
	panel.add_theme_stylebox_override("panel", sb)
	var mg := MarginContainer.new()
	mg.add_theme_constant_override("margin_left", 11)
	mg.add_theme_constant_override("margin_right", 11)
	mg.add_theme_constant_override("margin_top", 8)
	mg.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(mg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	mg.add_child(row)
	if thumb_path != "" and ResourceLoader.exists(thumb_path):
		var thumb := TextureRect.new()
		thumb.texture = load(thumb_path)
		thumb.custom_minimum_size = Vector2(40, 36)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(thumb)
	var grow := VBoxContainer.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grow.add_theme_constant_override("separation", 1)
	var nm := Label.new()
	nm.text = title
	nm.add_theme_font_size_override("font_size", DT.FS_SM)
	nm.add_theme_color_override("font_color", DT.TEXT_ON_GLASS)
	grow.add_child(nm)
	if sub != "":
		var sl := Label.new()
		sl.text = sub
		sl.add_theme_font_size_override("font_size", DT.FS_2XS)
		sl.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		grow.add_child(sl)
	row.add_child(grow)
	return [panel, row]


static func _equip_btn(row: HBoxContainer, text: String, enabled: bool, primary: bool, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(56, 34)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.disabled = not enabled
	b.add_theme_font_size_override("font_size", DT.FS_XS)
	apply_button_skin(b, primary)
	if enabled:
		b.pressed.connect(cb)
	row.add_child(b)


static func _section(v: VBoxContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", DT.FS_XS)
	l.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	l.custom_minimum_size = Vector2(0, 22)
	l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	v.add_child(l)


static func fill_upgrades(g: CornerFishing, v: VBoxContainer) -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 360)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", DT.SP_2)
	sc.add_child(list)

	# 鱼竿（线性升级）
	var rc := g._rod_cost()
	var rod := list_row("res://assets/art/equipment/rod_carbon.png", "鱼竿 Lv.%d" % g.rod_level,
		"决定稀有度 · 越高级越易上高阶鱼，咬钩更快，鱼价 +%d%%" % int((g.rod_level - 1) * 8), true)
	_equip_btn(rod[1], "升级 %d" % rc, g.coins >= rc, true, g._try_upgrade_rod)
	list.add_child(rod[0])

	# 鱼饵（决定星级品质）
	_section(list, "鱼饵 · 决定星级品质（卖价倍率 ×1.8/×4/×8）")
	for i in FishData.BAITS.size():
		var b: Dictionary = FishData.BAITS[i]
		var probs: Array = b["probs"]
		var sub := "%s · 上品率 %d%%" % [b.get("desc", ""), int(float(probs[1]) * 100.0)]
		var cur := i == g.bait_level
		var rw := list_row("res://assets/art/equipment/bait_jar.png", str(b["name"]), sub, cur)
		if cur:
			rw[1].add_child(make_pill("使用中", DT.GOLD, DT.INK_ON_GOLD))
		elif i == g.bait_level + 1:
			var bcost := int(b["cost"])
			_equip_btn(rw[1], "升级 %d" % bcost, g.coins >= bcost, true, g._try_upgrade_bait)
		elif i < g.bait_level:
			rw[1].add_child(make_pill("已超越", DT.GLASS_ROW_HOVER, DT.TEXT_MUTED_GLASS))
		else:
			rw[1].add_child(make_pill("🔒 %d" % int(b["cost"]), DT.GLASS_ROW, DT.TEXT_FAINT_GLASS))
		list.add_child(rw[0])

	# 鱼钩（决定双钩几率）
	_section(list, "鱼钩 · 决定双钩几率（一次钓上两条）")
	for i in FishData.HOOKS.size():
		var h: Dictionary = FishData.HOOKS[i]
		var sub := "%s · 双钩 %d%%" % [h.get("desc", ""), int(float(h["double"]) * 100.0)]
		var cur := i == g.hook_level
		var rw := list_row("res://assets/art/equipment/hook_basic.png", str(h["name"]), sub, cur)
		if cur:
			rw[1].add_child(make_pill("使用中", DT.GOLD, DT.INK_ON_GOLD))
		elif i == g.hook_level + 1:
			var hcost := int(h["cost"])
			_equip_btn(rw[1], "升级 %d" % hcost, g.coins >= hcost, true, g._try_upgrade_hook)
		elif i < g.hook_level:
			rw[1].add_child(make_pill("已超越", DT.GLASS_ROW_HOVER, DT.TEXT_MUTED_GLASS))
		else:
			rw[1].add_child(make_pill("🔒 %d" % int(h["cost"]), DT.GLASS_ROW, DT.TEXT_FAINT_GLASS))
		list.add_child(rw[0])
	v.add_child(sc)


# ============================ 设置 / 引导 / 离线小结 ============================

static func audio_slider(v: VBoxContainer, label: String, value: float, setter: Callable) -> void:
	var lbl := Label.new()
	lbl.text = label
	lbl.add_theme_font_size_override("font_size", DT.FS_SM)
	lbl.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	v.add_child(lbl)
	var sl := HSlider.new()
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = value
	sl.custom_minimum_size = Vector2(0, 18)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.value_changed.connect(func(x: float) -> void: setter.call(x))
	v.add_child(sl)


static func fill_settings(g: CornerFishing, v: VBoxContainer) -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 384)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", DT.SP_3)
	sc.add_child(col)

	# 自动卖鱼（付费占位）
	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 8)
	var auto_lbl := Label.new()
	auto_lbl.text = "🔒 自动卖鱼"
	auto_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	auto_lbl.add_theme_font_size_override("font_size", DT.FS_SM)
	auto_lbl.add_theme_color_override("font_color", DT.TEXT_FAINT_GLASS)
	auto_row.add_child(auto_lbl)
	auto_row.add_child(make_pill("敬请期待", DT.GLASS_ROW, DT.GOLD))
	col.add_child(auto_row)
	col.add_child(HSeparator.new())

	# 静音
	var mute_row := HBoxContainer.new()
	mute_row.add_theme_constant_override("separation", 8)
	var mute_lbl := Label.new()
	mute_lbl.text = "静音"
	mute_lbl.add_theme_font_size_override("font_size", DT.FS_SM)
	mute_lbl.add_theme_color_override("font_color", DT.TEXT_ON_GLASS)
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
	col.add_child(mute_row)
	audio_slider(col, "主音量", Audio.master_volume, Audio.set_master_volume)
	audio_slider(col, "音效", Audio.sfx_volume, Audio.set_sfx_volume)
	audio_slider(col, "环境音", Audio.ambience_volume, Audio.set_ambience_volume)
	col.add_child(HSeparator.new())

	# 专注模式
	var focus_row := HBoxContainer.new()
	focus_row.add_theme_constant_override("separation", 8)
	var focus_lbl := Label.new()
	focus_lbl.text = "专注模式（少打扰）"
	focus_lbl.add_theme_font_size_override("font_size", DT.FS_SM)
	focus_lbl.add_theme_color_override("font_color", DT.TEXT_ON_GLASS)
	focus_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_row.add_child(focus_lbl)
	var focus_btn := CheckButton.new()
	focus_btn.button_pressed = g.focus_mode
	focus_btn.focus_mode = Control.FOCUS_NONE
	focus_btn.toggled.connect(func(on: bool) -> void:
		g._set_focus(on)
		g._save())
	focus_row.add_child(focus_btn)
	col.add_child(focus_row)
	col.add_child(HSeparator.new())

	# 不透明度
	var ol := Label.new()
	ol.text = "不透明度"
	ol.add_theme_font_size_override("font_size", DT.FS_SM)
	ol.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	col.add_child(ol)
	var sl := HSlider.new()
	sl.min_value = 0.3
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = g._opacity
	sl.custom_minimum_size = Vector2(0, 18)
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.value_changed.connect(g._set_opacity)
	col.add_child(sl)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap)
	col.add_child(HSeparator.new())

	# 帧率（挂件默认 30 省电；可调高换更顺滑的画面，更耗电）
	var fps_lbl := Label.new()
	fps_lbl.text = "帧率"
	fps_lbl.add_theme_font_size_override("font_size", DT.FS_SM)
	fps_lbl.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
	col.add_child(fps_lbl)
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", DT.SP_2)
	for fps in g.FPS_OPTIONS:
		var fb := Button.new()
		fb.text = str(fps)
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb.custom_minimum_size = Vector2(0, 30)
		apply_tab_skin(fb, g.max_fps == fps)
		if g.max_fps != fps:
			fb.pressed.connect(func() -> void:
				g._set_max_fps(fps)
				g._save()
				g._refresh_panel())   # 重建设置页 → 高亮跳到新选项
		fps_row.add_child(fb)
	col.add_child(fps_row)
	var fps_hint := Label.new()
	fps_hint.text = "数字越高画面越顺滑，也越耗电"
	fps_hint.add_theme_font_size_override("font_size", DT.FS_2XS)
	fps_hint.add_theme_color_override("font_color", DT.TEXT_FAINT_GLASS)
	col.add_child(fps_hint)
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 6)
	col.add_child(gap2)

	# 窗口
	var br := HBoxContainer.new()
	br.add_theme_constant_override("separation", DT.SP_3)
	var reset := Button.new()
	reset.text = "回到右下角"
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.custom_minimum_size = Vector2(0, 34)
	apply_button_skin(reset, false)
	reset.pressed.connect(g._place_corner)
	br.add_child(reset)
	var quit := Button.new()
	quit.text = "退出游戏"
	quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quit.custom_minimum_size = Vector2(0, 34)
	apply_button_skin(quit, false)
	quit.pressed.connect(g._quit_game)
	br.add_child(quit)
	col.add_child(br)
	v.add_child(sc)


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
		l.add_theme_font_size_override("font_size", DT.FS_SM)
		l.add_theme_color_override("font_color", DT.TEXT_ON_GLASS)
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
	hi.add_theme_font_size_override("font_size", DT.FS_HEAD)
	hi.add_theme_color_override("font_color", DT.TEXT_TITLE)
	v.add_child(hi)
	var line := Label.new()
	line.text = "离线 %s，挂竿钓得 %d 条入篓%s" % [
		str(rep.get("dur", "")), int(rep.get("count", 0)),
		"（鱼篓已满）" if bool(rep.get("full", false)) else ""]
	line.add_theme_color_override("font_color", DT.TEXT_ON_GLASS)
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
		ov.add_theme_font_size_override("font_size", DT.FS_XS)
		ov.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
		ov.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ov.custom_minimum_size = Vector2(360, 0)
		v.add_child(ov)
	var notable: Array = rep.get("notable", [])
	if not notable.is_empty():
		var nlbl := Label.new()
		nlbl.text = "其中珍稀 %d 条：" % notable.size()
		nlbl.add_theme_font_size_override("font_size", DT.FS_XS)
		nlbl.add_theme_color_override("font_color", DT.TEXT_MUTED_GLASS)
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
