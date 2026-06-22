class_name Aquarium
extends Control
## 活水族箱（Task 1）：把放进缸里的收藏鱼（g.display）渲染成沿平滑路径游动的小鱼缸。
## 兑现 Chillquarium 式收集深度——鎏金/七彩变体带光晕粒子，点鱼弹出它的纪录卡。
## 自管动画（_process 推进、_draw 合成），不依赖 tween，避免面板重建时残留。
## 字段沿用主节点的 display（不另起炉灶）；纪录取自 g.dex（首捕日期为 v11 新增）。
## 缸景：竖向水体渐变 + 斜射光柱/焦散 + 砂砾/石头/水草/沉木 + 悬浮微粒 + 气泡 + 景深柔影。

var g                                   # CornerFishing 主节点（弱类型避免循环依赖）
var swimmers: Array = []                # 每条 {idx, c, tex, x, dir, speed, y, amp, freq, phase, vr, dsize, depth, vy, vyph}
var bubbles: Array = []                 # 缸底升起的气泡 {x, y, r, spd, sway, phase}
var plants: Array = []                  # 缸底水草丛 {x, base_y, blades, back}
var rocks: Array = []                   # 缸底石头 {x, w, h, col}
var driftwood: Dictionary = {}          # 斜插沉木 {x, y, len, ang, w}
var motes: Array = []                   # 悬浮浮游微粒（marine snow），填充空旷水域 {x, y, r, vx, vy, a}
var _t := 0.0
var _glow_tex: Texture2D
var _water_tex: Texture2D               # 上亮下深的水体竖向渐变（替代纯色矩形）
var _card: Control = null               # 当前打开的纪录卡（点空白处关闭）

const VIEW_SIZE := Vector2(472, 220)
const MARGIN := 26.0                     # 鱼游动的左右留白
const FISH_FACES_LEFT := true           # 鱼图标默认朝左 → 向右游时才水平翻转（修：原 false 致全部倒着游）
const FLOOR_H := 18.0                    # 缸底砂砾带高度
const TOP_COL := Color(0.16, 0.41, 0.45) # 水体上部：透光偏青，给"通透"
const BOT_COL := Color(0.05, 0.12, 0.19) # 水体底部：沉深蓝绿，给体积


func setup(host) -> void:
	g = host
	custom_minimum_size = VIEW_SIZE
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_glow_tex = _make_glow()
	_water_tex = _make_water_tex()
	_build_swimmers()
	_build_decor()
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
		# depth 0=远(偏上、小、融入水色) → 1=近(偏下、大、清晰)，造景深层次
		var depth := rng.randf()
		swimmers.append({
			"idx": i,
			"c": c,
			"tex": g._fish_texture(str(c["id"])),
			"vr": int(c.get("var", 0)),
			"dsize": clampf(30.0 + tier * 2.6, 30.0, 46.0) * lerpf(0.78, 1.14, depth),
			"depth": depth,
			"x": rng.randf_range(MARGIN, VIEW_SIZE.x - MARGIN),
			"dir": 1.0 if rng.randf() < 0.5 else -1.0,
			"speed": rng.randf_range(15.0, 30.0) * lerpf(0.75, 1.15, depth),
			"y": lerpf(40.0, VIEW_SIZE.y - FLOOR_H - 18.0, depth) + rng.randf_range(-14.0, 14.0),
			"amp": rng.randf_range(5.0, 12.0),
			"freq": rng.randf_range(0.5, 1.2),
			"phase": rng.randf() * TAU,
			"vy": rng.randf_range(0.12, 0.3),       # 垂直缓漂频率，让游动不只在一条水平线上
			"vyph": rng.randf() * TAU,
		})
	swimmers.sort_custom(func(a, b): return a["depth"] < b["depth"])  # 远先画、近后画


## 缸景：水草丛 + 石头 + 沉木 + 浮游微粒 + 气泡。一次性随机生成，之后靠 _t 做确定性动画。
func _build_decor() -> void:
	bubbles.clear()
	plants.clear()
	rocks.clear()
	motes.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var floor_y := VIEW_SIZE.y - FLOOR_H
	# 水草：多丛、前后交错、部分高草伸到缸中部，把空旷的中段填起来
	var spots := [0.05, 0.12, 0.21, 0.33, 0.5, 0.66, 0.79, 0.88, 0.95]
	for si in spots.size():
		var s: float = spots[si]
		var back := (si % 2 == 0)               # 隔丛靠后，前后两层更密
		var blades := []
		var n := rng.randi_range(3, 6)
		for b in n:
			blades.append({
				"dx": rng.randf_range(-12.0, 12.0),
				"h": rng.randf_range(42.0, 112.0) * (0.85 if back else 1.0),  # 高草可达缸高一半
				"w": rng.randf_range(3.0, 6.0),
				"ph": rng.randf() * TAU,
				"bend": rng.randf_range(0.6, 1.4),
			})
		plants.append({
			"x": VIEW_SIZE.x * s + rng.randf_range(-8.0, 8.0),
			"base_y": floor_y + 2.0,
			"blades": blades,
			"back": back,
		})
	# 石头：3~4 块，大小错落
	for k in rng.randi_range(3, 4):
		var w := rng.randf_range(24.0, 56.0)
		rocks.append({
			"x": rng.randf_range(32.0, VIEW_SIZE.x - 32.0),
			"w": w,
			"h": w * rng.randf_range(0.4, 0.62),
			"col": Color(0.12, 0.14, 0.16).lerp(Color(0.19, 0.20, 0.21), rng.randf()),
		})
	# 沉木：一根斜插枯木，作为缸中焦点物
	driftwood = {
		"x": VIEW_SIZE.x * rng.randf_range(0.28, 0.6),
		"y": floor_y + 2.0,
		"len": rng.randf_range(72.0, 104.0),
		"ang": -rng.randf_range(0.5, 0.92),     # 向上斜插
		"w": rng.randf_range(8.0, 12.0),
	}
	# 悬浮浮游微粒：散布全缸，缓慢下沉横移，填充空旷水域
	for k in 34:
		motes.append({
			"x": rng.randf_range(0.0, VIEW_SIZE.x),
			"y": rng.randf_range(0.0, floor_y),
			"r": rng.randf_range(0.6, 1.6),
			"vx": rng.randf_range(-3.0, 3.0),
			"vy": rng.randf_range(2.0, 7.0),
			"a": rng.randf_range(0.06, 0.18),
		})
	# 气泡：从缸底零散升起
	for k in 16:
		bubbles.append({
			"x": rng.randf_range(MARGIN, VIEW_SIZE.x - MARGIN),
			"y": rng.randf_range(0.0, VIEW_SIZE.y),
			"r": rng.randf_range(1.2, 3.0),
			"spd": rng.randf_range(10.0, 22.0),
			"sway": rng.randf_range(3.0, 7.0),
			"phase": rng.randf() * TAU,
		})


## 上亮下深的水体竖向渐变纹理（1px 宽、拉伸填充）；顶部叠一抹水面透光。
func _make_water_tex() -> ImageTexture:
	var h := 96
	var img := Image.create(1, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / float(h - 1)
		var col := TOP_COL.lerp(BOT_COL, pow(t, 1.15))
		if t < 0.12:   # 顶部 ~12% 叠水面透光，越靠上越亮
			col = col.lerp(Color(0.32, 0.56, 0.58), (0.12 - t) / 0.12 * 0.5)
		img.set_pixel(0, y, Color(col.r, col.g, col.b, 0.95))
	return ImageTexture.create_from_image(img)


func _process(delta: float) -> void:
	if swimmers.is_empty() and bubbles.is_empty():
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
	# 气泡上升 + 横向轻摆；越顶则回到缸底重生
	for bb in bubbles:
		bb["y"] -= bb["spd"] * delta
		if bb["y"] <= 6.0:
			bb["y"] = VIEW_SIZE.y - FLOOR_H * 0.5
			bb["x"] = clampf(bb["x"] + (bb["phase"] - PI) * 2.0, MARGIN, VIEW_SIZE.x - MARGIN)
	# 浮游微粒：缓慢下沉 + 横移，落到砂面回到顶部
	var floor_y := VIEW_SIZE.y - FLOOR_H
	for m in motes:
		m["x"] = fposmod(m["x"] + m["vx"] * delta, VIEW_SIZE.x)
		m["y"] += m["vy"] * delta
		if m["y"] > floor_y:
			m["y"] = 0.0
	queue_redraw()


# ============================ 绘制 ============================

func _draw() -> void:
	var sz := size if size.x > 1.0 else VIEW_SIZE
	# ① 水体：上亮下深竖向渐变（替代纯色矩形+横线，去掉"表格"廉价感）
	if _water_tex != null:
		draw_texture_rect(_water_tex, Rect2(Vector2.ZERO, sz), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, sz), BOT_COL)
	# ② 顶部斜射光柱（caustics）
	_draw_light_shafts(sz)
	# ③ 漂动焦散光斑
	for i in 4:
		var gx := sz.x * (0.2 + 0.22 * i) + sin(_t * 0.25 + i * 1.7) * 36.0
		var gy := sz.y * (0.18 + 0.09 * i) + cos(_t * 0.2 + i) * 10.0
		var gr := 70.0 + 18.0 * sin(_t * 0.3 + i)
		draw_texture_rect(_glow_tex, Rect2(Vector2(gx - gr, gy - gr), Vector2(gr, gr) * 2.0),
			false, Color(0.55, 0.82, 0.80, 0.05))
	# ④ 缸底砂砾带
	_draw_floor(sz)
	# ⑤ 石头
	for r in rocks:
		_draw_rock(r, sz)
	# ⑤b 沉木（缸中焦点物）
	_draw_driftwood(sz)
	# ⑥ 后景水草（鱼之前画 → 在鱼后面）
	for p in plants:
		if p["back"]:
			_draw_plant(p, true)
	# ⑦ 鱼（远→近已排序；各自带缸底柔影）
	for sw in swimmers:
		_draw_swimmer(sw, sz)
	# ⑦b 悬浮浮游微粒（填鱼周空白）
	_draw_motes()
	# ⑧ 前景水草（鱼之后画 → 个别遮住鱼，造穿插）
	for p in plants:
		if not p["back"]:
			_draw_plant(p, false)
	# ⑨ 气泡（最前）
	for bb in bubbles:
		_draw_bubble(bb)
	# ⑩ 暗角：左右轻压，把视线收进缸里
	_draw_vignette(sz)


## 顶部两道斜光柱，缓慢横移。
func _draw_light_shafts(sz: Vector2) -> void:
	for i in 2:
		var cx := sz.x * (0.32 + 0.4 * i) + sin(_t * 0.18 + i * 2.0) * 30.0
		var pts := PackedVector2Array([
			Vector2(cx - 16.0, 0), Vector2(cx + 16.0, 0),
			Vector2(cx + 64.0, sz.y * 0.78), Vector2(cx - 64.0, sz.y * 0.78)])
		draw_colored_polygon(pts, Color(0.6, 0.85, 0.82, 0.035))


## 缸底砂砾：暖灰多边形，顶边 sin 起伏，撒几粒亮砂。
func _draw_floor(sz: Vector2) -> void:
	var fy := sz.y - FLOOR_H
	var pts := PackedVector2Array()
	pts.append(Vector2(0, sz.y))
	var steps := 12
	for i in steps + 1:
		var x := sz.x * float(i) / float(steps)
		var y := fy + sin(x * 0.05 + 1.3) * 2.6 + cos(x * 0.11) * 1.4
		pts.append(Vector2(x, y))
	pts.append(Vector2(sz.x, sz.y))
	draw_colored_polygon(pts, Color(0.17, 0.18, 0.17))
	for i in 9:   # 几粒亮砂
		var gx := sz.x * (0.06 + 0.1 * i)
		var gy := fy + 4.0 + fmod(gx, 7.0)
		draw_circle(Vector2(gx, gy), 0.9, Color(0.34, 0.34, 0.30, 0.6))


func _draw_rock(r: Dictionary, sz: Vector2) -> void:
	var cx: float = r["x"]
	var by := sz.y - FLOOR_H + 4.0
	var w: float = r["w"]
	var h: float = r["h"]
	var pts := PackedVector2Array()
	var n := 16
	for i in n:   # 上半圆弧 → 半埋的圆润石
		var a := PI + PI * float(i) / float(n - 1)
		pts.append(Vector2(cx + cos(a) * w * 0.5, by + sin(a) * h))
	draw_colored_polygon(pts, r["col"])
	draw_circle(Vector2(cx - w * 0.12, by - h * 0.62), w * 0.16, Color(0.3, 0.32, 0.34, 0.4))


## 斜插沉木：暖棕枯木 + 一点附生苔，作为缸中焦点物。
func _draw_driftwood(sz: Vector2) -> void:
	if driftwood.is_empty():
		return
	var base := Vector2(driftwood["x"], sz.y - FLOOR_H + 3.0)
	var dir := Vector2(cos(driftwood["ang"]), sin(driftwood["ang"]))
	var tip: Vector2 = base + dir * float(driftwood["len"])
	var w: float = driftwood["w"]
	draw_line(base, tip, Color(0.20, 0.14, 0.10), w, true)                    # 木身
	draw_line(base, tip, Color(0.28, 0.20, 0.13), w * 0.5, true)             # 中层
	draw_line(base + dir * (w * 0.3), tip, Color(0.34, 0.26, 0.17, 0.6), w * 0.18, true)  # 高光纹
	draw_circle(tip, w * 0.5, Color(0.24, 0.17, 0.11))                       # 末端断口
	for i in 4:   # 附生苔点
		var f := 0.3 + 0.16 * i
		var mp := base + dir * (float(driftwood["len"]) * f) + Vector2(0, -w * 0.4)
		draw_circle(mp, 2.2, Color(0.12, 0.30, 0.20, 0.7))


## 一丛水草：每片叶子是随 _t 摆动的多段曲线（剪影感）。
func _draw_plant(p: Dictionary, back: bool) -> void:
	var base := Vector2(p["x"], p["base_y"])
	var col := Color(0.07, 0.22, 0.18, 0.55) if back else Color(0.10, 0.32, 0.24, 0.78)
	for bl in p["blades"]:
		var bx: float = base.x + bl["dx"]
		var h: float = bl["h"] * (0.8 if back else 1.0)
		var segs := 7
		var line := PackedVector2Array()
		for i in segs + 1:
			var f := float(i) / float(segs)
			var sway := sin(_t * 0.8 + bl["ph"] + f * bl["bend"]) * (5.0 + 7.0 * f)
			line.append(Vector2(bx + sway, base.y - h * f))
		draw_polyline(line, col, bl["w"] * (0.7 if back else 1.0), true)


## 悬浮浮游微粒（marine snow）：柔白小点，填充空旷水域。
func _draw_motes() -> void:
	for m in motes:
		draw_circle(Vector2(m["x"], m["y"]), m["r"], Color(0.78, 0.86, 0.84, m["a"]))


func _draw_bubble(bb: Dictionary) -> void:
	var x: float = bb["x"] + sin(_t * 1.6 + bb["phase"]) * bb["sway"]
	var pos := Vector2(x, bb["y"])
	var r: float = bb["r"]
	draw_circle(pos, r, Color(0.7, 0.86, 0.9, 0.12))
	draw_arc(pos, r, 0.0, TAU, 12, Color(0.85, 0.95, 0.98, 0.32), 0.9, true)
	draw_circle(pos - Vector2(r * 0.3, r * 0.3), r * 0.28, Color(1, 1, 1, 0.4))


## 左右暗角：各三条递减 alpha 的半透明条，柔化边缘、收拢视线。
func _draw_vignette(sz: Vector2) -> void:
	for i in 3:
		var a := 0.16 - i * 0.05
		var wdt := 6.0
		draw_rect(Rect2(i * wdt, 0, wdt, sz.y), Color(0.02, 0.05, 0.08, a))
		draw_rect(Rect2(sz.x - (i + 1) * wdt, 0, wdt, sz.y), Color(0.02, 0.05, 0.08, a))


func _draw_swimmer(sw: Dictionary, sz: Vector2) -> void:
	var depth: float = sw.get("depth", 1.0)
	var drift := sin(_t * sw["vy"] + sw["vyph"]) * 10.0   # 垂直缓漂
	var pos := Vector2(sw["x"], sw["y"] + drift + sin(_t * sw["freq"] + sw["phase"]) * sw["amp"])
	var vr: int = sw["vr"]
	# 缸底柔影：椭圆暗斑，随景深变淡变小
	var floor_y := sz.y - FLOOR_H + 3.0
	var shw: float = sw["dsize"] * lerpf(0.5, 0.9, depth)
	draw_texture_rect(_glow_tex, Rect2(Vector2(pos.x - shw, floor_y - shw * 0.22),
		Vector2(shw * 2.0, shw * 0.44)), false, Color(0.0, 0.0, 0.0, lerpf(0.06, 0.20, depth)))
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
		# 景深：远处的鱼融入水色、略降亮度/不透明
		tint = tint.lerp(TOP_COL, (1.0 - depth) * 0.35)
		tint.a = lerpf(0.82, 1.0, depth)
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
		var drift := sin(_t * sw["vy"] + sw["vyph"]) * 10.0
		var pos := Vector2(sw["x"], sw["y"] + drift + sin(_t * sw["freq"] + sw["phase"]) * sw["amp"])
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
	card.custom_minimum_size = Vector2(186, 0)   # 定宽，高随内容（按真实高摆放，不再用写死的 168）
	card.top_level = true                         # 脱离鱼缸的 clip_contents：卡片可越过缸底/缸边完整显示，不被裁
	add_child(card)
	_card = card
	# 用内容真实尺寸 + 钳进整张面板可视范围（而非缸内 220 高）：偏下点鱼时卡片向面板下方延伸也能完整显示。
	var csz := card.get_combined_minimum_size()
	csz.x = maxf(csz.x, 186.0)
	var gpt := get_global_transform() * at        # 鱼缸局部点 → 画布全局（top_level 用画布坐标）
	var pos := gpt + Vector2(12.0, -csz.y * 0.5)
	var area: Rect2 = g._panel.get_global_rect() if (g != null and is_instance_valid(g._panel)) else get_global_rect()
	pos.x = clampf(pos.x, area.position.x + 4.0, maxf(area.position.x + 4.0, area.end.x - csz.x - 4.0))
	pos.y = clampf(pos.y, area.position.y + 4.0, maxf(area.position.y + 4.0, area.end.y - csz.y - 4.0))
	card.position = pos
