extends Node2D
class_name CornerFishing
## 角落垂钓 · 主控
## 职责：透明角落窗形态 + 挂机钓鱼状态机 + 经济 + 即时反馈（后续接存档/离线/面板）。

@onready var painter: Node2D = $ScenePainter
@onready var ui_root: Control = $HUD/Root
@onready var coins_label: Label = $HUD/Root/Coins
@onready var toast_label: Label = $HUD/Root/Toast

# 窗口比美术画布(520x400)更大，多出的空间透明、留给弹出面板自由展开；
# 场景靠 SCENE_OFF 偏移钉在窗口右下角（视觉上仍是角落小挂件）。
const WIN := Vector2i(1040, 720)
const ART := Vector2(520, 400)
const SCENE_OFF := Vector2(520, 320)  # = WIN - ART，场景绘制/按钮/落水点统一加此偏移

# 可交互区（美术画布坐标，绘制时加 SCENE_OFF）：右下角可见场景 + 按钮；其余透明区穿透。
const INTERACT_RECT := Rect2(160, 148, 360, 252)

# 羽化遮罩参数（art 空间中心 + 屏幕像素半径/core），shader 与鼠标穿透多边形共用。
# 注意：Windows 的 window_set_mouse_passthrough 用 SetWindowRgn 会把窗口裁到该多边形，
# 所以空闲时的穿透区必须贴合羽化椭圆边界（alpha≈0 处），否则会把场景裁成硬矩形。
const FEATHER_CENTER := Vector2(478, 388)   # art 空间，绘制时 + SCENE_OFF
const FEATHER_RADII := Vector2(560, 460)
const FEATHER_CORE := 0.20

# —— UI 布局契约 ——
# 主图烤入按钮/落水点的坐标随 Codex 美术版本漂移。优先从 ui_layout.json 读取
# （Codex 更新美术时同步改 json 即可，不用动代码）；无 json 时用下面实测的回退值。
# json 格式：{"buttons": {"catch": [x,y]}, "bite_point": [x,y]}
# 升级（鱼竿/鱼饵/鱼钩）与设置都已并入鱼篓面板页签，主界面只留一个「鱼篓」按钮。
const UI_LAYOUT_PATHS := ["res://ui_layout.json", "res://assets/art/ui/ui_layout.json"]
var btn_centers := {
	"catch": Vector2(452, 371),
}

# —— 钓鱼状态机 ——
enum {ST_WAIT, ST_BITE}
var _state := ST_WAIT
var _state_t := 0.0
var _started := false

# —— 存档数据 ——
var coins := 0
var rod_level := 1
var bag_level := 1
var bait_level := 0  # FishData.BAITS 下标，金币永久升级
var hook_level := 0  # FishData.HOOKS 下标，决定双钩几率
var inventory: Array = []  # 每条 {"id", "w", "v", "q"(星级)}，一条鱼占一格
var display: Array = []     # 陈列架上的鱼（离开鱼篓、永久展示），最多 Decor.NUM_SLOTS 件
var lifetime_coins := 0    # 累计卖鱼所得
var lifetime_catches := 0
var dex := {}  # id -> {"n": 累计捕获数, "w": 最大体重纪录}（图鉴纪录轴）
var best_quality := 0      # 历史最高星级（成就用）
var best_variant := 0      # 历史最高稀有变体（成就用：斑斓/鎏金/七彩）
var caught_giant := false  # 是否钓到过「巨物」（成就用）
var achievements_done := {}  # id -> true，已达成的成就（toast 只触发一次）

# 背包容量与扩容费用（bag_level 1 起步；费用 = 升到下一级）。
# 调研定标：起始 20 格（Melvor 同款），整档 +5 格，费用走 1-2-5 阶梯（首扩几分钟产出可买）。
const BAG_CAPS := [20, 25, 30, 35, 40, 45, 50, 55]
const BAG_COSTS := [100, 250, 600, 1500, 4000, 10000, 25000]

var save_enabled := true
var rng := RandomNumberGenerator.new()
var _font: SystemFont
var _serif: Font               # Noto Serif SC —— 标题/钓点名/英雄数字的衬线展示声音
var _serif_num: FontVariation  # 同字体 + 等宽数字
var _msg_id := 0
var _panel: Control = null
var _panel_kind := ""
var _detail_fish := ""       # 当前「鱼种详情卡」显示的鱼 id
var _opacity := 1.0
var focus_mode := false          # 专注/安静模式：停小动物事件 + 抑制飘字 + 轻微变暗
var seen_intro := false          # 是否看过首次引导
var order_chip: Button = null   # HUD 上的每日订单进度小字（可点开订单页）
var spot_chip: Button = null    # HUD 上的当前钓点·事件小字（可点开钓点页）

# 存档路径用变量：测试可改用独立文件，避免覆盖真实存档。
var save_path := "user://corner_fishing_save.json"
const OFFLINE_CAP := 8.0 * 3600.0     # 离线最多结算 8 小时
const OFFLINE_EFFICIENCY := 0.5       # 离线效率 50%
const OVERFLOW_SELL_RATE := 0.5       # 满篓兜底：自动折价兑换比例（调研 3.2，避免满篓硬截断惩罚挂机）
var _save_t := 10.0
var _pending_offline := ""               # 仅"满篓没钓到"等无渔获情况用 toast
var _offline_report := {}                # 离线小结：{dur,count,full,value,top,notable[]}

# —— 窗口拖动（默认右下角，可拖到任意位置）——
var _dragging := false
var _drag_grab := Vector2i.ZERO
var _saved_win_pos = null   # Variant：Vector2i 或 null（无存档位置则用右下角默认）
var _panel_dragging := false
var _panel_drag_offset := Vector2.ZERO
var _panel_saved_pos = null  # Variant：Vector2 或 null，记住弹出面板被拖到的位置

# —— 流动鱼贩（动森 CJ 模式）：随机出现的限时收购，卖价 ×1.5 ——
const MERCHANT_MULT := 1.5
const MERCHANT_DUR := Vector2(60.0, 90.0)        # 停留时长区间(秒)
const MERCHANT_GAP := Vector2(1200.0, 2400.0)    # 两次出现间隔(秒)
const MERCHANT_FIRST := Vector2(180.0, 360.0)    # 首次出现(秒)，让玩家较快见到一次
var _merchant_active := false
var _merchant_t := 0.0                            # 当前阶段剩余秒数

# —— 随机事件（EventData 驱动）：同一时刻最多一个 buff 在场，instant 一次结算。低干扰。——
# 钓点决定可触发的事件池（SpotData.event_pool）；事件效果叠加 wait/value/luck 到结算。
const EVENT_FIRST := Vector2(180.0, 420.0)         # 首个事件出现窗口（让玩家较快见到一次）
var current_spot := SpotData.DEFAULT_SPOT          # 当前钓点
var unlocked_spots: Array = [SpotData.DEFAULT_SPOT]  # 已解锁钓点 id
var seen_spots: Array = [SpotData.DEFAULT_SPOT]      # 已造访过的钓点 id（首访提示用）
var _unlocks_inited := false                       # 载入期静默解锁，运行期才弹解锁提示
var active_event := ""                             # 当前在场的 buff 事件 id（"" = 无）
var _event_buff_t := 0.0                           # 当前 buff 剩余时长
var _event_next_t := 0.0                           # 距下一次事件的倒计时
var day_phase := Weather.DEFAULT_PHASE             # 昼夜时段（由真实时钟派生，零存档）

# —— 每日订单：每天 1 单，交付指定鱼种，按原价 ×2.5 结算 ——
const DAILY_ORDER_MULT := 2.5
var daily_order := {}  # {"date": yyyy-mm-dd, "fish": id, "need": int, "done": bool}

# —— 周目标：滚动 7 天大挑战（累计渔获或卖鱼达标领大奖），日常之上的长期层 ——
var weekly := {}  # {week:int, kind:"catches"/"coins", target, base, reward, done}
var day_stat := {}  # {date, catches, coins} 当日起点快照，用于"今日渔获/收入"

# —— 专注奖励（Task 5）：窗口失焦 + 无操作 = 你在别处忙，累计连续专注时长；
# 达 25/50 分钟阈值 → 下一竿强制升级（保底高星 / 保底鎏金变体），给"一直开着"一个正向理由。
# 与手动「专注/安静模式」(focus_mode) 是两回事：那是少打扰开关，这是离开时的惊喜渔获。
const FOCUS_T1 := 25.0 * 60.0          # 25 分钟 → 保底极品★★
const FOCUS_T2 := 50.0 * 60.0          # 50 分钟 → 再保底鎏金变体
const FOCUS_REWARD_DAILY_CAP := 4      # 每日封顶，防刷
var _window_focused := true            # 窗口是否聚焦（FOCUS_IN/OUT 通知维护）
var _focus_away_t := 0.0               # 当前连续失焦累计秒（切回/操作即清零）
var _focus_t1_done := false            # 本段是否已发 25 分钟奖励
var _focus_t2_done := false            # 本段是否已发 50 分钟奖励
var focus_pending := 0                 # 待兑奖励等级（0 无 / 1 高星 / 2 鎏金），下一竿消费
var focus_minutes_total := 0.0         # 累计专注分钟（成就/统计）
var focus_reward_today := 0            # 今日已发奖励次数（封顶）
var focus_reward_date := ""            # 今日封顶计数对应日期
var _idle_t := 0.0                     # 距上次操作的秒数（渔夫打盹 / 专注无操作判定）

# —— 桌面宠物（Task 4）：渔夫旁的小馋猫，上鱼时偶尔扒拉，小概率叼走最廉价的一条当趣味事件 ——
const PET_STEAL_CHANCE := 0.02         # 每次上鱼的偷鱼概率
const PET_STEAL_MAX_VALUE := 30        # 只偷便宜杂鱼（卖价 ≤ 此值），珍藏绝不动
var pet_steals := 0                    # 被叼走的鱼计数（成就/趣味）

const TANK_TAB := 6                    # 鱼篓面板「鱼缸」页签下标（names 第 7 项）


func _ready() -> void:
	rng.randomize()
	Engine.max_fps = 30  # 挂件省电
	get_tree().set_auto_accept_quit(false)  # 退出前存档
	_setup_theme()
	painter.position = SCENE_OFF
	if painter.material is ShaderMaterial:
		var fmat := painter.material as ShaderMaterial
		fmat.set_shader_parameter("center", FEATHER_CENTER + SCENE_OFF)
		# 深色桌面上明亮内容（如湖泊晨雾）在羽化边界会显出"硬切"。
		# 用很长的渐变（core 低、半径大）让所有底图都柔和淡入桌面，跨钓点观感一致。
		fmat.set_shader_parameter("radii", FEATHER_RADII)
		fmat.set_shader_parameter("core", FEATHER_CORE)
	# HUD 贴住可见场景的左上角（窗口放大后，美术左侧被羽化淡掉，故 x 偏移到可见区起点）
	coins_label.position = SCENE_OFF + Vector2(196, 150)
	# 点金币栏 = 打开多功能面板(默认背包页)。主界面不再放独立按钮，入口全收进 HUD
	# （金币栏 / 钓点签 / 订单签）。金币栏落在羽化椭圆穿透区内，故可点且不穿透到桌面（见 _update_passthrough）。
	coins_label.mouse_filter = Control.MOUSE_FILTER_STOP
	coins_label.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_catch_tab = 0
			_toggle_panel("catch"))
	# 钓点签 126 / 金币 150 / 订单 174 三行栈占到 ~192；toast 落到 204 清开订单行
	toast_label.position = SCENE_OFF + Vector2(198, 204)
	toast_label.size = Vector2(440, 28)
	_build_spot_chip()
	_build_order_chip()
	_apply_hud_legibility()
	_setup_window()
	_load_ui_layout()
	_load_save()
	_refresh_unlocks()  # 载入期静默补登已满足解锁的钓点
	_ensure_daily_order()
	_ensure_weekly()
	_build_buttons()
	_apply_spot_visuals()
	day_phase = Weather.current_phase()
	if painter.has_method("set_phase_tint"):
		painter.set_phase_tint(Weather.tint(day_phase))
	_merchant_t = rng.randf_range(MERCHANT_FIRST.x, MERCHANT_FIRST.y)
	if active_event == "":  # 存档可能恢复了在场事件，则不重排首个事件
		_event_next_t = rng.randf_range(EVENT_FIRST.x, EVENT_FIRST.y)
	_update_hud()
	_begin_wait()
	_unlocks_inited = true
	_started = true
	Audio.start_ambience()
	if not seen_intro and lifetime_catches == 0 and DisplayServer.get_name() != "headless":
		_open_panel("intro")  # 全新玩家首启引导（无头测试不弹）
	elif not _offline_report.is_empty():
		_open_panel("offline")
	elif _pending_offline != "":
		_toast(_pending_offline, 4.5, Color(0.55, 0.85, 0.55))
		_pending_offline = ""


# ============================ 窗体形态 ============================

func _setup_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var w := get_window()
	w.transparent_bg = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
	w.borderless = true
	w.always_on_top = true
	await get_tree().process_frame
	if _saved_win_pos != null and _pos_on_screen(_saved_win_pos):
		DisplayServer.window_set_position(_clamp_win_to_screen(_saved_win_pos))
	else:
		_place_corner()  # 无存档位置 / 存档位置离屏(换了显示器等) → 回到右下角
	_update_passthrough()


# 探针取可见场景内一点（窗口右下角附近），判断挂件是否落在某块屏幕可见区内。
func _pos_on_screen(pos: Vector2i) -> bool:
	var ws := DisplayServer.window_get_size()
	var probe := pos + Vector2i(int(ws.x) - 40, int(ws.y) - 40)
	for i in DisplayServer.get_screen_count():
		if DisplayServer.screen_get_usable_rect(i).has_point(probe):
			return true
	return false


# 把窗口位置钳到所在屏可见区：透明左/上边可溢出，但保证右下角可见场景不被切到屏外。
func _clamp_win_to_screen(pos: Vector2i) -> Vector2i:
	var ws := DisplayServer.window_get_size()
	var probe := pos + Vector2i(int(ws.x) - 40, int(ws.y) - 40)
	for i in DisplayServer.get_screen_count():
		var r := DisplayServer.screen_get_usable_rect(i)
		if r.has_point(probe):
			return Vector2i(
				clampi(pos.x, r.position.x - int(SCENE_OFF.x), r.position.x + r.size.x - ws.x),
				clampi(pos.y, r.position.y - int(SCENE_OFF.y), r.position.y + r.size.y - ws.y))
	return pos


func _place_corner() -> void:
	var scr := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(scr)
	var ws := DisplayServer.window_get_size()
	DisplayServer.window_set_position(Vector2i(
		usable.position.x + usable.size.x - ws.x,
		usable.position.y + usable.size.y - ws.y))
	_saved_win_pos = null


func _update_passthrough() -> void:
	# 穿透区贴合羽化椭圆（略大于 alpha=0 边界），裁剪发生在场景已透明处 → 不再硬切；
	# 椭圆外（左上透明区）照常穿透到桌面。点超出窗口时钳到窗口边（右下角=屏幕角，实心收边）。
	var c := FEATHER_CENTER + SCENE_OFF
	var radii := FEATHER_RADII * 1.04
	var pts := PackedVector2Array()
	var n := 48
	for i in n:
		var a := TAU * float(i) / float(n)
		var p := c + Vector2(cos(a), sin(a)) * radii
		pts.append(Vector2(clampf(p.x, 0.0, float(WIN.x)), clampf(p.y, 0.0, float(WIN.y))))
	DisplayServer.window_set_mouse_passthrough(pts)


# 任意操作刷新"无操作"计时；点击/按键还会清掉当前这段专注（你回来动手了）。
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		if event.is_pressed():
			_idle_t = 0.0
			_reset_focus_streak()
	elif event is InputEventMouseMotion:
		_idle_t = 0.0


# 拖动窗口：在场景空白处按住左键拖拽（按钮/面板会先消费事件，不会误触发）。
func _unhandled_input(event: InputEvent) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_grab = DisplayServer.mouse_get_position() - DisplayServer.window_get_position()
		elif _dragging:
			_dragging = false
			_save()
	elif event is InputEventMouseMotion and _dragging:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - _drag_grab)


# ============================ 钓鱼循环 ============================

func _process(delta: float) -> void:
	if not _started:
		return
	if save_enabled:
		_save_t -= delta
		if _save_t <= 0.0:
			_save_t = 10.0
			_save()
	_tick_merchant(delta)
	_tick_events(delta)
	_tick_phase()
	_tick_focus(delta)
	_state_t -= delta
	match _state:
		ST_WAIT:
			painter.dip = lerpf(painter.dip, 0.0, delta * 6.0)
			if _state_t <= 0.0 and not _bag_full():
				_begin_bite()
		ST_BITE:
			painter.dip = lerpf(painter.dip, 1.0, delta * 10.0)
			if _state_t <= 0.0:
				_do_catch()


func _begin_wait() -> void:
	_state = ST_WAIT
	var w := rng.randf_range(3.5, 7.0) * maxf(0.4, 1.0 - float(rod_level - 1) * 0.06)
	w *= SpotData.wait_mult(current_spot)          # 钓点常驻系数（阶段④起生效）
	w *= Weather.wait_mult(day_phase)              # 昼夜时段（金色时段咬钩更勤）
	if active_event != "":
		w *= EventData.wait_mult(active_event)      # 事件期间咬钩节奏变化
	_state_t = w
	Audio.play_sfx("cast")
	get_tree().create_timer(0.45).timeout.connect(func() -> void: Audio.play_sfx("bobber_splash"))


## 昼夜时段：每帧轻量比对真实时钟，跨段才刷新（一天仅 4 次，开销可忽略）。
func _tick_phase() -> void:
	var p := Weather.current_phase()
	if p != day_phase:
		day_phase = p
		_apply_phase()


## 应用当前时段：场景染色 + HUD + 按新节奏重排（不打断已在咬钩）。
func _apply_phase() -> void:
	if painter.has_method("set_phase_tint"):
		painter.set_phase_tint(Weather.tint(day_phase))
	_update_hud()


func _begin_bite() -> void:
	_state = ST_BITE
	_state_t = 0.9
	painter.add_ripple(painter.bobber_pos(), 22.0)
	Audio.play_sfx("bite")


## 更新图鉴纪录（捕获数 +1、最大体重取大、巨物/完美徽章）。返回是否打破"既有"纪录：
## 该鱼种此前已钓 ≥5 条且新体重超过旧纪录才算（避免前期每条都播报）。
func _dex_record(id: String, w: float, is_big := false, is_perfect := false, variant := 0) -> bool:
	var vbit := (1 << variant) if variant > 0 else 0  # 记录见过的稀有变体（位掩码）
	if not dex.has(id):
		dex[id] = {"n": 1, "w": w, "big": is_big, "perf": is_perfect, "vmask": vbit,
			"fd": _today_key()}  # v11：首次捕获日期（水族箱纪录卡）
		return false
	var r: Dictionary = dex[id]
	var broke: bool = int(r["n"]) >= 5 and w > float(r["w"])
	r["n"] = int(r["n"]) + 1
	r["w"] = maxf(float(r["w"]), w)
	if is_big:
		r["big"] = true
	if is_perfect:
		r["perf"] = true
	r["vmask"] = int(r.get("vmask", 0)) | vbit
	return broke


func _bag_capacity() -> int:
	return BAG_CAPS[clampi(bag_level - 1, 0, BAG_CAPS.size() - 1)]


func _bag_full() -> bool:
	return inventory.size() >= _bag_capacity()


## 钓点：薄壳委托 Spots（实现见 spots.gd，行为不变）。
func _spot_pool() -> Array:
	return Spots.pool(self)


func _catch_luck() -> int:
	return Spots.catch_luck(self)


func _catch_value_mult() -> float:
	return Spots.catch_value_mult(self)


## 钓一条鱼：限定当前钓点鱼池，应用钓点/事件增值系数。
func _roll_one(luck: int) -> Dictionary:
	var c := FishData.roll_catch(rng, rod_level, bait_level, luck, _spot_pool())
	var vm := _catch_value_mult()
	if vm != 1.0:
		c["v"] = max(1, int(round(float(c["v"]) * vm)))
	return c


func _do_catch() -> void:
	if _bag_full():
		_overflow_catch()   # 满篓不空转：钓一条折价兑成金币，挂机永不停产
		_begin_wait()
		return
	var luck := _catch_luck()
	var c := _roll_one(luck)
	var focus_up := _apply_focus_reward(c)   # 专注奖励：把这一竿强制升级（保底高星/鎏金）
	var tier := FishData.tier_of(c["id"])
	var q := int(c.get("q", 0))
	var vr := int(c.get("var", 0))
	var fname := FishData.variant_label(vr) + FishData.quality_label(q) + FishData.size_tag(c["id"], c["w"]) \
		+ FishData.display_name(c["id"])
	inventory.append(c)
	lifetime_catches += 1
	best_quality = maxi(best_quality, q)
	best_variant = maxi(best_variant, vr)
	var is_big := FishData.size_tag(c["id"], c["w"]) == "巨物·"
	if is_big:
		caught_giant = true
	var broke_record := _dex_record(c["id"], float(c["w"]), is_big, q >= 3, vr)
	var col: Color = FishData.TIER_COLORS[tier]
	Audio.play_sfx("catch_rare" if (tier >= 2 or q >= 2 or vr >= 1) else "catch_common")
	_popup("%s %.2fkg" % [fname, c["w"]], painter.position + painter.bobber_pos() + Vector2(-22, -8),
		FishData.variant_color(vr) if vr >= 1 else col)
	painter.add_ripple(painter.bobber_pos(), 34.0)
	if vr >= 1:
		_toast("✨ 变体！%s%s（%.2fkg，%d 金币）" % [FishData.variant_label(vr),
			FishData.display_name(c["id"]), c["w"], c["v"]], 2.8, FishData.variant_color(vr))
	elif broke_record:
		_toast("破纪录！%s %.2fkg，刷新个人最大" % [FishData.display_name(c["id"]), c["w"]],
			2.6, Color(0.95, 0.82, 0.45))
	elif tier >= 3 or q >= 2:
		_toast("%s钓到 %s（%.2fkg，%d 金币）" % [
			(FishData.TIER_NAMES[tier] + "！") if tier >= 3 else "",
			fname, c["w"], c["v"]], 2.4, col)
	elif not bool(daily_order.get("done", false)) and _order_matches(c):
		var need := int(daily_order.get("need", 1))
		var have := mini(_daily_order_indices().size(), need)
		_toast("订单进度：%s %d/%d" % [_order_short(), have, need],
			2.0, Color(0.96, 0.78, 0.38))
	if tier >= 4 or q >= 3 or vr >= 2:
		_flash()
	# 渔夫性格：钓到高星/七彩，举手欢呼一下（Task 4）
	if (q >= 2 or vr >= 3) and painter.has_method("fisher_cheer"):
		painter.fisher_cheer()
	# 鱼钩双钩：一定几率再上一条（受背包剩余格数限制）
	if hook_level > 0 and not _bag_full() \
			and rng.randf() < float(FishData.HOOKS[hook_level]["double"]):
		var c2 := _roll_one(luck)
		inventory.append(c2)
		lifetime_catches += 1
		best_quality = maxi(best_quality, int(c2.get("q", 0)))
		best_variant = maxi(best_variant, int(c2.get("var", 0)))
		var ib2 := FishData.size_tag(c2["id"], c2["w"]) == "巨物·"
		if ib2:
			caught_giant = true
		_dex_record(c2["id"], float(c2["w"]), ib2, int(c2.get("q", 0)) >= 3, int(c2.get("var", 0)))
		_popup("双钩 +%s" % FishData.display_name(c2["id"]),
			painter.position + painter.bobber_pos() + Vector2(24, -22), Color(0.62, 0.86, 0.74))
		Audio.play_sfx("catch_common")
	if _bag_full():
		_toast("鱼篓满了，先去卖鱼或扩容～", 3.0, Color(1.0, 0.75, 0.4))
	_maybe_pet_steal()   # 桌面宠物：小概率叼走最廉价的一条（Task 4）
	if painter.has_method("pet_react") and not focus_mode and rng.randf() < 0.3:
		painter.pet_react("paw")  # 上鱼时偶尔扒拉一下鱼篓
	_check_achievements()
	_update_hud()
	_refresh_panel()
	if focus_up > 0:  # 专注奖励到手：用最醒目的 toast 收尾（最后调用者覆盖前面的飘字）
		var rname := FishData.variant_label(int(c.get("var", 0))) + FishData.quality_label(int(c.get("q", 0))) \
			+ FishData.display_name(str(c["id"]))
		_toast("🎁 专注奖励到手：%s（%.2fkg，%d 金币）" % [rname, float(c["w"]), int(c["v"])],
			4.0, Color(0.74, 0.86, 0.98))
	_begin_wait()


## 满篓兜底（调研 3.2「把痛点变成卖点」）：鱼篓满时把新鱼 c 与篓中最低价的
## 「可兑换鱼」（未上锁、非当前订单目标）比较，留下更值钱的那条，另一条按
## OVERFLOW_SELL_RATE 折价自动兑成金币。返回兜底金币（不改 coins/lifetime，调用方累计）。
## 篓里若全是收藏锁/订单鱼（无可兑换）则直接折价兑掉新鱼，绝不动玩家珍藏。
func _absorb_overflow(c: Dictionary) -> int:
	var worst_idx := -1
	var worst_v := 0
	for i in inventory.size():
		var f: Dictionary = inventory[i]
		if bool(f.get("lock", false)) or _order_matches(f):
			continue
		var fv := _sell_value(f)
		if worst_idx == -1 or fv < worst_v:
			worst_idx = i
			worst_v = fv
	var sold := c
	if worst_idx >= 0 and _sell_value(c) > worst_v:
		sold = inventory[worst_idx]   # 新鱼更值钱 → 收进篓，兑掉篓中最低价那条
		inventory[worst_idx] = c
	return maxi(1, int(ceil(_sell_value(sold) * OVERFLOW_SELL_RATE)))


## 满篓在线钓鱼：照常计入图鉴/累计（挂机仍推进收集），渔获经 _absorb_overflow 折价入金。
## 低干扰：只在浮标处给一个小飘字 + 涟漪，不发 toast、不响金币音，避免满篓久挂时刷屏吵闹。
func _overflow_catch() -> void:
	var luck := _catch_luck()
	var c := _roll_one(luck)
	lifetime_catches += 1
	var q := int(c.get("q", 0))
	var vr := int(c.get("var", 0))
	best_quality = maxi(best_quality, q)
	best_variant = maxi(best_variant, vr)
	var is_big := FishData.size_tag(c["id"], c["w"]) == "巨物·"
	if is_big:
		caught_giant = true
	_dex_record(c["id"], float(c["w"]), is_big, q >= 3, vr)
	var gain := _absorb_overflow(c)
	coins += gain
	lifetime_coins += gain
	painter.add_ripple(painter.bobber_pos(), 28.0)
	_popup("满篓兑 +%d" % gain, painter.position + painter.bobber_pos() + Vector2(-22, -8),
		Color(0.85, 0.72, 0.42))
	_check_achievements()
	_update_hud()
	_refresh_panel()


# ============================ 反馈 / HUD ============================

func _setup_theme() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "SimHei", "Noto Sans CJK SC"])
	# 衬线展示字体（设计令牌 --font-display）：标题与英雄数字用，呼应水彩卷轴气质。
	_serif = load("res://assets/fonts/NotoSerifSC-Bold.woff2")
	if _serif == null:
		_serif = _font  # 字体缺失时优雅回退系统字体，绝不崩
	_serif_num = FontVariation.new()
	_serif_num.base_font = _serif
	_serif_num.opentype_features = {"tnum": 1, "lnum": 1}  # 等宽数字（字体支持时）
	var th := Theme.new()
	th.default_font = _font
	th.default_font_size = 15
	ui_root.theme = th


func _update_hud() -> void:
	_ensure_day_stat()  # 跨天即时重置当日统计
	var bag := "鱼篓 %d/%d" % [inventory.size(), _bag_capacity()]
	if _bag_full():
		bag += "（满）"
	var mer := "　收鱼郎×1.5" if _merchant_active else ""
	var evt := ""
	if active_event != "" and EventData.hud_text(active_event) != "":
		evt = "　" + EventData.hud_text(active_event)
	coins_label.text = "金币 %d　%s%s%s" % [coins, bag, mer, evt]
	var col := Color(0.92, 0.92, 0.9)
	if active_event != "":
		col = EventData.color(active_event)
	elif _merchant_active:
		col = Color(0.98, 0.82, 0.40)
	elif _bag_full():
		col = Color(1.0, 0.78, 0.45)
	coins_label.add_theme_color_override("font_color", col)
	_refresh_unlocks()
	_update_spot_chip()
	_update_order_chip()


## HUD 当前钓点·事件小字（金币行上方，点开钓点页）。
func _build_spot_chip() -> void:
	spot_chip = Button.new()
	spot_chip.flat = true
	spot_chip.focus_mode = Control.FOCUS_NONE
	spot_chip.position = SCENE_OFF + Vector2(196, 126)
	spot_chip.add_theme_font_size_override("font_size", 14)
	spot_chip.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	spot_chip.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	spot_chip.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	spot_chip.add_theme_color_override("font_hover_color", Color(0.98, 0.90, 0.62))
	spot_chip.pressed.connect(func() -> void:
		Audio.play_ui("ui_click")
		_catch_tab = 5
		_open_panel("catch"))
	ui_root.add_child(spot_chip)


func _update_spot_chip() -> void:
	if spot_chip == null:
		return
	var txt := SpotData.display_name(current_spot) + " · " + Weather.display_name(day_phase)
	var col := Color(0.86, 0.86, 0.82)
	if active_event != "" and EventData.hud_text(active_event) != "":
		txt += " · " + EventData.display_name(active_event)
		col = EventData.color(active_event)
	spot_chip.text = txt
	spot_chip.add_theme_color_override("font_color", col)


## HUD 订单进度小字（低调、可点开订单页）。Stardew/AC 式每日目标常驻可见。
func _build_order_chip() -> void:
	order_chip = Button.new()
	order_chip.flat = true
	order_chip.focus_mode = Control.FOCUS_NONE
	order_chip.position = SCENE_OFF + Vector2(196, 174)
	order_chip.add_theme_font_size_override("font_size", 13)
	order_chip.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	order_chip.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	order_chip.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	order_chip.add_theme_color_override("font_hover_color", Color(0.98, 0.90, 0.62))
	order_chip.pressed.connect(func() -> void:
		Audio.play_ui("ui_click")
		_catch_tab = 2
		_open_panel("catch"))
	ui_root.add_child(order_chip)


func _update_order_chip() -> void:
	if order_chip == null:
		return
	_ensure_daily_order()
	if bool(daily_order.get("done", false)):
		order_chip.text = "今日订单 ✓ 已完成"
		order_chip.add_theme_color_override("font_color", Color(0.55, 0.78, 0.50))
		return
	var need := int(daily_order.get("need", 1))
	var have := mini(_daily_order_indices().size(), need)
	order_chip.text = "订单  %s  %d/%d" % [_order_short(), have, need]
	order_chip.add_theme_color_override("font_color",
		Color(0.95, 0.85, 0.5) if have >= need else Color(0.80, 0.73, 0.55))


## 面板开着时数据变了（上鱼/卖鱼/扩容），原地重建内容。
## 例外：鱼缸页签开着时不因后台上鱼而重建——否则游动的鱼每几秒被重置。
## 放入/捞出鱼等主动操作走 _rebuild_panel() 强制重建。
func _refresh_panel() -> void:
	if _panel_kind == "":
		return
	if _panel_kind == "catch" and _catch_tab == TANK_TAB:
		return
	_open_panel(_panel_kind)


# 常驻 HUD 文字（金币行 / 钓点签 / 订单签）叠在水彩背景上，原先只设字色、
# 在湖泊/海岸等中明度底图上糊成一团。统一加暖墨描边 + 柔和投影把字「托」起来，
# 比飘字更强一档保证一眼可读，但仍是暖墨非纯黑，不破坏水彩的安静气质。
func _apply_hud_legibility() -> void:
	for node: Control in [coins_label, spot_chip, order_chip]:
		if node == null:
			continue
		node.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.07, 0.82))
		node.add_theme_constant_override("outline_size", 5)
		node.add_theme_color_override("font_shadow_color", Color(0.06, 0.05, 0.04, 0.5))
		node.add_theme_constant_override("shadow_offset_x", 1)
		node.add_theme_constant_override("shadow_offset_y", 2)
		node.add_theme_constant_override("shadow_outline_size", 3)


# 把工程化的高饱和色调柔化为水彩气质：降饱和 + 提亮 + 轻混奶油色。
# 飘字/toast 统一过这道滤镜，整体色调与柔和场景一致。
func _soft(c: Color) -> Color:
	var s: float = c.s * 0.62
	var val: float = clampf(c.v * 0.95 + 0.08, 0.0, 1.0)
	var out := Color.from_hsv(c.h, s, val, 1.0)
	return out.lerp(Color(0.96, 0.92, 0.83), 0.14)


func _popup(text: String, pos: Vector2, color: Color) -> void:
	if focus_mode:
		return  # 专注模式下不弹频繁飘字
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", _soft(color))
	# 飘字固定出现在浮漂处（水彩最密的右下角），描边/投影需与 HUD 同档才一眼可读
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.09, 0.07, 0.82))
	l.add_theme_constant_override("outline_size", 5)
	l.add_theme_color_override("font_shadow_color", Color(0.06, 0.05, 0.04, 0.5))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.position = pos
	l.z_index = 20
	ui_root.add_child(l)
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", pos.y - 30.0, 1.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tw.tween_callback(l.queue_free)


func _toast(text: String, duration: float, color := Color.WHITE) -> void:
	_msg_id += 1
	var id := _msg_id
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", _soft(color))
	toast_label.add_theme_color_override("font_outline_color", Color(0.16, 0.13, 0.10, 0.40))
	toast_label.add_theme_constant_override("outline_size", 4)
	toast_label.modulate.a = 1.0
	toast_label.visible = true
	await get_tree().create_timer(duration).timeout
	if _msg_id == id and is_instance_valid(toast_label):
		toast_label.visible = false


func _flash() -> void:
	var fr := ColorRect.new()
	fr.color = Color(1.0, 0.85, 0.3, 0.0)
	fr.anchor_right = 1.0
	fr.anchor_bottom = 1.0
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(fr)
	var tw := create_tween()
	tw.tween_property(fr, "color:a", 0.32, 0.12)
	tw.tween_property(fr, "color:a", 0.0, 0.8)
	tw.tween_callback(fr.queue_free)


# ============================ 按钮 / 面板 ============================

var _spot_round_btns: Array = []   # 干净 spot 上显示的真实圆按钮（river 隐藏，用底图烤死的+命中区）


func _build_buttons() -> void:
	if painter.use_composite:
		# 所有钓场都是干净底图，统一用独立图标按钮（不再有底图烤死按钮 + 命中区的特例）
		_build_spot_buttons()
		_update_spot_buttons()
	else:
		_build_round_buttons()


# 干净 spot 底图没有烤死的按钮，这里补一组图标按钮，直接复用 Codex 的独立图标
# （ui_button_fish/rod/coin），与 river 底图烤死的那三个图标一模一样，跨钓点观感一致。
# river 用底图自带按钮 + 透明命中区，这组隐藏；切钓点时在 Spots.apply_visuals 里切显隐。
const SPOT_BTN_ICONS := {
	"catch": "res://assets/art/ui/ui_button_fish.png",
	"rod": "res://assets/art/ui/ui_button_rod.png",
	"set": "res://assets/art/ui/ui_button_coin.png",
}

func _build_spot_buttons() -> void:
	for k in []:   # 入口已全收进金币栏(点金币开面板)，主界面不再放独立按钮（撤鱼篓按钮）
		var b := TextureButton.new()
		b.texture_normal = load(SPOT_BTN_ICONS[k])
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(30, 30)
		b.size = Vector2(30, 30)
		b.focus_mode = Control.FOCUS_NONE
		b.position = (btn_centers[k] as Vector2) + SCENE_OFF - Vector2(15, 15)
		b.visible = false
		b.mouse_entered.connect(func() -> void: b.modulate = Color(1.18, 1.14, 1.0))
		b.mouse_exited.connect(func() -> void: b.modulate = Color.WHITE)
		b.pressed.connect(func() -> void: Audio.play_ui("ui_click"))
		b.pressed.connect(_toggle_panel.bind(k))
		ui_root.add_child(b)
		_spot_round_btns.append(b)


func _update_spot_buttons() -> void:
	var clean: bool = painter.has_method("uses_clean_bg") and painter.uses_clean_bg()
	for b in _spot_round_btns:
		if is_instance_valid(b):
			b.visible = clean


## 读取 ui_layout.json（若 Codex 提供），覆盖按钮中心与落水点。
func _load_ui_layout() -> void:
	for path in UI_LAYOUT_PATHS:
		if not FileAccess.file_exists(path):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (data is Dictionary):
			continue
		var btns: Variant = data.get("buttons", {})
		if btns is Dictionary:
			for k in btn_centers.keys():
				var v: Variant = btns.get(k, btns.get("settings" if k == "set" else k, null))
				if v is Array and v.size() >= 2:
					btn_centers[k] = Vector2(float(v[0]), float(v[1]))
		var bp: Variant = data.get("bite_point", null)
		if bp is Array and bp.size() >= 2:
			painter.bite_point = Vector2(float(bp[0]), float(bp[1]))
		return


# 程序化回退模式：纸色圆按钮（只剩篓；升级/设置都并入鱼篓面板页签）。
func _build_round_buttons() -> void:
	var defs := []   # 入口已收进金币栏，主界面无独立圆按钮（程序化回退模式同步）
	var x := 436.0
	for d in defs:
		var b := _round_button(d[0])
		b.position = Vector2(x, 362) + SCENE_OFF
		b.pressed.connect(_toggle_panel.bind(d[1]))
		ui_root.add_child(b)
		x += 38.0


func _round_button(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(32, 32)
	b.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.94, 0.88, 0.92)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.5, 0.5, 0.45, 0.5)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = Color(1.0, 0.98, 0.92, 0.98)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_color_override("font_color", Color(0.3, 0.3, 0.28))
	return b


func _toggle_panel(kind: String) -> void:
	Audio.play_ui("ui_click")
	if _panel_kind == kind:
		_close_panel()
	else:
		_open_panel(kind)


var _catch_tab := 0  # 0=鱼篓 1=图鉴 2=订单 3=成就
var _bag_sort := 0   # 0=最新 1=价值 2=品阶 3=重量
var _bag_filter_order := false  # 只看订单目标鱼
const BAG_SORT_NAMES := ["最新", "价值", "品阶", "重量"]


## 鱼图标：只加载已通过美术验收的专属图；未批准/缺失时回退到同品阶旧风格图标。
var _tier_icon_cache := {}
const APPROVED_FISH_ICON_IDS := {
	"whitebait": true,
	"topmouth": true,
	"loach": true,
	"crucian": true,
	"bighead": true,
	"yellowhead": true,
	"dace": true,
	"carp": true,
	"grass": true,
	"bream": true,
	"blackcarp": true,
	"bass": true,
	"fangbream": true,
	"barbel": true,
	"culter": true,
	"mandarin": true,
	"snakehead": true,
	"trout": true,
	"pike": true,
	"zander": true,
	"longsnout": true,
	"lenok": true,
	"koi": true,
	"salmon": true,
	"sturgeon": true,
	"taimen": true,
	"chinese_sturgeon": true,
	"kaluga": true,
}
const GENERIC_FISH_ICON_BY_TIER := [
	"whitebait",
	"carp",
	"bass",
	"snakehead",
	"koi",
	"chinese_sturgeon",
]
func _fish_icon(id: String, size := 42) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(size, size)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture = _fish_texture(id)
	return tr


## 取鱼的贴图（未批准或专属图缺失则回退品阶通用图），供水族箱等需要裸 Texture2D 的地方复用。
func _fish_texture(id: String) -> Texture2D:
	if APPROVED_FISH_ICON_IDS.has(id):
		var path := "res://assets/art/fish/%s.png" % id
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return _generic_fish_texture(FishData.tier_of(id))


## 按品阶的通用鱼图标：使用旧有已批准水彩图标，最后才生成中性占位，按品阶缓存。
func _generic_fish_texture(tier: int) -> Texture2D:
	tier = clampi(tier, 0, FishData.TIER_COLORS.size() - 1)
	if _tier_icon_cache.has(tier):
		return _tier_icon_cache[tier]
	var approved_id := str(GENERIC_FISH_ICON_BY_TIER[tier])
	var asset := "res://assets/art/fish/%s.png" % approved_id
	var tex: Texture2D
	if ResourceLoader.exists(asset):
		tex = load(asset) as Texture2D
	else:
		tex = _make_generic_fish(Color(0.55, 0.53, 0.46))
	_tier_icon_cache[tier] = tex
	return tex


## 程序化小鱼剪影（品阶色 + 柔边 + 鱼尾 + 眼点），水彩淡墨气质，作缺图回退。
func _make_generic_fish(col: Color) -> ImageTexture:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := s * 0.52
	var cy := s * 0.5
	var rx := s * 0.30
	var ry := s * 0.19
	for y in s:
		for x in s:
			var a := 0.0
			# 鱼身：椭圆，向边缘柔化
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			var d := dx * dx + dy * dy
			if d <= 1.0:
				a = clampf(0.9 - d * 0.45, 0.4, 0.9)
			# 鱼尾：左侧三角
			var tx := cx - rx * 0.78
			if x <= tx and x >= tx - s * 0.16:
				var span := (tx - x) / (s * 0.16)
				if absf(y - cy) <= span * s * 0.16:
					a = maxf(a, 0.75)
			if a > 0.0:
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	# 眼点
	var ex := int(cx + rx * 0.45)
	var ey := int(cy - ry * 0.25)
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var px := ex + ox
			var py := ey + oy
			if px >= 0 and px < s and py >= 0 and py < s:
				img.set_pixel(px, py, Color(0.12, 0.11, 0.10, 0.85))
	return ImageTexture.create_from_image(img)


func _tier_color(tier: int) -> Color:
	return FishData.TIER_COLORS[clampi(tier, 0, FishData.TIER_COLORS.size() - 1)]


func _ui_tier_color(tier: int, on_paper := false) -> Color:
	if tier == 0:
		return Color(0.38, 0.37, 0.33) if on_paper else Color(0.86, 0.84, 0.78)
	return _tier_color(tier)


## —— 面板：薄壳委托 UIPanels（实现见 ui_panels.gd，行为不变）——
func _open_panel(kind: String) -> void:
	UIPanels.open_panel(self, kind)


func _close_panel() -> void:
	UIPanels.close_panel(self)


func _open_fish_detail(id: String) -> void:
	_detail_fish = id
	_open_panel("fishdetail")


func _set_catch_tab(tab: int) -> void:
	_catch_tab = tab
	_open_panel("catch")


# ============================ 每日订单 ============================

## 订单/周目标/今日统计：薄壳委托 Orders（实现见 orders.gd，行为不变）。
func _today_key() -> String:
	return Orders.today_key()


func _ensure_day_stat() -> void:
	Orders.ensure_day_stat(self)


func _today_catches() -> int:
	return Orders.today_catches(self)


func _today_income() -> int:
	return Orders.today_income(self)


func _ensure_daily_order() -> void:
	Orders.ensure_daily_order(self)


func _make_daily_order(date_key: String) -> Dictionary:
	return Orders.make_daily_order(self, date_key)


func _rep_fish_of_tier(t: int, local: RandomNumberGenerator, pool: Array = []) -> String:
	return Orders.rep_fish_of_tier(t, local, pool)


func _order_matches(c: Dictionary) -> bool:
	return Orders.order_matches(self, c)


func _order_title() -> String:
	return Orders.order_title(self)


func _order_short() -> String:
	return Orders.order_short(self)


func _is_daily_order_target(id: String) -> bool:
	return Orders.is_daily_order_target(self, id)


func _daily_order_indices() -> Array:
	return Orders.daily_order_indices(self)


func _daily_order_reward(indices: Array) -> int:
	return Orders.daily_order_reward(self, indices)


func _try_complete_daily_order() -> void:
	Orders.try_complete_daily_order(self)


func _week_id() -> int:
	return Orders.week_id()


func _ensure_weekly() -> void:
	Orders.ensure_weekly(self)


func _make_weekly(wk: int) -> Dictionary:
	return Orders.make_weekly(self, wk)


func _weekly_progress() -> int:
	return Orders.weekly_progress(self)


func _weekly_desc() -> String:
	return Orders.weekly_desc(self)


func _try_claim_weekly() -> void:
	Orders.try_claim_weekly(self)



## 按当前排序返回背包显示用的真实索引序列。filter_order=true 时只保留符合当前订单的鱼
## （按 _order_matches，兼容指定鱼种/品阶/大物/完美各类订单，而非仅图标代表鱼）。
func _sorted_bag_indices(filter_order: bool) -> Array:
	var idxs: Array = []
	for i in inventory.size():
		if filter_order and not _order_matches(inventory[i]):
			continue
		idxs.append(i)
	match _bag_sort:
		1:  # 价值降序
			idxs.sort_custom(func(a, b): return _sell_value(inventory[a]) > _sell_value(inventory[b]))
		2:  # 品阶降序，同阶按价值
			idxs.sort_custom(func(a, b):
				var ta := FishData.tier_of(str(inventory[a]["id"]))
				var tb := FishData.tier_of(str(inventory[b]["id"]))
				if ta != tb:
					return ta > tb
				return _sell_value(inventory[a]) > _sell_value(inventory[b]))
		3:  # 重量降序
			idxs.sort_custom(func(a, b): return float(inventory[a]["w"]) > float(inventory[b]["w"]))
		_:  # 最新（后进先出）
			idxs.reverse()
	return idxs


func _toggle_lock(idx: int) -> void:
	if idx < 0 or idx >= inventory.size():
		return
	var c: Dictionary = inventory[idx]
	c["lock"] = not bool(c.get("lock", false))
	_refresh_panel()
	_save()


# 流动鱼贩在场时卖价 ×1.5（向上取整）。
# 音频薄壳：供早解析的全局类（如 Decor）经 g 调用，避开它们直接引用 Audio 自动加载。
func _play_sfx(n: String) -> void:
	Audio.play_sfx(n)


func _play_ui(n: String) -> void:
	Audio.play_ui(n)


func _sell_value(c: Dictionary) -> int:
	var v := float(c["v"]) * (1.0 + Decor.value_bonus(self))  # 陈列加成（封顶 +5%）
	if _merchant_active:
		v *= MERCHANT_MULT
	return int(ceil(v))


func _sell_one(idx: int) -> void:
	if idx < 0 or idx >= inventory.size():
		return
	if bool(inventory[idx].get("lock", false)):
		_toast("这条鱼已上锁收藏", 1.5, Color(0.95, 0.78, 0.42))
		return
	var c: Dictionary = inventory[idx]
	inventory.remove_at(idx)
	var v := _sell_value(c)
	coins += v
	lifetime_coins += v
	Audio.play_sfx("coin")
	_toast("卖出 %s +%d%s" % [FishData.display_name(c["id"]), v,
		"（鱼贩×1.5）" if _merchant_active else ""], 1.5, Color(0.85, 0.7, 0.35))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_save()


func _sell_all() -> void:
	var total := 0
	var n := 0
	var keep: Array = []
	for c in inventory:
		if bool(c.get("lock", false)):
			keep.append(c)       # 收藏锁：跳过锁定的鱼
		else:
			total += _sell_value(c)
			n += 1
	if n == 0:
		return
	inventory = keep
	coins += total
	lifetime_coins += total
	Audio.play_sfx("coin")
	var msg := "卖出 %d 条鱼 +%d 金币%s" % [n, total, "（鱼贩×1.5）" if _merchant_active else ""]
	if not keep.is_empty():
		msg += "（%d 条收藏留着）" % keep.size()
	_toast(msg, 2.2, Color(0.85, 0.7, 0.35))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_save()


## 卖杂鱼：卖出未上锁且非当前订单目标的鱼，保留订单进度与收藏。
func _sell_junk() -> void:
	var total := 0
	var n := 0
	var keep: Array = []
	for c in inventory:
		if bool(c.get("lock", false)) or _order_matches(c):
			keep.append(c)
		else:
			total += _sell_value(c)
			n += 1
	if n == 0:
		return
	inventory = keep
	coins += total
	lifetime_coins += total
	Audio.play_sfx("coin")
	_toast("卖出杂鱼 %d 条 +%d 金币（订单鱼与收藏保留）" % [n, total], 2.2, Color(0.85, 0.7, 0.35))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_save()


# ============================ 流动鱼贩 ============================

func _tick_merchant(delta: float) -> void:
	_merchant_t -= delta
	if _merchant_t > 0.0:
		return
	if _merchant_active:
		_merchant_active = false
		_merchant_t = rng.randf_range(MERCHANT_GAP.x, MERCHANT_GAP.y)
		_toast("收鱼郎走了，下次再来～", 2.4, Color(0.7, 0.66, 0.58))
	else:
		_merchant_active = true
		_merchant_t = rng.randf_range(MERCHANT_DUR.x, MERCHANT_DUR.y)
		_toast("收鱼郎来了！限时收购，全部卖价 ×1.5", 3.5, Color(0.98, 0.82, 0.40))
	_update_hud()
	_refresh_panel()


# ============================ 随机事件（EventData 驱动）============================

## 随机事件：薄壳委托 Events（实现见 events.gd，行为不变）。
func _eligible_events() -> Array:
	return Events.eligible(self)


func _tick_events(delta: float) -> void:
	Events.tick(self, delta)


func _fire_event(forced := "") -> void:
	Events.fire(self, forced)


# ============================ 多钓点 ============================

## 钓点控制：薄壳委托 Spots（实现见 spots.gd，行为不变）。
func _refresh_unlocks() -> void:
	Spots.refresh_unlocks(self)


func _switch_spot(id: String) -> void:
	Spots.switch_to(self, id)


func _apply_spot_visuals() -> void:
	Spots.apply_visuals(self)
	_update_spot_buttons()


func _order_pool() -> Array:
	return Spots.order_pool(self)


func _best_spot_for(fish_id: String) -> String:
	return Spots.best_spot_for(self, fish_id)


func _try_expand_bag() -> void:
	if bag_level > BAG_COSTS.size():
		return
	var cost: int = BAG_COSTS[bag_level - 1]
	if coins < cost:
		Audio.play_ui("ui_error")
		_toast("金币不足", 1.5, Color(1.0, 0.5, 0.4))
		return
	coins -= cost
	bag_level += 1
	Audio.play_sfx("upgrade")
	_toast("鱼篓扩到 %d 格！" % _bag_capacity(), 2.2, Color(0.5, 0.8, 1.0))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_save()


# ============================ 成就 ============================

## 判定单条成就是否达成（对照当前状态）。
func _ach_done(a: Dictionary) -> bool:
	match str(a["kind"]):
		"catches": return lifetime_catches >= int(a["n"])
		"coins": return lifetime_coins >= int(a["n"])
		"species": return dex.size() >= int(a["n"])
		"species_all": return dex.size() >= FishData.FISH.size()
		"tier": return _best_tier_caught() >= int(a["n"])
		"giant": return caught_giant
		"quality": return best_quality >= int(a["n"])
		"bag": return bag_level >= int(a["n"])
		"rod": return rod_level >= int(a["n"])
		"bait": return bait_level >= int(a["n"])
		"hook": return hook_level >= int(a["n"])
		"maxweight": return _dex_max_weight() >= float(a["n"])
		"display": return display.size() >= int(a["n"])
		"variant": return best_variant >= int(a["n"])
		"focus_minutes": return focus_minutes_total >= float(a["n"])
		"pet_steals": return pet_steals >= int(a["n"])
	return false


## 图鉴里记录到的最大单条体重（用于重量里程碑成就）。
func _dex_max_weight() -> float:
	var m := 0.0
	for id in dex:
		m = maxf(m, float(dex[id]["w"]))
	return m


func _best_tier_caught() -> int:
	var best := -1
	for id in dex:
		best = maxi(best, FishData.tier_of(str(id)))
	return best


## 扫描所有未达成成就，新达成的发 toast + 发奖励。
## silent=true 用于载入老存档时静默补登已满足的成就（不发 toast / 不补发奖励）。
func _check_achievements(silent := false) -> void:
	for a in AchievementData.LIST:
		var id: String = a["id"]
		if achievements_done.has(id):
			continue
		if _ach_done(a):
			achievements_done[id] = true
			if silent:
				continue
			var reward := int(a.get("reward", 0))
			if reward > 0:
				coins += reward
			var msg := "成就达成：%s" % a["name"]
			if reward > 0:
				msg += "（+%d 金币）" % reward
			_toast(msg, 3.0, Color(0.98, 0.85, 0.45))


func _rod_cost() -> int:
	# 陡成本曲线：让鱼竿成为真正的长期金币去向（旧 40×1.8^n 几乎零成本）。
	# 成本增速(2.0/级) 高于产出增速(~1.25/级)，回本时间随等级递增、后期形成自然墙。
	return int(round(200.0 * pow(2.0, rod_level - 1)))


func _try_upgrade_rod() -> void:
	var cost := _rod_cost()
	if coins < cost:
		Audio.play_ui("ui_error")
		_toast("金币不足", 1.5, Color(1.0, 0.5, 0.4))
		return
	coins -= cost
	rod_level += 1
	Audio.play_sfx("upgrade")
	_check_achievements()
	_update_hud()
	_toast("鱼竿升到 Lv.%d！" % rod_level, 2.0, Color(0.5, 0.8, 1.0))
	_refresh_panel()   # 升级页已是鱼篓面板「装备」页签，原地刷新即可


func _try_upgrade_bait() -> void:
	if bait_level >= FishData.BAITS.size() - 1:
		return
	var nxt: Dictionary = FishData.BAITS[bait_level + 1]
	var cost := int(nxt["cost"])
	if coins < cost:
		Audio.play_ui("ui_error")
		_toast("金币不足", 1.5, Color(1.0, 0.5, 0.4))
		return
	coins -= cost
	bait_level += 1
	Audio.play_sfx("upgrade")
	_check_achievements()
	_update_hud()
	_toast("换上了%s，星级渔获概率提升！" % nxt["name"], 2.4, Color(0.6, 0.85, 0.5))
	_save()
	_refresh_panel()   # 升级页已是鱼篓面板「装备」页签，原地刷新即可


func _try_upgrade_hook() -> void:
	if hook_level >= FishData.HOOKS.size() - 1:
		return
	var nxt: Dictionary = FishData.HOOKS[hook_level + 1]
	var cost := int(nxt["cost"])
	if coins < cost:
		Audio.play_ui("ui_error")
		_toast("金币不足", 1.5, Color(1.0, 0.5, 0.4))
		return
	coins -= cost
	hook_level += 1
	Audio.play_sfx("upgrade")
	_check_achievements()
	_update_hud()
	_toast("换上了%s，双钩几率提升！" % nxt["name"], 2.4, Color(0.6, 0.85, 0.5))
	_save()
	_refresh_panel()   # 升级页已是鱼篓面板「装备」页签，原地刷新即可


func _set_opacity(val: float) -> void:
	_opacity = val
	painter.modulate.a = val
	coins_label.modulate.a = val


## 专注/安静模式：停小动物事件 + 抑制飘字（_popup 已守卫）+ 场景轻微变暗。
func _set_focus(on: bool) -> void:
	focus_mode = on
	if painter.has_method("set_quiet"):
		painter.set_quiet(on)
	_set_opacity(_opacity)  # 重新应用，叠加 focus 暗化
	if on:
		painter.modulate.a = _opacity * 0.8


# ============================ 专注奖励（Task 5）============================

## 每帧推进专注/无操作计时；失焦累计连续专注，达阈值发奖励；并同步渔夫情绪上下文。
func _tick_focus(delta: float) -> void:
	if _window_focused:
		_idle_t += delta            # 看着它发呆 → 渔夫会打盹
	else:
		_focus_away_t += delta      # 你在别处忙 → 累计专注
		focus_minutes_total += delta / 60.0
		_check_focus_thresholds()
	_update_fisher_context()


## 跨越 25/50 分钟阈值则发奖励（每段每档只发一次，且受每日封顶约束）。
func _check_focus_thresholds() -> void:
	_ensure_focus_day()
	if focus_reward_today >= FOCUS_REWARD_DAILY_CAP:
		return
	if not _focus_t1_done and _focus_away_t >= FOCUS_T1:
		_focus_t1_done = true
		_grant_focus_reward(1)
	if not _focus_t2_done and _focus_away_t >= FOCUS_T2 and focus_reward_today < FOCUS_REWARD_DAILY_CAP:
		_focus_t2_done = true
		_grant_focus_reward(2)


func _grant_focus_reward(level: int) -> void:
	focus_pending = maxi(focus_pending, level)
	focus_reward_today += 1
	var mins := 25 if level == 1 else 50
	_toast("专注 %d 分钟，下一竿留了份惊喜给你 ✨" % mins, 4.0, Color(0.74, 0.86, 0.98))
	_check_achievements()
	_save()


## 当前若有待兑专注奖励，就把这一竿强制升级（保底高星 / 50 分钟再保底鎏金）。返回消费的等级。
func _apply_focus_reward(c: Dictionary) -> int:
	if focus_pending <= 0:
		return 0
	var level := focus_pending
	focus_pending = 0
	var old_q := int(c.get("q", 0))
	var old_v := int(c.get("var", 0))
	var new_q := maxi(old_q, 2)                       # 保底极品★★
	var new_var := maxi(old_v, 2) if level >= 2 else old_v  # 50 分钟再保底鎏金
	var mult: float = FishData.QUALITY_MULTS[new_q] / FishData.QUALITY_MULTS[old_q] \
		* FishData.VARIANT_MULTS[new_var] / FishData.VARIANT_MULTS[old_v]
	c["q"] = new_q
	c["var"] = new_var
	c["v"] = maxi(1, int(round(float(c["v"]) * mult)))
	_save()
	return level


func _ensure_focus_day() -> void:
	var today := _today_key()
	if focus_reward_date != today:
		focus_reward_date = today
		focus_reward_today = 0


## 切回窗口 / 主动操作 → 当前这段专注清零（不清待兑奖励：已挣到的留着下一竿兑）。
func _reset_focus_streak() -> void:
	_focus_away_t = 0.0
	_focus_t1_done = false
	_focus_t2_done = false


## 把昼夜/久未操作等上下文喂给绘制层，驱动渔夫情绪动画（Task 4）。
func _update_fisher_context() -> void:
	if painter.has_method("set_fisher_context"):
		painter.set_fisher_context(day_phase == "night", _idle_t > 45.0 and _window_focused)


# ============================ 桌面宠物（Task 4）============================

## 上鱼后的趣味事件：小概率让宠物叼走鱼。安静模式不打扰；
## 测试/截图实例（save_enabled=false）不触发随机偷鱼，避免污染钓鱼数量断言。
func _maybe_pet_steal() -> void:
	if focus_mode or not save_enabled:
		return
	if rng.randf() >= PET_STEAL_CHANCE:
		return
	var id := _pet_steal_cheapest()
	if id != "" and painter.has_method("pet_react"):
		painter.pet_react("steal")


## 叼走鱼篓里最廉价且「可舍弃」（未上锁、非订单目标、卖价 ≤ 上限）的一条。返回鱼 id（没合适的返回 ""）。
func _pet_steal_cheapest() -> String:
	var worst := -1
	var worst_v := 0
	for i in inventory.size():
		var f: Dictionary = inventory[i]
		if bool(f.get("lock", false)) or _order_matches(f):
			continue
		var fv := _sell_value(f)
		if worst == -1 or fv < worst_v:
			worst = i
			worst_v = fv
	if worst < 0 or worst_v > PET_STEAL_MAX_VALUE:
		return ""   # 没有可舍弃的廉价鱼 → 绝不动珍藏
	var c: Dictionary = inventory[worst]
	inventory.remove_at(worst)
	pet_steals += 1
	_toast("🐱 小馋猫叼走了一条%s当点心～" % FishData.display_name(str(c["id"])), 2.6, Color(0.95, 0.80, 0.5))
	_check_achievements()
	_update_hud()
	_rebuild_panel()
	_save()
	return str(c["id"])


## 从鱼篓/图鉴把鱼放进水族箱后用：强制重建面板（含会游动的水族箱视图）。
func _rebuild_panel() -> void:
	if _panel_kind != "":
		_open_panel(_panel_kind)


# ============================ 存档 / 离线 ============================

func _save() -> void:
	if not save_enabled:
		return
	_ensure_daily_order()
	SaveSystem.write_atomic(save_path, SaveSystem.collect(self))


func _load_save() -> void:
	if not save_enabled:
		return
	# 主档解析失败（截断/损坏）时回退到 .bak，最大限度保住进度
	var data: Variant = SaveSystem.read_file(save_path)
	if data == null:
		data = SaveSystem.read_file(save_path + ".bak")
		if data != null:
			push_warning("主存档损坏，已从 .bak 恢复")
	if not (data is Dictionary):
		return
	SaveSystem.apply(self, data)
	# 老存档（v4 及更早，无 ach 字段）静默补登已满足的成就，避免回屏刷屏
	if not (data.get("ach", null) is Array):
		_check_achievements(true)
	# 离线渔获：按时长估算上鱼数，逐条入篓直到装满
	var elapsed: float = Time.get_unix_time_from_system() - float(data.get("ts", 0))
	elapsed = clampf(elapsed, 0.0, OFFLINE_CAP)
	if elapsed > 30.0:
		var caught := _offline_catch(elapsed)
		if caught > 0:
			_offline_report["dur"] = _fmt_dur(elapsed)
			_offline_report["full"] = _bag_full()
		elif _bag_full():
			_pending_offline = "离线 %s，鱼篓是满的，一条都装不下啦" % _fmt_dur(elapsed)


## 离线钓鱼：上鱼数 = 时长/平均间隔×效率。鱼篓装满后不再截断（调研 3.2），
## 多出的鱼经 _absorb_overflow 折价兑成金币兜底——挂一夜回来一定有收益。
## 汇总成 _offline_report 供回屏小结展示。返回本次产生收益的总条数（入篓 + 兜底）。
func _offline_catch(elapsed: float) -> int:
	var wait_factor: float = maxf(0.4, 1.0 - float(rod_level - 1) * 0.06)
	var avg_interval := 5.25 * wait_factor + 0.9
	var est := int(elapsed / avg_interval * OFFLINE_EFFICIENCY)
	if est <= 0:
		return 0
	var cap := _bag_capacity()
	var stored := mini(est, maxi(0, cap - inventory.size()))  # 先填满空格
	var overflow := est - stored                              # 其余折价兜底
	var total_v := 0
	var top: Dictionary = {}
	var notable: Array = []
	# —— 入篓部分（正常展示）——
	for i in stored:
		var c := _roll_one(0)  # 离线也按当前钓点鱼池 + 钓点增值，含稀有变体
		inventory.append(c)
		var ib := FishData.size_tag(c["id"], c["w"]) == "巨物·"
		_dex_record(c["id"], float(c["w"]), ib, int(c.get("q", 0)) >= 3, int(c.get("var", 0)))
		lifetime_catches += 1
		best_quality = maxi(best_quality, int(c.get("q", 0)))
		best_variant = maxi(best_variant, int(c.get("var", 0)))
		if ib:
			caught_giant = true
		total_v += int(c["v"])
		if top.is_empty() or int(c["v"]) > int(top["v"]):
			top = c
		if FishData.tier_of(c["id"]) >= 3 or int(c.get("q", 0)) >= 2 or int(c.get("var", 0)) >= 1:
			notable.append(c)
	# —— 满篓兜底部分（折价兑金；稀有仍会被换进篓、踢出最廉价那条）——
	var overflow_v := 0
	for i in overflow:
		var c := _roll_one(0)
		var ib := FishData.size_tag(c["id"], c["w"]) == "巨物·"
		_dex_record(c["id"], float(c["w"]), ib, int(c.get("q", 0)) >= 3, int(c.get("var", 0)))
		lifetime_catches += 1
		best_quality = maxi(best_quality, int(c.get("q", 0)))
		best_variant = maxi(best_variant, int(c.get("var", 0)))
		if ib:
			caught_giant = true
		overflow_v += _absorb_overflow(c)
	coins += overflow_v
	lifetime_coins += overflow_v
	_offline_report["overflow_n"] = overflow
	_offline_report["overflow_v"] = overflow_v
	if stored > 0 or overflow > 0:
		_offline_report["count"] = stored          # 入篓条数（满篓溢出走 overflow_n/v）
		_offline_report["value"] = total_v
		_offline_report["top"] = top
		_offline_report["notable"] = notable
	return stored + overflow


func _fmt_dur(sec: float) -> String:
	var h := int(sec) / 3600
	var m := (int(sec) % 3600) / 60
	if h > 0:
		return "%d 小时 %d 分" % [h, m]
	return "%d 分钟" % max(1, m)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_save()
			get_tree().quit()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			_window_focused = false   # 你切去别的程序 → 开始累计专注
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			_window_focused = true    # 切回挂件 → 当前这段专注清零
			_reset_focus_streak()
			_idle_t = 0.0


func _quit_game() -> void:
	_save()
	get_tree().quit()
