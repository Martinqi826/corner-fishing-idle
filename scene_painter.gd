extends Node2D
## 角落垂钓 · 场景绘制
## 优先用 Codex 产出的真实美术（docs/art_direction.md 规范）；缺失时回退程序化绘制。
## main.gd 钓鱼状态机通过 dip / add_ripple() 驱动浮标与水花。
##
## 预留资源入口（缺失自动回退）：
##   背景主图  res://assets/art/background/corner_scene_winter_base.png
##   波光叠层  res://assets/art/background/water_highlight_overlay.png
##   浮标      res://assets/art/props/bobber_idle.png / bobber_bite.png
##   （fisher_idle/rod/lantern 已合入 base 主图；分层背景到货后再切换图层模式）

const W := 520.0
const H := 400.0
const HORIZON := 206.0

# 合成主图模式下的咬钩点（≈烤进主图里的钓线落水处），涟漪/飘字以此为锚。
const COMPOSITE_BITE := Vector2(322, 300)

# —— 程序化回退配色 ——
const C_GLOW := Color(0.97, 0.91, 0.80)
const C_MT_FAR := Color(0.64, 0.69, 0.75)
const C_SNOW := Color(0.94, 0.96, 0.97)
const C_PINE := Color(0.34, 0.46, 0.43)
const C_PINE_HI := Color(0.45, 0.55, 0.50)
const C_WATER_TOP := Color(0.69, 0.80, 0.82)
const C_WATER_BOT := Color(0.50, 0.64, 0.71)
const C_SHIMMER := Color(0.96, 0.98, 0.98)
const C_SNOWBANK := Color(0.89, 0.91, 0.91)
const C_ROCK := Color(0.55, 0.56, 0.57)
const C_COAT := Color(0.44, 0.47, 0.39)
const C_DARK := Color(0.28, 0.28, 0.26)
const C_SKIN := Color(0.80, 0.72, 0.62)
const C_LANTERN := Color(1.0, 0.84, 0.48)

var t := 0.0
var dip := 0.0
var use_composite := false
var _base: Texture2D
var _water_overlay: Texture2D
var _bobber_idle: Texture2D
var _bobber_bite: Texture2D
var _bobber := Vector2(296, HORIZON + 80)
var _rod_tip := Vector2(338, 244)
var _ripples: Array = []


func _ready() -> void:
	_base = _tex("res://assets/art/background/corner_scene_winter_base.png")
	_water_overlay = _tex("res://assets/art/background/water_highlight_overlay.png")
	_bobber_idle = _tex("res://assets/art/props/bobber_idle.png")
	_bobber_bite = _tex("res://assets/art/props/bobber_bite.png")
	use_composite = _base != null


func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _process(delta: float) -> void:
	t += delta
	for r in _ripples:
		r["r"] += delta * 40.0
		r["life"] -= delta * 1.1
	_ripples = _ripples.filter(func(x): return x["life"] > 0.0)
	queue_redraw()


func bobber_pos() -> Vector2:
	if use_composite:
		return COMPOSITE_BITE
	return Vector2(_bobber.x, _bobber.y + sin(t * 2.0) * 1.5 + dip * 9.0)


func add_ripple(pos: Vector2, max_r := 28.0) -> void:
	_ripples.append({"pos": pos, "r": 4.0, "max_r": max_r, "life": 1.0})


# ============================ 绘制 ============================

func _draw() -> void:
	if use_composite:
		_draw_composite()
	else:
		_draw_procedural()


func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


# —— 真实美术：主图 + 动态波光 + 浮标 + 涟漪 ——
func _draw_composite() -> void:
	draw_texture(_base, Vector2.ZERO)
	if _water_overlay != null:
		var a: float = clampf(0.22 + 0.12 * sin(t * 0.8), 0.0, 0.45)
		var off := Vector2(sin(t * 0.4) * 3.0, 0.0)
		draw_texture_rect(_water_overlay, Rect2(off, Vector2(W, H)), false, Color(1, 1, 1, a))
	_draw_ripples()
	_draw_bobber_sprite()


func _draw_bobber_sprite() -> void:
	var p := bobber_pos()
	var tex := _bobber_bite if (dip > 0.5 and _bobber_bite != null) else _bobber_idle
	if tex == null:
		_draw_bobber_proc(p)
		return
	var sz := Vector2(tex.get_size())
	draw_texture(tex, p - sz * 0.5 + Vector2(0, sin(t * 2.0) * 1.5 + dip * 8.0))


func _draw_bobber_proc(p: Vector2) -> void:
	var rr := 5.0 + sin(t * 2.0) * 1.0
	draw_arc(p + Vector2(0, 2), rr, 0.0, TAU, 18, _a(C_SHIMMER, 0.25), 1.0)
	draw_circle(p, 3.2, Color(0.86, 0.42, 0.34))
	draw_circle(p + Vector2(0, -3), 2.0, Color(0.96, 0.96, 0.93))


# ============================ 程序化回退场景 ============================

func _draw_procedural() -> void:
	_draw_glow()
	_draw_mountains()
	_draw_treeline()
	_draw_water()
	_draw_shimmer()
	_draw_ripples()
	_draw_bank()
	_draw_angler()
	_draw_bobber_proc(bobber_pos())


func _draw_glow() -> void:
	var top := 72.0
	var pts := PackedVector2Array([
		Vector2(150, top), Vector2(W, top), Vector2(W, HORIZON), Vector2(150, HORIZON)])
	var clear := _a(C_GLOW, 0.0)
	draw_polygon(pts, PackedColorArray([clear, clear, _a(C_GLOW, 0.5), _a(C_GLOW, 0.12)]))


func _draw_mountains() -> void:
	var far := PackedVector2Array([
		Vector2(150, HORIZON), Vector2(150, 170), Vector2(208, 142),
		Vector2(252, 160), Vector2(300, 120), Vector2(356, 154),
		Vector2(408, 130), Vector2(468, 152), Vector2(W, 140), Vector2(W, HORIZON)])
	draw_colored_polygon(far, _a(C_MT_FAR, 0.92))
	_snowcap(Vector2(300, 120), 24, 17)
	_snowcap(Vector2(408, 130), 20, 14)
	_snowcap(Vector2(208, 142), 16, 11)


func _snowcap(peak: Vector2, hw: float, h: float) -> void:
	var pts := PackedVector2Array([
		peak, peak + Vector2(hw * 0.55, h), peak + Vector2(hw * 0.18, h * 0.65),
		peak + Vector2(-hw * 0.22, h), peak + Vector2(-hw * 0.55, h * 0.78)])
	draw_colored_polygon(pts, _a(C_SNOW, 0.95))


func _draw_treeline() -> void:
	var x := 150.0
	var i := 0
	while x < W - 4:
		var hh := 15.0 + (3.0 if i % 2 == 0 else 8.0)
		_pine(Vector2(x, HORIZON + 1), hh, hh * 0.5, C_PINE if i % 2 == 0 else C_PINE_HI, 0.85)
		x += 12.5
		i += 1


func _pine(base: Vector2, h: float, hw: float, col: Color, a := 1.0) -> void:
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(0, -h), base + Vector2(hw, 0), base + Vector2(-hw, 0)]), _a(col, a))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(0, -h * 1.5), base + Vector2(hw * 0.66, -h * 0.5),
		base + Vector2(-hw * 0.66, -h * 0.5)]), _a(col, a))


func _draw_water() -> void:
	var pts := PackedVector2Array([
		Vector2(0, HORIZON), Vector2(W, HORIZON), Vector2(W, H), Vector2(0, H)])
	draw_polygon(pts, PackedColorArray([
		_a(C_WATER_TOP, 0.0), _a(C_WATER_TOP, 0.9),
		_a(C_WATER_BOT, 0.9), _a(C_WATER_BOT, 0.0)]))


func _draw_shimmer() -> void:
	for i in 7:
		var yy := HORIZON + 16.0 + i * 23.0
		if yy > H - 6.0:
			continue
		var phase := t * 0.6 + i * 1.3
		var cx := 308.0 + sin(phase) * 12.0
		var hw := 58.0 + 22.0 * cos(phase * 0.7)
		var a: float = max(0.05, 0.11 + 0.06 * sin(phase * 1.3))
		a *= clampf((cx - 60.0) / 180.0, 0.15, 1.0)
		draw_line(Vector2(cx - hw, yy), Vector2(cx + hw, yy), _a(C_SHIMMER, a), 2.0)


func _draw_ripples() -> void:
	for r in _ripples:
		var k: float = clampf(1.0 - r["r"] / r["max_r"], 0.0, 1.0)
		var a: float = clampf(r["life"], 0.0, 1.0) * 0.5 * k
		if a > 0.02:
			draw_arc(r["pos"], r["r"], 0.0, TAU, 26, _a(C_SHIMMER, a), 1.5)


func _draw_bank() -> void:
	var bank := PackedVector2Array([
		Vector2(W, 248), Vector2(372, 300), Vector2(404, 332), Vector2(W, H)])
	draw_colored_polygon(bank, _a(C_SNOWBANK, 0.95))
	draw_circle(Vector2(372, 304), 9.0, _a(C_ROCK, 0.9))
	draw_circle(Vector2(398, 318), 7.0, _a(C_ROCK, 0.9))
	draw_circle(Vector2(150, HORIZON + 14), 6.0, _a(C_ROCK, 0.55))
	draw_circle(Vector2(166, HORIZON + 18), 4.0, _a(C_ROCK, 0.5))
	_pine(Vector2(502, 252), 42.0, 18.0, C_PINE)
	_pine(Vector2(516, 276), 32.0, 14.0, C_PINE)


func _draw_angler() -> void:
	var hip := Vector2(430, 294)
	draw_line(hip + Vector2(-10, 4), hip + Vector2(-12, 20), C_DARK, 2.0)
	draw_line(hip + Vector2(10, 4), hip + Vector2(12, 20), C_DARK, 2.0)
	draw_line(hip + Vector2(-13, 4), hip + Vector2(13, 4), C_DARK, 3.0)
	var lp := hip + Vector2(28, -4)
	draw_circle(lp, 11.0, _a(C_LANTERN, 0.22))
	draw_circle(lp, 4.0, C_LANTERN)
	draw_line(lp + Vector2(0, 4), lp + Vector2(0, 18), C_DARK, 1.5)
	draw_colored_polygon(PackedVector2Array([
		hip + Vector2(-13, 2), hip + Vector2(13, 4),
		hip + Vector2(9, -30), hip + Vector2(-9, -32)]), C_COAT)
	draw_circle(hip + Vector2(-3, -42), 7.5, C_SKIN)
	draw_colored_polygon(PackedVector2Array([
		hip + Vector2(-12, -43), hip + Vector2(5, -45),
		hip + Vector2(3, -53), hip + Vector2(-9, -51)]), C_DARK)
	var hands := hip + Vector2(-9, -18)
	draw_line(hands, _rod_tip, Color(0.32, 0.25, 0.18), 2.0)
	draw_line(_rod_tip, bobber_pos(), _a(Color(0.95, 0.95, 0.95), 0.5), 1.0)
