extends Node2D
## 角落垂钓 · 场景绘制
## 优先用 Codex 产出的真实美术；缺失时回退程序化绘制。
## 动态效果层按 docs/dynamic_art_plan.md 接入（全部透明叠加，只播放不修改资源）：
##   雾气微风 / 水流高光循环 / 雪粒漂移 / 小动物低频事件 / 浮漂涟漪 / 灯光呼吸
## main.gd 钓鱼状态机通过 dip / add_ripple() 驱动浮标与水花。

const W := 520.0
const H := 400.0
const HORIZON := 206.0

# 合成主图模式下的咬钩点（= 主图里画的小浮漂/钓线落水处），涟漪/飘字以此为锚。
# 默认值按当前主图实测；main.gd 可从 ui_layout.json 覆盖（Codex 美术更新时同步）。
var bite_point := Vector2(384, 344)

# 浮漂精灵缩放：资源是 64/96 大画布，原尺寸在场景里过大，按场景比例缩小。
const BOBBER_SCALE := 0.24
# 灯光呼吸锚点回退值（dynamic_art_plan.md 给定的近似位置；
# 实际锚点在 _ready 里扫描主图暖色像素质心自动定位，主图更新也不会错位）
const LANTERN_POS := Vector2(438, 274)

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
var _water_overlay: Texture2D     # 旧版波光叠层（无新版帧动画时的回退）
var _bobber_idle: Texture2D
var _bobber_bite: Texture2D
var _bobber := Vector2(296, HORIZON + 80)
var _rod_tip := Vector2(338, 244)
var _ripples: Array = []

# —— 动态效果层（Codex 资源，缺失自动跳过对应效果）——
var _shimmer_tex: Array = []      # 6 帧水流高光
var _mist_tex: Array = []         # 3 层雾气
var _snow_tex: Array = []         # 3 层雪粒
var _ripple_tex: Array = []       # 4 帧浮漂涟漪
var _glow_tex: Array = []         # 4 帧灯光呼吸
var _wild_tex: Dictionary = {}    # 小动物事件精灵

var _mist_par: Array = []         # 每层 {period, amp, phase, alpha}
var _snow_par: Array = []         # 每层 {period, dist, phase, alpha}
var _shimmer_period := 6.0
var _glow_period := 4.5
var _pulse_t := 8.0               # 浮漂待机涟漪计时

# 小动物事件状态
var quiet := false      # 专注模式：停小动物低频事件
var _wild_kind := ""
var _wild_t := 0.0
var _wild_dur := 0.0
var _wild_from := Vector2.ZERO
var _wild_to := Vector2.ZERO
var _wild_scale := 0.25
var _wild_timer := 60.0
var _lantern := LANTERN_POS
var _prng := RandomNumberGenerator.new()


func _ready() -> void:
	_prng.randomize()
	_base = _tex("res://assets/art/background/corner_scene_winter_base.png")
	_water_overlay = _tex("res://assets/art/background/water_highlight_overlay.png")
	_bobber_idle = _tex("res://assets/art/props/bobber_idle.png")
	_bobber_bite = _tex("res://assets/art/props/bobber_bite.png")
	use_composite = _base != null
	# 动态效果层
	_shimmer_tex = _frames("res://assets/art/effects/water/water_shimmer_%02d.png", 6)
	_mist_tex = _frames("res://assets/art/effects/mist/mist_drift_%02d.png", 3)
	_snow_tex = _frames("res://assets/art/effects/snow/snow_drift_%02d.png", 3)
	_ripple_tex = _frames("res://assets/art/effects/ripple/bobber_ripple_%02d.png", 4)
	_glow_tex = _frames("res://assets/art/effects/light/lantern_glow_%02d.png", 4)
	for k in ["bird_fly_01", "rabbit_idle_01", "fox_peek_01", "fish_jump_01"]:
		var tx := _tex("res://assets/art/wildlife/%s.png" % k)
		if tx != null:
			_wild_tex[k.get_slice("_", 0)] = tx
	# 每层随机参数 + 随机相位（避免所有循环同步重启，plan 的 Motion Rules）
	_shimmer_period = _prng.randf_range(4.2, 5.5)
	_glow_period = _prng.randf_range(3.5, 5.5)
	for i in _mist_tex.size():
		_mist_par.append({
			"period": _prng.randf_range(18.0, 35.0),
			"amp": _prng.randf_range(8.0, 18.0),
			"phase": _prng.randf() * TAU,
			"alpha": _prng.randf_range(0.25, 0.55),
		})
	for i in _snow_tex.size():
		_snow_par.append({
			"speed": _prng.randf_range(7.0, 15.0),   # px/s 连续下落
			"sway": _prng.randf_range(6.0, 16.0),    # 横向摆动幅度
			"phase": _prng.randf(),
			"alpha": _prng.randf_range(0.22, 0.38),
		})
	# 首次小动物事件提前到 12~25s（让玩家尽快看到一次），之后恢复 45~120s 低频
	_wild_timer = _prng.randf_range(12.0, 25.0)
	_lantern = _detect_lantern()


## 在主图右下区域扫描暖橙色像素质心 = 灯笼位置（排除底部金色按钮行）。
## 找不到足够暖色像素时回退 plan 给的近似锚点。
func _detect_lantern() -> Vector2:
	if _base == null:
		return LANTERN_POS
	var img := _base.get_image()
	if img == null:
		return LANTERN_POS
	if img.is_compressed():
		img.decompress()
	var n := 0
	var sx := 0.0
	var sy := 0.0
	var ymax: int = mini(358, img.get_height())
	var xmax: int = mini(520, img.get_width())
	for y in range(260, ymax):
		for x in range(380, xmax):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.r > 0.59 and (c.r - c.b) > 0.235:
				n += 1
				sx += x
				sy += y
	if n < 30:
		return LANTERN_POS
	return Vector2(sx / n, sy / n)


func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _frames(pattern: String, count: int) -> Array:
	var out: Array = []
	for i in count:
		var tx := _tex(pattern % (i + 1))
		if tx == null:
			return []  # 帧不全则整组禁用，避免播放残缺动画
		out.append(tx)
	return out


func _process(delta: float) -> void:
	t += delta
	for r in _ripples:
		r["r"] += delta * 40.0
		r["life"] -= delta * 1.1
	_ripples = _ripples.filter(func(x): return x["life"] > 0.0)
	if use_composite:
		_tick_idle_pulse(delta)
		_tick_wildlife(delta)
	queue_redraw()


## 浮漂待机时偶发的轻涟漪（钓鱼暂停/等待间隙画面不至于完全静止）
func _tick_idle_pulse(delta: float) -> void:
	_pulse_t -= delta
	if _pulse_t <= 0.0:
		_pulse_t = _prng.randf_range(5.0, 9.0)
		if _ripples.is_empty():
			add_ripple(bobber_pos(), 18.0)


func set_quiet(q: bool) -> void:
	quiet = q
	if q:
		_wild_kind = ""


func _tick_wildlife(delta: float) -> void:
	if _wild_tex.is_empty() or quiet:
		return
	if _wild_kind == "":
		_wild_timer -= delta
		if _wild_timer <= 0.0:
			_start_wild()
	else:
		_wild_t += delta
		if _wild_t >= _wild_dur:
			_wild_kind = ""
			_wild_timer = _prng.randf_range(45.0, 120.0)


## 启动一次小动物事件；kind 为空时随机挑选（dynamic_art_plan.md 的出场参数）。
func _start_wild(kind := "") -> void:
	if _wild_tex.is_empty():
		return
	if kind == "" or not _wild_tex.has(kind):
		var keys := _wild_tex.keys()
		kind = keys[_prng.randi() % keys.size()]
	_wild_kind = kind
	_wild_t = 0.0
	match kind:
		"bird":
			_wild_dur = _prng.randf_range(5.0, 9.0)
			_wild_scale = _prng.randf_range(0.22, 0.35)
			var y0 := _prng.randf_range(105.0, 145.0)
			_wild_from = Vector2(W + 30.0, y0)
			_wild_to = Vector2(150.0, y0 - _prng.randf_range(10.0, 30.0))
		"rabbit":
			_wild_dur = _prng.randf_range(4.0, 8.0)
			_wild_scale = _prng.randf_range(0.18, 0.28)
			_wild_from = Vector2(_prng.randf_range(395.0, 430.0), 330.0)
			_wild_to = _wild_from
		"fox":
			_wild_dur = _prng.randf_range(3.0, 6.0)
			_wild_scale = _prng.randf_range(0.18, 0.28)
			_wild_from = Vector2(_prng.randf_range(488.0, 504.0), 296.0)
			_wild_to = _wild_from
		"fish":
			_wild_dur = _prng.randf_range(0.7, 1.1)
			_wild_scale = _prng.randf_range(0.22, 0.35)
			var fx := bite_point.x + _prng.randf_range(-34.0, 30.0)
			_wild_from = Vector2(fx, bite_point.y + 4.0)
			_wild_to = _wild_from
			add_ripple(_wild_from, 24.0)


func bobber_pos() -> Vector2:
	if use_composite:
		return bite_point
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


# —— 真实美术：主图 + 动态叠加层（图层顺序按 dynamic_art_plan.md）——
func _draw_composite() -> void:
	draw_texture(_base, Vector2.ZERO)
	_draw_mist_layer()
	_draw_shimmer_layer()
	_draw_snow_layer()
	_draw_wildlife()
	_draw_ripples()
	_draw_bobber_sprite()
	_draw_glow_layer()


## 雾气微风：每层异周期正弦漂移（约 ±20~40px），透明度做明显的浓淡呼吸。
func _draw_mist_layer() -> void:
	for i in _mist_tex.size():
		var p: Dictionary = _mist_par[i]
		var ph: float = TAU * t / p["period"] + p["phase"]
		var off := Vector2(sin(ph) * p["amp"] * 2.2, cos(ph * 0.7) * p["amp"] * 0.4)
		var a: float = p["alpha"] * (0.62 + 0.38 * sin(ph * 1.7))
		draw_texture(_mist_tex[i], off, Color(1, 1, 1, a))


## 水流高光：6 帧慢循环，相邻帧交叉淡化，整体透明度 0.35~0.65 缓慢起伏。
func _draw_shimmer_layer() -> void:
	if _shimmer_tex.is_empty():
		if _water_overlay != null:  # 回退旧版单张波光
			var a: float = clampf(0.22 + 0.12 * sin(t * 0.8), 0.0, 0.45)
			draw_texture_rect(_water_overlay, Rect2(Vector2(sin(t * 0.4) * 3.0, 0.0), Vector2(W, H)), false, Color(1, 1, 1, a))
		return
	var n := _shimmer_tex.size()
	var f: float = fposmod(t, _shimmer_period) / _shimmer_period * n
	var i0 := int(f) % n
	var i1 := (i0 + 1) % n
	var frac := f - floorf(f)
	var base_a := 0.55 + 0.2 * sin(t * 0.5)  # 0.35 ~ 0.75，呼吸更明显
	draw_texture(_shimmer_tex[i0], Vector2.ZERO, Color(1, 1, 1, base_a * (1.0 - frac)))
	draw_texture(_shimmer_tex[i1], Vector2.ZERO, Color(1, 1, 1, base_a * frac))


## 雪粒漂移：连续向下飘落（7~15 px/s）+ 横向轻摆，纵向 wrap 两次绘制实现无缝循环。
func _draw_snow_layer() -> void:
	for i in _snow_tex.size():
		var p: Dictionary = _snow_par[i]
		var yy: float = fposmod(t * p["speed"] + p["phase"] * H, H)
		var xx: float = sin(t * 0.35 + p["phase"] * TAU) * p["sway"]
		var col := Color(1, 1, 1, p["alpha"])
		draw_texture(_snow_tex[i], Vector2(xx, yy), col)
		draw_texture(_snow_tex[i], Vector2(xx, yy - H), col)


## 小动物低频事件：首尾各 ~18% 时长淡入淡出，绝不抢画面。
func _draw_wildlife() -> void:
	if _wild_kind == "" or not _wild_tex.has(_wild_kind):
		return
	var tex: Texture2D = _wild_tex[_wild_kind]
	var prog: float = clampf(_wild_t / _wild_dur, 0.0, 1.0)
	var fade: float = clampf(minf(_wild_t, _wild_dur - _wild_t) / maxf(0.18 * _wild_dur, 0.15), 0.0, 1.0)
	var pos := _wild_from.lerp(_wild_to, prog)
	match _wild_kind:
		"bird":
			pos.y += sin(prog * TAU * 2.0) * 4.0  # 滑翔起伏
		"fish":
			pos.y -= sin(PI * prog) * 24.0        # 跃出水面的弧线
		"rabbit":
			pos.y += sin(t * 2.2) * 1.2           # 原地轻动
	var sz := Vector2(tex.get_size()) * _wild_scale
	draw_texture_rect(tex, Rect2(pos - sz * 0.5, sz), false, Color(1, 1, 1, 0.95 * fade))
	if _wild_kind == "fish" and prog > 0.85 and _ripples.size() < 2:
		add_ripple(Vector2(_wild_from.x, bite_point.y + 4.0), 20.0)


## 涟漪：有 Codex 帧动画时按扩散进度播 4 帧；否则回退程序化圆弧。
func _draw_ripples() -> void:
	for r in _ripples:
		var prog: float = clampf(1.0 - r["life"], 0.0, 1.0)
		if not _ripple_tex.is_empty():
			var idx: int = clampi(int(prog * _ripple_tex.size()), 0, _ripple_tex.size() - 1)
			var tex: Texture2D = _ripple_tex[idx]
			var s: float = (0.7 + 0.6 * prog) * (r["max_r"] / 28.0)
			var sz := Vector2(tex.get_size()) * s
			var a: float = clampf(r["life"], 0.0, 1.0) * 0.8
			draw_texture_rect(tex, Rect2(Vector2(r["pos"]) - sz * 0.5, sz), false, Color(1, 1, 1, a))
		else:
			var k: float = clampf(1.0 - r["r"] / r["max_r"], 0.0, 1.0)
			var a2: float = clampf(r["life"], 0.0, 1.0) * 0.5 * k
			if a2 > 0.02:
				draw_arc(r["pos"], r["r"], 0.0, TAU, 26, _a(C_SHIMMER, a2), 1.5)


func _draw_bobber_sprite() -> void:
	var p := bobber_pos()
	var tex := _bobber_bite if (dip > 0.5 and _bobber_bite != null) else _bobber_idle
	if tex == null:
		_draw_bobber_proc(p)
		return
	var sz := Vector2(tex.get_size()) * BOBBER_SCALE
	var off := Vector2(0, sin(t * 2.0) * 1.2 + dip * 5.0)
	draw_texture_rect(tex, Rect2(p - sz * 0.5 + off, sz), false)


## 灯光呼吸：4 帧 ping-pong + 相邻帧交叉淡化，慢速脉动。
func _draw_glow_layer() -> void:
	if _glow_tex.is_empty():
		return
	var n := _glow_tex.size()
	var ph: float = fposmod(t, _glow_period * 2.0) / _glow_period
	var k: float = ph if ph <= 1.0 else 2.0 - ph  # 0→1→0
	var f: float = k * float(n - 1)
	var i0 := int(f)
	var i1: int = mini(i0 + 1, n - 1)
	var frac := f - floorf(f)
	var base_a := 0.55 + 0.28 * sin(t * TAU / _glow_period)  # 0.27 ~ 0.83，呼吸更明显
	var s: float = 1.0 + 0.10 * sin(t * TAU / _glow_period)  # 光晕随呼吸轻微胀缩
	var sz := Vector2(_glow_tex[0].get_size()) * s
	var rect := Rect2(_lantern - sz * 0.5, sz)
	draw_texture_rect(_glow_tex[i0], rect, false, Color(1, 1, 1, base_a * (1.0 - frac)))
	if i1 != i0:
		draw_texture_rect(_glow_tex[i1], rect, false, Color(1, 1, 1, base_a * frac))


func _draw_bobber_proc(p: Vector2) -> void:
	var rr := 5.0 + sin(t * 2.0) * 1.0
	draw_arc(p + Vector2(0, 2), rr, 0.0, TAU, 18, _a(C_SHIMMER, 0.25), 1.0)
	draw_circle(p, 3.2, Color(0.86, 0.42, 0.34))
	draw_circle(p + Vector2(0, -3), 2.0, Color(0.96, 0.96, 0.93))


# ============================ 程序化回退场景 ============================

func _draw_procedural() -> void:
	_draw_glow_proc()
	_draw_mountains()
	_draw_treeline()
	_draw_water()
	_draw_shimmer_proc()
	_draw_ripples()
	_draw_bank()
	_draw_angler()
	_draw_bobber_proc(bobber_pos())


func _draw_glow_proc() -> void:
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


func _draw_shimmer_proc() -> void:
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
