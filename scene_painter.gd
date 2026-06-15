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
var _spot_base: Texture2D = null   # 当前钓点底图（缺图回退到 _base，不崩）
var _fisher: Texture2D             # 独立渔夫精灵（含鱼竿），叠加到所有干净底图上
var _lantern_tex: Texture2D        # 独立灯笼精灵，叠加到所有干净底图上

# 统一叠加层锚点（art 空间）。所有钓场底图都是纯风景，渔夫/灯笼/钓线/浮漂都由代码叠加。
const FISHER_SCALE := 0.30   # 渔夫精灵原 192px → ~58px，坐右岸
var fisher_anchor := Vector2(430, 300)   # 渔夫脚底中心
var fisher_flip := false
const LANTERN_SCALE := 0.34  # 灯笼精灵原 96px → ~33px，立在渔夫旁
var lantern_anchor := Vector2(462, 286)  # 灯笼底部中心（渔夫右侧岸上）
var rod_tip_off := Vector2(-22, -50)     # 竿尖相对 fisher_anchor 的偏移（钓线起点）
var phase_tint := Color(0, 0, 0, 0)  # 昼夜时段染色（A=0 不染色），main 经 set_phase_tint 设置
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

# —— 渔夫情绪 / 桌面宠物（Task 4）：尽量零存档、瞬态，用变换驱动 ——
var _fisher_pull: Array = []        # 收竿/上鱼姿势帧（咬钩时切换，给渔夫加动作）
var fisher_mood := "idle"           # idle / cheer / yawn / shiver / doze
var _mood_t := 0.0                  # 当前非 idle 情绪剩余时长
var _mood_dur := 1.0
var _mood_gap := 10.0               # 距下一次环境小情绪
var ctx_night := false              # 由 main 喂入：夜间时段
var ctx_idle := false              # 由 main 喂入：久未操作
var pet_anchor := Vector2(410, 305) # 小馋猫坐处（脚底中心，渔夫左前的雪岸上）
var pet_action := ""                # "" idle / paw / steal
var _pet_action_t := 0.0
var _pet_action_dur := 1.0
var _pet_blink_t := 3.0


func _ready() -> void:
	_prng.randomize()
	# 默认/回退底图用干净河湾（不再用烤死渔夫的旧图）；正常情况 set_spot 会按钓点覆盖
	_base = _tex("res://assets/art/background/spot_river_bend.png")
	_water_overlay = _tex("res://assets/art/background/water_highlight_overlay.png")
	_bobber_idle = _tex("res://assets/art/props/bobber_idle.png")
	_bobber_bite = _tex("res://assets/art/props/bobber_bite.png")
	_fisher = _tex("res://assets/art/character/fisher_idle.png")
	_fisher_pull = _frames("res://assets/art/character/fisher_pull_%02d.png", 2)
	_lantern_tex = _tex("res://assets/art/props/lantern.png")
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
	# 灯笼为独立叠加精灵，光晕锚点取灯笼火焰处（不再从底图扫描暖色像素）
	_lantern = lantern_anchor + Vector2(0, -16)


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
		_tick_fisher(delta)
		_tick_pet(delta)
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


## 切换钓点底图：加载 assets/art/background/spot_<bg_key>.png；缺图回退现有主图（不崩）。
func set_spot(bg_key: String) -> void:
	if bg_key == "":
		_spot_base = null
	else:
		_spot_base = _tex("res://assets/art/background/spot_%s.png" % bg_key)
	queue_redraw()


## 当前是否用干净 spot 底图（渔夫/按钮需由代码补上）；river 回退 _base 时为 false。
func uses_clean_bg() -> bool:
	return _spot_base != null


## 渔夫情绪状态机（Task 4）：cheer/yawn/shiver/doze 为瞬态小情绪，零存档。
## cheer 由 main 在高星/七彩上鱼时触发；其余按 main 喂入的夜间/久坐上下文低频自发。
func _tick_fisher(delta: float) -> void:
	if _mood_t > 0.0:
		_mood_t -= delta
		if _mood_t <= 0.0:
			fisher_mood = "idle"
		return
	_mood_gap -= delta
	if _mood_gap <= 0.0:
		_mood_gap = _prng.randf_range(14.0, 26.0)
		_start_ambient_mood()


func _start_ambient_mood() -> void:
	if quiet:
		return  # 安静模式不主动演小情绪
	var pool := ["shiver"]    # 冬日钓场总有点冷
	if ctx_night:
		pool.append("yawn")
	if ctx_idle:
		pool.append("doze")
		pool.append("doze")   # 久坐更容易打盹
	fisher_mood = pool[_prng.randi() % pool.size()]
	match fisher_mood:
		"shiver": _mood_dur = 1.8
		"yawn": _mood_dur = 2.4
		"doze": _mood_dur = 3.6
		_: _mood_dur = 1.6
	_mood_t = _mood_dur


## main 喂入昼夜 / 久未操作上下文，决定自发小情绪倾向。
func set_fisher_context(night: bool, idle: bool) -> void:
	ctx_night = night
	ctx_idle = idle


## 钓到高星/七彩 → 举手欢呼（一次性，最高优先）。
func fisher_cheer() -> void:
	fisher_mood = "cheer"
	_mood_dur = 1.6
	_mood_t = _mood_dur


## 叠加独立渔夫精灵（脚底中心对齐 fisher_anchor）。咬钩时切收竿姿势；情绪用变换叠加。
func _draw_fisher() -> void:
	if _fisher == null:
		return
	var tex := _fisher
	if dip > 0.5 and not _fisher_pull.is_empty():
		tex = _fisher_pull[int(t * 6.0) % _fisher_pull.size()]  # 咬钩收竿，帧间切换
	var sz := Vector2(tex.get_size()) * FISHER_SCALE
	var off := Vector2.ZERO
	var rot := 0.0
	var sc := Vector2.ONE
	sc.y *= 1.0 + 0.02 * sin(t * 2.0)   # 呼吸
	var p := 0.0
	match fisher_mood:
		"cheer":
			p = 1.0 - _mood_t / _mood_dur
			off.y = -sin(p * PI) * 12.0        # 蹦一下
			sc *= 1.0 + 0.08 * sin(p * PI)
			rot = 0.05 * sin(p * TAU * 2.0)    # 小幅摇摆
		"yawn":
			p = 1.0 - _mood_t / _mood_dur
			var yy := sin(p * PI)
			sc.y *= 1.0 + 0.06 * yy            # 缓慢伸展
			off.y -= 2.0 * yy
			rot = -0.05 * yy                   # 微微后仰
		"shiver":
			off.x = sin(t * 34.0) * 1.4        # 快速发抖
			off.y += 1.0                        # 缩脖
			sc.y *= 0.98
		"doze":
			rot = 0.06 * sin(t * 0.8)          # 一点一点打盹
			off.y += 1.5 * sin(t * 0.8) + 1.0
	var flip := -1.0 if fisher_flip else 1.0
	draw_set_transform(fisher_anchor + off, rot, Vector2(flip * sc.x, sc.y))
	draw_texture_rect(tex, Rect2(Vector2(-sz.x * 0.5, -sz.y), sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ============================ 桌面宠物：小馋猫（Task 4，程序化占位）============================

## 上鱼扒拉 / 偷鱼时由 main 触发，瞬态动作。
func pet_react(kind: String) -> void:
	pet_action = kind
	_pet_action_dur = 0.9 if kind == "paw" else 1.4
	_pet_action_t = _pet_action_dur


func _tick_pet(delta: float) -> void:
	if _pet_action_t > 0.0:
		_pet_action_t -= delta
		if _pet_action_t <= 0.0:
			pet_action = ""
	_pet_blink_t -= delta
	if _pet_blink_t <= 0.0:
		_pet_blink_t = _prng.randf_range(2.6, 6.0)


func _pet_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
	draw_set_transform(center, 0.0, Vector2(rx, ry))
	draw_circle(Vector2.ZERO, 1.0, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 程序化橘猫（坐姿，面朝渔夫/水面）：尾巴轻摆、偶尔眨眼、上鱼/偷鱼时抬爪。
## 美术补图前的占位实现（机制可用）；需要的反应帧见结尾清单。
func _draw_pet() -> void:
	var B := pet_anchor
	var body := Color(0.86, 0.55, 0.28)
	var dark := Color(0.66, 0.40, 0.18)
	var belly := Color(0.96, 0.85, 0.66)
	# 动作进度（抬爪/前倾）
	var lean := 0.0
	var paw_lift := 0.0
	if pet_action != "":
		var pp: float = 1.0 - _pet_action_t / _pet_action_dur
		paw_lift = sin(pp * PI) * 7.0
		if pet_action == "steal":
			lean = sin(pp * PI) * 3.0   # 偷鱼时朝鱼篓前倾
	# 影子
	_pet_ellipse(B + Vector2(1, 1), 12.0, 3.0, Color(0, 0, 0, 0.16))
	# 尾巴（身后，左侧上扬，轻摆）
	var sway := sin(t * 1.6) * 6.0
	var t0 := B + Vector2(-8, -6)
	var t1 := B + Vector2(-14, -14)
	var t2 := B + Vector2(-9 + sway, -24)
	var tail := PackedVector2Array()
	for i in 7:
		var u := float(i) / 6.0
		var a := t0.lerp(t1, u)
		var b := t1.lerp(t2, u)
		tail.append(a.lerp(b, u))
	draw_polyline(tail, dark, 3.4, true)
	# 身体（坐姿臀部 + 前胸）
	_pet_ellipse(B + Vector2(-1 + lean, -9), 9.5, 11.0, body)
	_pet_ellipse(B + Vector2(4 + lean, -9), 6.5, 9.0, body)
	_pet_ellipse(B + Vector2(4 + lean, -6), 3.6, 6.0, belly)
	# 前腿/爪（右爪在动作时抬起扒拉）
	_pet_ellipse(B + Vector2(2 + lean, -3), 2.0, 4.0, body)
	_pet_ellipse(B + Vector2(7 + lean, -3 - paw_lift), 2.0, 4.0, body)
	# 头
	var HC := B + Vector2(7 + lean, -19)
	_pet_ellipse(HC, 6.5, 6.0, body)
	# 耳朵
	draw_colored_polygon(PackedVector2Array([
		HC + Vector2(-5, -4), HC + Vector2(-1, -9), HC + Vector2(0, -3)]), body)
	draw_colored_polygon(PackedVector2Array([
		HC + Vector2(2, -3), HC + Vector2(4, -9), HC + Vector2(6, -3)]), body)
	draw_colored_polygon(PackedVector2Array([
		HC + Vector2(-3, -4), HC + Vector2(-1, -7), HC + Vector2(-0.5, -4)]), dark)
	draw_colored_polygon(PackedVector2Array([
		HC + Vector2(3, -4), HC + Vector2(4, -7), HC + Vector2(5, -4)]), dark)
	# 眼睛（偶尔眨）+ 鼻子
	if _pet_blink_t < 0.14:
		draw_line(HC + Vector2(0, -1), HC + Vector2(2, -1), dark, 1.0)
		draw_line(HC + Vector2(4, -1), HC + Vector2(6, -1), dark, 1.0)
	else:
		draw_circle(HC + Vector2(1, -1), 1.0, dark)
		draw_circle(HC + Vector2(5, -1), 1.0, dark)
	draw_circle(HC + Vector2(3, 1), 0.9, Color(0.5, 0.3, 0.3))


## 叠加独立油灯精灵（底部中心对齐 lantern_anchor）。
func _draw_lantern() -> void:
	if _lantern_tex == null:
		return
	var sz := Vector2(_lantern_tex.get_size()) * LANTERN_SCALE
	var topleft := lantern_anchor - Vector2(sz.x * 0.5, sz.y)
	draw_texture_rect(_lantern_tex, Rect2(topleft, sz), false)


## 钓线：竿尖 → 浮漂，淡白细线（底图不再烤死钓线，统一由此叠加）。
func _draw_fishing_line() -> void:
	var tip := fisher_anchor + rod_tip_off
	draw_line(tip, bobber_pos(), Color(0.95, 0.96, 0.97, 0.55), 1.2, true)


## 昼夜时段染色（main 在跨段时调用；A=0 即白昼不染色）。
func set_phase_tint(c: Color) -> void:
	phase_tint = c
	queue_redraw()


## 时段染色叠层：覆盖整幅场景的淡色，经羽化材质自然向左上渐隐。
func _draw_phase_tint() -> void:
	if phase_tint.a > 0.001:
		draw_rect(Rect2(0.0, 0.0, W, H), phase_tint)


# —— 干净底图 + 统一叠加层（所有钓场同一路径；底图均为纯风景，渔夫/灯笼/钓线/浮漂全代码叠加）——
func _draw_composite() -> void:
	draw_texture(_spot_base if _spot_base != null else _base, Vector2.ZERO)
	_draw_fisher()          # 渔夫（含鱼竿）坐右岸
	_draw_pet()             # 渔夫旁的小馋猫
	_draw_lantern()         # 渔夫旁的油灯
	_draw_fishing_line()    # 竿尖 → 浮漂的钓线
	_draw_mist_layer()
	_draw_shimmer_layer()
	_draw_snow_layer()
	_draw_phase_tint()
	_draw_wildlife()
	_draw_ripples()
	_draw_bobber_sprite()
	_draw_glow_layer()      # 灯光呼吸光晕（锚在灯笼火焰处）


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
