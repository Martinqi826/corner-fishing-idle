class_name Aquarium
extends Control
## 活水族箱（Task 1）：把放进缸里的收藏鱼（g.display）渲染成沿平滑路径游动的小鱼缸。
## 兑现 Chillquarium 式收集深度——鎏金/七彩变体带光晕粒子，点鱼弹出它的纪录卡。
## 自管动画（_process 推进、_draw 合成），不依赖 tween，避免面板重建时残留。
## 字段沿用主节点的 display（不另起炉灶）；纪录取自 g.dex（首捕日期为 v11 新增）。

var g                                   # CornerFishing 主节点（弱类型避免循环依赖）
var swimmers: Array = []                # 每条 {idx, c, tex, x, dir, speed, y, amp, freq, phase, vr, dsize}
var _t := 0.0
var _glow_tex: Texture2D
var _card: Control = null               # 当前打开的纪录卡（点空白处关闭）

const VIEW_SIZE := Vector2(472, 220)
const MARGIN := 26.0                     # 鱼游动的左右留白
const FISH_FACES_LEFT := true           # 鱼图标默认朝左 → 向右游时才水平翻转（修：原 false 致全部倒着游）


func setup(host) -> void:
	g = host
	custom_minimum_size = VIEW_SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_glow_tex = _make_glow()
	_build_swimmers()
	if swimmers.is_empty():
		var hint := Label.new()
		hint.text = "缸里还空着——从下面把心爱的鱼放进来，让它们游起来～"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint.add_theme_color_override("font_color", Color(0.62, 0.70, 0.74))
		hint.set_anchors_preset(Control.PRESET_FULL_RECT)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hint)


func _build_swimmers() -> void:
	swimmers.clear()
	if g == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in g.display.size():
		var c: Dictionary = g.display[i]
		var tier := FishData.tier_of(str(c["id"]))
		swimmers.append({
			"idx": i,
			"c": c,
			"tex": g._fish_texture(str(c["id"])),
			"vr": int(c.get("var", 0)),
			"dsize": clampf(30.0 + tier * 2.6, 30.0, 46.0),
			"x": rng.randf_range(MARGIN, VIEW_SIZE.x - MARGIN),
			"dir": 1.0 if rng.randf() < 0.5 else -1.0,
			"speed": rng.randf_range(16.0, 32.0),
			"y": rng.randf_range(34.0, VIEW_SIZE.y - 30.0),
			"amp": rng.randf_range(5.0, 12.0),
			"freq": rng.randf_range(0.5, 1.2),
			"phase": rng.randf() * TAU,
		})


func _process(delta: float) -> void:
	if swimmers.is_empty():
		return
	_t += delta
	for sw in swimmers:
		sw["x"] += sw["dir"] * sw["speed"] * delta
		if sw["x"] <= MARGIN:
			sw["x"] = MARGIN
			sw["dir"] = 1.0
		elif sw["x"] >= VIEW_SIZE.x - MARGIN:
			sw["x"] = VIEW_SIZE.x - MARGIN
			sw["dir"] = -1.0
	queue_redraw()


# ============================ 绘制 ============================

func _draw() -> void:
	# 缸水：上浅下深的蓝绿渐变 + 几道缓动光带 + 缸底砂线
	var sz := size if size.x > 1.0 else VIEW_SIZE
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.10, 0.20, 0.26, 0.62))
	for i in 3:
		var yy := sz.y * (0.18 + i * 0.26) + sin(_t * 0.4 + i) * 4.0
		draw_line(Vector2(0, yy), Vector2(sz.x, yy), Color(0.55, 0.80, 0.85, 0.05), 8.0)
	draw_rect(Rect2(0, sz.y - 6.0, sz.x, 6.0), Color(0.16, 0.22, 0.22, 0.5))
	for sw in swimmers:
		_draw_swimmer(sw)


func _draw_swimmer(sw: Dictionary) -> void:
	var pos := Vector2(sw["x"], sw["y"] + sin(_t * sw["freq"] + sw["phase"]) * sw["amp"])
	var vr: int = sw["vr"]
	# 鎏金/七彩：脉动光晕
	if vr >= 2 and _glow_tex != null:
		var pulse := 0.5 + 0.5 * sin(_t * 2.4 + sw["phase"])
		var col := FishData.variant_color(vr)
		var gs: float = sw["dsize"] * (1.7 + 0.35 * pulse)
		draw_texture_rect(_glow_tex, Rect2(pos - Vector2(gs, gs) * 0.5, Vector2(gs, gs)),
			false, Color(col.r, col.g, col.b, 0.20 + 0.22 * pulse))
	# 鱼身：按游动方向翻转，轻微随上下游动倾斜
	var tex: Texture2D = sw["tex"]
	if tex != null:
		var tsz := Vector2(tex.get_size())
		var aspect := tsz.y / maxf(1.0, tsz.x)
		var w: float = sw["dsize"]
		var rect := Rect2(-w * 0.5, -w * aspect * 0.5, w, w * aspect)
		var face_right: bool = sw["dir"] > 0.0
		var flip := face_right if FISH_FACES_LEFT else not face_right
		var tilt := cos(_t * sw["freq"] + sw["phase"]) * 0.10 * (1.0 if face_right else -1.0)
		draw_set_transform(pos, tilt, Vector2(-1.0 if flip else 1.0, 1.0))
		var tint := Color.WHITE
		if vr >= 1:
			tint = Color.WHITE.lerp(FishData.variant_color(vr), 0.22)
		draw_texture_rect(tex, rect, false, tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 七彩：环绕小星点
	if vr >= 3:
		for k in 3:
			var ang := _t * 2.0 + k * TAU / 3.0
			var rp: float = sw["dsize"] * 0.55
			var sp := pos + Vector2(cos(ang), sin(ang) * 0.6) * rp
			var a := 0.4 + 0.4 * sin(_t * 4.0 + k)
			draw_circle(sp, 1.6, Color(0.98, 0.92, 1.0, a))


## 软光晕径向纹理（白心 → 透明边），变体光晕复用此图按颜色染色。
func _make_glow() -> ImageTexture:
	var s := 48
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := s * 0.5
	for y in s:
		for x in s:
			var d := Vector2(x - c, y - c).length() / (s * 0.5)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


# ============================ 点鱼看纪录 ============================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss_card()
		var hit := _swimmer_at(event.position)
		if not hit.is_empty():
			_show_card(hit, event.position)


func _swimmer_at(p: Vector2) -> Dictionary:
	var best := {}
	var best_d := 1e9
	for sw in swimmers:
		var pos := Vector2(sw["x"], sw["y"] + sin(_t * sw["freq"] + sw["phase"]) * sw["amp"])
		var d := p.distance_to(pos)
		if d < sw["dsize"] * 0.7 and d < best_d:
			best_d = d
			best = sw
	return best


func _dismiss_card() -> void:
	if is_instance_valid(_card):
		_card.queue_free()
	_card = null


func _show_card(sw: Dictionary, at: Vector2) -> void:
	var c: Dictionary = sw["c"]
	var id := str(c["id"])
	var tier := FishData.tier_of(id)
	var vr := int(c.get("var", 0))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIPanels.panel_bg_style())
	card.z_index = 60
	var mg := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		mg.add_theme_constant_override("margin_" + side, 10 if side in ["left", "right"] else 8)
	card.add_child(mg)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	mg.add_child(box)
	# 头部：图标 + 名字（含变体宝石/星级）+ 关闭
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(g._fish_icon(id, 44))
	var ni := VBoxContainer.new()
	ni.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ni.add_theme_constant_override("separation", 0)
	var nm := Label.new()
	nm.text = FishData.variant_label(vr) + FishData.quality_label(int(c.get("q", 0))) \
		+ FishData.size_tag(id, float(c["w"])) + FishData.display_name(id)
	nm.add_theme_font_size_override("font_size", 15)
	nm.add_theme_color_override("font_color",
		FishData.variant_color(vr) if vr >= 1 else g._ui_tier_color(tier, false))
	ni.add_child(nm)
	var sub := Label.new()
	sub.text = "%s · 这条 %.2fkg" % [FishData.TIER_NAMES[tier], float(c["w"])]
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.72, 0.70, 0.64))
	ni.add_child(sub)
	head.add_child(ni)
	var close := Button.new()
	close.text = "×"
	close.flat = true
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(24, 22)
	close.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	close.pressed.connect(_dismiss_card)
	head.add_child(close)
	box.add_child(head)
	# 纪录：图鉴里的该鱼种纪录（最大体重 / 累计 / 首捕日 / 变体）
	var rec: Dictionary = g.dex.get(id, {})
	var maxw := float(rec.get("w", float(c["w"])))
	var fd := str(rec.get("fd", ""))
	var lines := [
		"最大纪录 %.2fkg" % maxw,
		"累计钓获 ×%d" % int(rec.get("n", 1)),
		"首次捕获 %s" % (fd if fd != "" else "很久以前"),
		"变体 %s" % (FishData.variant_label(vr).replace("·", "") if vr >= 1 else "普通"),
	]
	for line in lines:
		var l := Label.new()
		l.text = line
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", Color(0.80, 0.78, 0.72))
		box.add_child(l)
	# 捞回鱼篓
	var back := Button.new()
	back.text = "捞回鱼篓"
	back.custom_minimum_size = Vector2(0, 30)
	UIPanels.apply_button_skin(back, false)
	back.pressed.connect(func() -> void: Decor.remove_to_inventory(g, int(sw["idx"])))
	box.add_child(back)
	add_child(card)
	_card = card
	# 卡片摆到鱼附近并钳进缸内
	var csz := Vector2(186, 168)
	var pos := at + Vector2(12, -csz.y * 0.5)
	pos.x = clampf(pos.x, 4.0, maxf(4.0, VIEW_SIZE.x - csz.x - 4.0))
	pos.y = clampf(pos.y, 4.0, maxf(4.0, VIEW_SIZE.y - csz.y - 4.0))
	card.position = pos
	card.custom_minimum_size = csz
