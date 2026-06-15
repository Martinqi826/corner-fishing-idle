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
const WIN := Vector2i(760, 560)
const ART := Vector2(520, 400)
const SCENE_OFF := Vector2(240, 160)  # = WIN - ART，场景绘制/按钮/落水点统一加此偏移

# 可交互区（美术画布坐标，绘制时加 SCENE_OFF）：右下角可见场景 + 按钮；其余透明区穿透。
const INTERACT_RECT := Rect2(160, 148, 360, 252)

# —— UI 布局契约 ——
# 主图烤入按钮/落水点的坐标随 Codex 美术版本漂移。优先从 ui_layout.json 读取
# （Codex 更新美术时同步改 json 即可，不用动代码）；无 json 时用下面实测的回退值。
# json 格式：{"buttons": {"catch": [x,y], "rod": [x,y], "set": [x,y]}, "bite_point": [x,y]}
const UI_LAYOUT_PATHS := ["res://ui_layout.json", "res://assets/art/ui/ui_layout.json"]
var btn_centers := {
	"catch": Vector2(424, 371),
	"rod": Vector2(452, 371),
	"set": Vector2(481, 371),
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
var lifetime_coins := 0    # 累计卖鱼所得
var lifetime_catches := 0
var dex := {}  # id -> {"n": 累计捕获数, "w": 最大体重纪录}（图鉴纪录轴）
var best_quality := 0      # 历史最高星级（成就用）
var caught_giant := false  # 是否钓到过「巨物」（成就用）
var achievements_done := {}  # id -> true，已达成的成就（toast 只触发一次）

# 背包容量与扩容费用（bag_level 1 起步；费用 = 升到下一级）。
# 调研定标：起始 20 格（Melvor 同款），整档 +5 格，费用走 1-2-5 阶梯（首扩几分钟产出可买）。
const BAG_CAPS := [20, 25, 30, 35, 40, 45, 50, 55]
const BAG_COSTS := [100, 250, 600, 1500, 4000, 10000, 25000]

var save_enabled := true
var rng := RandomNumberGenerator.new()
var _font: SystemFont
var _msg_id := 0
var _panel: Control = null
var _panel_kind := ""
var _opacity := 1.0
var focus_mode := false          # 专注/安静模式：停小动物事件 + 抑制飘字 + 轻微变暗
var seen_intro := false          # 是否看过首次引导
var order_chip: Button = null   # HUD 上的每日订单进度小字（可点开订单页）
var spot_chip: Button = null    # HUD 上的当前钓点·事件小字（可点开钓点页）

# 存档路径用变量：测试可改用独立文件，避免覆盖真实存档。
var save_path := "user://corner_fishing_save.json"
const OFFLINE_CAP := 8.0 * 3600.0     # 离线最多结算 8 小时
const OFFLINE_EFFICIENCY := 0.5       # 离线效率 50%
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

# —— 每日订单：每天 1 单，交付指定鱼种，按原价 ×2.5 结算 ——
const DAILY_ORDER_MULT := 2.5
var daily_order := {}  # {"date": yyyy-mm-dd, "fish": id, "need": int, "done": bool}

# —— 周目标：滚动 7 天大挑战（累计渔获或卖鱼达标领大奖），日常之上的长期层 ——
var weekly := {}  # {week:int, kind:"catches"/"coins", target, base, reward, done}
var day_stat := {}  # {date, catches, coins} 当日起点快照，用于"今日渔获/收入"


func _ready() -> void:
	rng.randomize()
	Engine.max_fps = 30  # 挂件省电
	get_tree().set_auto_accept_quit(false)  # 退出前存档
	_setup_theme()
	painter.position = SCENE_OFF
	if painter.material is ShaderMaterial:
		(painter.material as ShaderMaterial).set_shader_parameter("center", Vector2(478, 388) + SCENE_OFF)
	coins_label.position = SCENE_OFF + Vector2(22, 96)
	toast_label.position = SCENE_OFF + Vector2(40, 112)
	toast_label.size = Vector2(440, 28)
	_build_spot_chip()
	_build_order_chip()
	_setup_window()
	_load_ui_layout()
	_load_save()
	_refresh_unlocks()  # 载入期静默补登已满足解锁的钓点
	_ensure_daily_order()
	_ensure_weekly()
	_build_buttons()
	_apply_spot_visuals()
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
	var r := Rect2(INTERACT_RECT.position + SCENE_OFF, INTERACT_RECT.size)
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]))


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
	if active_event != "":
		w *= EventData.wait_mult(active_event)      # 事件期间咬钩节奏变化
	_state_t = w
	Audio.play_sfx("cast")
	get_tree().create_timer(0.45).timeout.connect(func() -> void: Audio.play_sfx("bobber_splash"))


func _begin_bite() -> void:
	_state = ST_BITE
	_state_t = 0.9
	painter.add_ripple(painter.bobber_pos(), 22.0)
	Audio.play_sfx("bite")


## 更新图鉴纪录（捕获数 +1、最大体重取大、巨物/完美徽章）。返回是否打破"既有"纪录：
## 该鱼种此前已钓 ≥5 条且新体重超过旧纪录才算（避免前期每条都播报）。
func _dex_record(id: String, w: float, is_big := false, is_perfect := false) -> bool:
	if not dex.has(id):
		dex[id] = {"n": 1, "w": w, "big": is_big, "perf": is_perfect}
		return false
	var r: Dictionary = dex[id]
	var broke: bool = int(r["n"]) >= 5 and w > float(r["w"])
	r["n"] = int(r["n"]) + 1
	r["w"] = maxf(float(r["w"]), w)
	if is_big:
		r["big"] = true
	if is_perfect:
		r["perf"] = true
	return broke


func _bag_capacity() -> int:
	return BAG_CAPS[clampi(bag_level - 1, 0, BAG_CAPS.size() - 1)]


func _bag_full() -> bool:
	return inventory.size() >= _bag_capacity()


## 当前钓点鱼池（多钓点）：阶段④起 _do_catch / 离线按此池出鱼。
func _spot_pool() -> Array:
	return SpotData.pool_for(current_spot)


## 钓点常驻 + 当前事件 叠加的品阶运气。
func _catch_luck() -> int:
	var l := SpotData.luck_bonus(current_spot)
	if active_event != "":
		l += EventData.luck(active_event)
	return l


## 钓点常驻 × 当前事件 叠加的渔获增值系数。
func _catch_value_mult() -> float:
	var m := SpotData.value_mult(current_spot)
	if active_event != "":
		m *= EventData.value_mult(active_event)
	return m


## 钓一条鱼：限定当前钓点鱼池，应用钓点/事件增值系数。
func _roll_one(luck: int) -> Dictionary:
	var c := FishData.roll_catch(rng, rod_level, bait_level, luck, _spot_pool())
	var vm := _catch_value_mult()
	if vm != 1.0:
		c["v"] = max(1, int(round(float(c["v"]) * vm)))
	return c


func _do_catch() -> void:
	if _bag_full():
		_begin_wait()
		return
	var luck := _catch_luck()
	var c := _roll_one(luck)
	var tier := FishData.tier_of(c["id"])
	var q := int(c.get("q", 0))
	var fname := FishData.quality_label(q) + FishData.size_tag(c["id"], c["w"]) \
		+ FishData.display_name(c["id"])
	inventory.append(c)
	lifetime_catches += 1
	best_quality = maxi(best_quality, q)
	var is_big := FishData.size_tag(c["id"], c["w"]) == "巨物·"
	if is_big:
		caught_giant = true
	var broke_record := _dex_record(c["id"], float(c["w"]), is_big, q >= 3)
	var col: Color = FishData.TIER_COLORS[tier]
	Audio.play_sfx("catch_rare" if (tier >= 2 or q >= 2) else "catch_common")
	_popup("%s %.2fkg" % [fname, c["w"]], painter.position + painter.bobber_pos() + Vector2(-22, -8), col)
	painter.add_ripple(painter.bobber_pos(), 34.0)
	if broke_record:
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
	if tier >= 4 or q >= 3:
		_flash()
	# 鱼钩双钩：一定几率再上一条（受背包剩余格数限制）
	if hook_level > 0 and not _bag_full() \
			and rng.randf() < float(FishData.HOOKS[hook_level]["double"]):
		var c2 := _roll_one(luck)
		inventory.append(c2)
		lifetime_catches += 1
		best_quality = maxi(best_quality, int(c2.get("q", 0)))
		var ib2 := FishData.size_tag(c2["id"], c2["w"]) == "巨物·"
		if ib2:
			caught_giant = true
		_dex_record(c2["id"], float(c2["w"]), ib2, int(c2.get("q", 0)) >= 3)
		_popup("双钩 +%s" % FishData.display_name(c2["id"]),
			painter.position + painter.bobber_pos() + Vector2(24, -22), Color(0.62, 0.86, 0.74))
		Audio.play_sfx("catch_common")
	if _bag_full():
		_toast("鱼篓满了，先去卖鱼或扩容～", 3.0, Color(1.0, 0.75, 0.4))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_begin_wait()


# ============================ 反馈 / HUD ============================

func _setup_theme() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray([
		"Microsoft YaHei UI", "Microsoft YaHei", "SimHei", "Noto Sans CJK SC"])
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
	spot_chip.position = SCENE_OFF + Vector2(22, 72)
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
	var txt := SpotData.display_name(current_spot)
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
	order_chip.position = SCENE_OFF + Vector2(22, 120)
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
func _refresh_panel() -> void:
	if _panel_kind != "":
		var kind := _panel_kind
		_open_panel(kind)


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
	# 柔和的暖墨描边代替生硬纯黑，保证场景上可读又不突兀
	l.add_theme_color_override("font_outline_color", Color(0.16, 0.13, 0.10, 0.42))
	l.add_theme_constant_override("outline_size", 4)
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

func _build_buttons() -> void:
	if painter.use_composite:
		_build_hit_areas()
	else:
		_build_round_buttons()


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


# 合成主图模式：按钮已烤进主图，这里只放透明命中区（带悬停高亮），点击可用、无重影。
func _build_hit_areas() -> void:
	for k in ["catch", "rod", "set"]:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(30, 32)
		b.size = Vector2(30, 32)
		b.position = (btn_centers[k] as Vector2) + SCENE_OFF - Vector2(15, 16)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		var hov := StyleBoxFlat.new()
		hov.bg_color = Color(1, 1, 1, 0.16)
		hov.set_corner_radius_all(15)
		b.add_theme_stylebox_override("hover", hov)
		b.pressed.connect(_toggle_panel.bind(k))
		ui_root.add_child(b)


# 程序化回退模式：纸色圆按钮（篓/竿/设）。
func _build_round_buttons() -> void:
	var defs := [["篓", "catch"], ["竿", "rod"], ["设", "set"]]
	var x := 404.0
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


## 鱼图标：优先专属图；缺失时回退「按品阶通用鱼图标」（Codex 资源或程序化生成），绝不空白/崩。
var _tier_icon_cache := {}
func _fish_icon(id: String, size := 42) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(size, size)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path := "res://assets/art/fish/%s.png" % id
	if ResourceLoader.exists(path):
		tr.texture = load(path) as Texture2D
	else:
		tr.texture = _generic_fish_texture(FishData.tier_of(id))
	return tr


## 按品阶的通用鱼图标：先找 Codex 通用图，缺则程序化生成（品阶色小鱼剪影），按品阶缓存。
func _generic_fish_texture(tier: int) -> Texture2D:
	tier = clampi(tier, 0, FishData.TIER_COLORS.size() - 1)
	if _tier_icon_cache.has(tier):
		return _tier_icon_cache[tier]
	var asset := "res://assets/art/fish/generic_tier%d.png" % tier
	var tex: Texture2D
	if ResourceLoader.exists(asset):
		tex = load(asset) as Texture2D
	else:
		tex = _make_generic_fish(_tier_color(tier))
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


func _set_catch_tab(tab: int) -> void:
	_catch_tab = tab
	_open_panel("catch")


# ============================ 每日订单 ============================

func _today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


## 维护当日起点快照（跨天自动重置）。用于统计页"今日渔获/收入"。
func _ensure_day_stat() -> void:
	var today := _today_key()
	if str(day_stat.get("date", "")) != today:
		day_stat = {"date": today, "catches": lifetime_catches, "coins": lifetime_coins}


func _today_catches() -> int:
	_ensure_day_stat()
	return maxi(0, lifetime_catches - int(day_stat.get("catches", 0)))


func _today_income() -> int:
	_ensure_day_stat()
	return maxi(0, lifetime_coins - int(day_stat.get("coins", 0)))


func _ensure_daily_order() -> void:
	var today := _today_key()
	if daily_order.has("date") and str(daily_order.get("date", "")) == today \
			and FishData.FISH.has(str(daily_order.get("fish", ""))) \
			and int(daily_order.get("need", 0)) > 0:
		return
	daily_order = _make_daily_order(today)


# ============================ 周目标 ============================

func _week_id() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0 / 7.0)


func _ensure_weekly() -> void:
	var wk := _week_id()
	if weekly.has("week") and int(weekly.get("week", -1)) == wk \
			and weekly.has("kind") and int(weekly.get("target", 0)) > 0:
		return
	weekly = _make_weekly(wk)


func _make_weekly(wk: int) -> Dictionary:
	var local := RandomNumberGenerator.new()
	local.seed = int(abs(("week:%d" % wk).hash()))
	var kind: String = "catches" if local.randi() % 2 == 0 else "coins"
	var target := 0
	var base := 0
	if kind == "catches":
		target = 120 + rod_level * 40
		base = lifetime_catches
	else:
		target = 4000 + rod_level * 2500
		base = lifetime_coins
	return {"week": wk, "kind": kind, "target": target, "base": base,
		"reward": 3000 + rod_level * 1500, "done": false}


func _weekly_progress() -> int:
	var cur := lifetime_catches if str(weekly.get("kind", "catches")) == "catches" else lifetime_coins
	return maxi(0, cur - int(weekly.get("base", 0)))


func _weekly_desc() -> String:
	if str(weekly.get("kind", "catches")) == "catches":
		return "本周累计钓到 %d 条鱼" % int(weekly.get("target", 0))
	return "本周累计卖鱼赚 %d 金币" % int(weekly.get("target", 0))


func _try_claim_weekly() -> void:
	_ensure_weekly()
	if bool(weekly.get("done", false)):
		return
	if _weekly_progress() < int(weekly.get("target", 0)):
		Audio.play_ui("ui_error")
		_toast("周目标还没达成", 1.6, Color(1.0, 0.5, 0.4))
		return
	var reward := int(weekly.get("reward", 0))
	coins += reward
	weekly["done"] = true
	Audio.play_sfx("coin")
	_toast("周目标达成：+%d 金币！" % reward, 3.0, Color(0.98, 0.82, 0.40))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_save()


## 生成每日订单。kind ∈ species/tier/weight/perfect（perfect 需鱼饵≥2 才出，避免难以达成）。
## fish 字段恒为一个有效鱼 id（作图标与 species 目标），保证旧存档守卫兼容。
func _make_daily_order(date_key: String) -> Dictionary:
	var local := RandomNumberGenerator.new()
	local.seed = int(abs(("%s:%d" % [date_key, rod_level]).hash()))
	var max_tier := clampi(1 + int(float(rod_level - 1) / 3.0), 1, 3)
	# 候选鱼 = 所有已解锁钓点鱼池的并集（保证订单可在某已解锁钓点完成；多钓点感知）
	var ids := _order_pool()
	if ids.is_empty():
		ids = FishData.FISH.keys()
	var candidates: Array = []
	for id in ids:
		if FishData.tier_of(str(id)) <= max_tier:
			candidates.append(str(id))
	if candidates.is_empty():
		candidates = ids
	var fish_id: String = candidates[local.randi() % candidates.size()]
	var kinds := ["species", "species", "species", "tier", "weight"]
	if bait_level >= 2:
		kinds.append("perfect")
	var kind: String = kinds[local.randi() % kinds.size()]
	var order := {"date": date_key, "kind": kind, "fish": fish_id, "done": false,
		"need": 1, "tier": 1, "minw": 1.0}
	match kind:
		"tier":
			var mt := local.randi_range(1, max_tier)
			order["tier"] = mt
			order["need"] = clampi(4 - mt, 1, 3)
			order["fish"] = _rep_fish_of_tier(mt, local, ids)
		"weight":
			order["minw"] = [1.0, 2.0, 3.0][local.randi_range(0, 2)]
			order["need"] = local.randi_range(1, 2)
		"perfect":
			order["need"] = 1
		_:  # species
			match FishData.tier_of(fish_id):
				0: order["need"] = local.randi_range(3, 5)
				1: order["need"] = local.randi_range(2, 3)
				2: order["need"] = local.randi_range(1, 2)
				_: order["need"] = 1
	order["spot"] = _best_spot_for(str(order["fish"]))  # 建议钓点提示
	return order


## 取某品阶的代表鱼 id（仅用于订单图标/建议）。pool 限定候选鱼范围。
func _rep_fish_of_tier(t: int, local: RandomNumberGenerator, pool: Array = []) -> String:
	var src: Array = pool if not pool.is_empty() else FishData.FISH.keys()
	var bucket: Array = []
	for id in src:
		if FishData.tier_of(str(id)) == t:
			bucket.append(str(id))
	if bucket.is_empty():
		return str(src[0]) if not src.is_empty() else str(FishData.FISH.keys()[0])
	bucket.sort()
	return str(bucket[local.randi() % bucket.size()])


## 一条渔获是否满足当前订单（不含上锁判定）。
func _order_matches(c: Dictionary) -> bool:
	match str(daily_order.get("kind", "species")):
		"tier":
			return FishData.tier_of(str(c.get("id", ""))) >= int(daily_order.get("tier", 1))
		"weight":
			return float(c.get("w", 0.0)) >= float(daily_order.get("minw", 1.0))
		"perfect":
			return int(c.get("q", 0)) >= 3
		_:
			return str(c.get("id", "")) == str(daily_order.get("fish", ""))


## 订单一句话标题。
func _order_title() -> String:
	var need := int(daily_order.get("need", 1))
	match str(daily_order.get("kind", "species")):
		"tier":
			return "收 %d 条 %s及以上" % [need, FishData.TIER_NAMES[int(daily_order.get("tier", 1))]]
		"weight":
			return "收 %d 条 ≥%.1fkg 的鱼" % [need, float(daily_order.get("minw", 1.0))]
		"perfect":
			return "收 %d 条 完美★★★渔获" % need
		_:
			return "收 %d 条 %s" % [need, FishData.display_name(str(daily_order.get("fish", "")))]


## HUD 用的订单短标签。
func _order_short() -> String:
	match str(daily_order.get("kind", "species")):
		"tier":
			return "%s+" % FishData.TIER_NAMES[int(daily_order.get("tier", 1))]
		"weight":
			return "≥%.1fkg" % float(daily_order.get("minw", 1.0))
		"perfect":
			return "完美★"
		_:
			return FishData.display_name(str(daily_order.get("fish", "")))


func _is_daily_order_target(id: String) -> bool:
	_ensure_daily_order()
	return not bool(daily_order.get("done", false)) and id == str(daily_order.get("fish", ""))


func _daily_order_indices() -> Array:
	_ensure_daily_order()
	var out: Array = []
	for i in inventory.size():
		var c: Dictionary = inventory[i]
		if _order_matches(c) and not bool(c.get("lock", false)):
			out.append(i)
	out.sort_custom(func(a, b):
		return int(inventory[int(a)]["v"]) > int(inventory[int(b)]["v"]))
	return out


func _daily_order_reward(indices: Array) -> int:
	var need := int(daily_order.get("need", 0))
	var total := 0
	for i in mini(need, indices.size()):
		total += int(inventory[int(indices[i])]["v"])
	var mult := DAILY_ORDER_MULT
	if _merchant_active:
		mult *= MERCHANT_MULT  # 收鱼郎在场：订单结算再 ×1.5（黄金时刻）
	return int(ceil(float(total) * mult))


func _try_complete_daily_order() -> void:
	_ensure_daily_order()
	if bool(daily_order.get("done", false)):
		_toast("今日订单已经完成", 1.6, Color(0.76, 0.72, 0.64))
		return
	var need := int(daily_order.get("need", 0))
	var indices := _daily_order_indices()
	if indices.size() < need:
		_toast("目标鱼还不够", 1.6, Color(1.0, 0.5, 0.4))
		return
	var reward := _daily_order_reward(indices)
	var chosen := indices.slice(0, need)
	chosen.sort_custom(func(a, b): return int(a) > int(b))
	for idx in chosen:
		inventory.remove_at(int(idx))
	coins += reward
	lifetime_coins += reward
	daily_order["done"] = true
	Audio.play_sfx("coin")
	_toast("每日订单完成：+%d 金币%s" % [reward, "（收鱼郎×1.5）" if _merchant_active else ""],
		2.6, Color(0.98, 0.82, 0.40))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_save()


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
func _sell_value(c: Dictionary) -> int:
	if _merchant_active:
		return int(ceil(float(c["v"]) * MERCHANT_MULT))
	return int(c["v"])


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

## 当前钓点可触发的事件 id 列表（事件池 ∩ EventData 适配本钓点）。
func _eligible_events() -> Array:
	var out: Array = []
	for eid in SpotData.event_pool(current_spot):
		if EventData.has(str(eid)) and EventData.applies_to(str(eid), current_spot):
			out.append(str(eid))
	return out


## 事件主循环：buff 在场则走时长，否则走间隔到点触发。同一时刻最多一个 buff。
func _tick_events(delta: float) -> void:
	if active_event != "":
		_event_buff_t -= delta
		if _event_buff_t <= 0.0:
			_end_buff()
		return
	_event_next_t -= delta
	if _event_next_t <= 0.0:
		_fire_event()


## 触发一次事件：从当前钓点池随机挑选（forced 用于测试指定）。buff 进场 / instant 结算。
func _fire_event(forced := "") -> void:
	var pool := _eligible_events()
	if pool.is_empty():
		_event_next_t = rng.randf_range(EVENT_FIRST.x, EVENT_FIRST.y)
		return
	var id := forced if (forced != "" and forced in pool) else str(pool[rng.randi() % pool.size()])
	if EventData.is_instant(id):
		_resolve_instant(id)
		_schedule_next_after(id)
	else:
		_activate_buff(id)


## buff 事件进场：设时长、提示、可选闪光，并立刻按新节奏重排下一口。
func _activate_buff(id: String) -> void:
	active_event = id
	var e: Dictionary = EventData.get_event(id)
	var dur: Array = e.get("dur", [45.0, 70.0])
	_event_buff_t = rng.randf_range(float(dur[0]), float(dur[1]))
	if EventData.wants_flash(id) and not focus_mode:
		_flash()
	var tin := str(e.get("toast_in", ""))
	if tin != "":
		_toast(tin, 3.5, EventData.color(id))
	_begin_wait()
	_update_hud()


## buff 事件退场：清状态、提示、排下一次事件。
func _end_buff() -> void:
	var id := active_event
	active_event = ""
	var tout := str(EventData.get_event(id).get("toast_out", ""))
	if tout != "":
		_toast(tout, 2.4, Color(0.62, 0.70, 0.74))
	_schedule_next_after(id)
	_update_hud()


## instant 事件结算：发一次性金币奖励（随鱼竿轻微缩放），文案含 +金额。
func _resolve_instant(id: String) -> void:
	var e: Dictionary = EventData.get_event(id)
	var rb: Array = e.get("reward_base", [40, 120])
	var reward := int(round(rng.randf_range(float(rb[0]), float(rb[1])) * (1.0 + float(rod_level - 1) * 0.35)))
	reward = maxi(1, reward)
	coins += reward  # 拾得/保育奖励：进金币但不计入卖鱼终身收入
	Audio.play_sfx("coin")
	var tin := str(e.get("toast_in", ""))
	if tin != "":
		_toast(tin % reward if "%d" in tin else tin, 3.2, EventData.color(id))
	_check_achievements()
	_update_hud()
	_refresh_panel()


## 按某事件的 gap 排下一次事件出现时间。
func _schedule_next_after(id: String) -> void:
	var gap: Array = EventData.get_event(id).get("gap", [900.0, 1800.0])
	_event_next_t = rng.randf_range(float(gap[0]), float(gap[1]))


# ============================ 多钓点 ============================

## 补登已满足解锁条件的钓点；运行期（_unlocks_inited 后）新解锁会弹提示。
func _refresh_unlocks() -> void:
	var species := dex.size()
	for sid in SpotData.SPOT_ORDER:
		if sid in unlocked_spots:
			continue
		if SpotData.unlock_met(sid, lifetime_catches, lifetime_coins, species):
			unlocked_spots.append(sid)
			if _unlocks_inited:
				Audio.play_sfx("upgrade")
				_toast("新钓点解锁：%s！（鱼篓→钓点 切换过去）" % SpotData.display_name(sid),
					4.0, Color(0.6, 0.85, 0.55))


## 切换到某钓点：换鱼池 / 事件 / 背景 / 订单建议。锁定钓点拒绝。
func _switch_spot(id: String) -> void:
	if not SpotData.has(id) or not (id in unlocked_spots):
		Audio.play_ui("ui_error")
		_toast("这个钓点还没解锁", 1.6, Color(1.0, 0.5, 0.4))
		return
	if id == current_spot:
		return
	current_spot = id
	if not (id in seen_spots):
		seen_spots.append(id)
	# 换钓点 → 在场事件清空，按新钓点重排下一次事件
	if active_event != "":
		active_event = ""
		_event_buff_t = 0.0
	_event_next_t = rng.randf_range(EVENT_FIRST.x, EVENT_FIRST.y)
	_apply_spot_visuals()
	_ensure_daily_order()
	Audio.play_sfx("upgrade")
	_toast("已来到 %s" % SpotData.display_name(id), 2.2, Color(0.6, 0.82, 0.95))
	_begin_wait()  # 立刻按新钓点节奏重排
	_update_hud()
	_refresh_panel()
	_save()


## 把当前钓点的背景切给 ScenePainter（缺图自动回退现有主图，不崩）。
func _apply_spot_visuals() -> void:
	if painter.has_method("set_spot"):
		painter.set_spot(str(SpotData.get_spot(current_spot).get("bg_key", "")))


## 订单候选鱼池：所有已解锁钓点鱼池的并集（保证订单总能在某个已解锁钓点完成）。
func _order_pool() -> Array:
	var seen := {}
	var out: Array = []
	for sid in unlocked_spots:
		for fid in SpotData.pool_for(sid):
			if not seen.has(fid):
				seen[fid] = true
				out.append(fid)
	out.sort_custom(func(a, b):
		var ta := FishData.tier_of(str(a))
		var tb := FishData.tier_of(str(b))
		if ta != tb:
			return ta < tb
		return str(a) < str(b))
	return out


## 某鱼最适合在哪个已解锁钓点钓（订单 UI 的“建议钓点”提示）。
func _best_spot_for(fish_id: String) -> String:
	for sid in SpotData.SPOT_ORDER:
		if sid in unlocked_spots and fish_id in SpotData.pool_for(sid):
			return sid
	return current_spot


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
	_open_panel("rod")


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
	_open_panel("rod")


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
	_open_panel("rod")


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


## 离线钓鱼：上鱼数 = 时长/平均间隔×效率，受背包剩余格数限制。
## 同时汇总成 _offline_report 供回屏小结面板展示。返回实际入篓条数。
func _offline_catch(elapsed: float) -> int:
	var wait_factor: float = maxf(0.4, 1.0 - float(rod_level - 1) * 0.06)
	var avg_interval := 5.25 * wait_factor + 0.9
	var est := int(elapsed / avg_interval * OFFLINE_EFFICIENCY)
	var free := _bag_capacity() - inventory.size()
	var n: int = clampi(est, 0, free)
	var total_v := 0
	var top: Dictionary = {}
	var notable: Array = []
	for i in n:
		var c := FishData.roll_catch(rng, rod_level, bait_level, 0, _spot_pool())
		inventory.append(c)
		var ib := FishData.size_tag(c["id"], c["w"]) == "巨物·"
		_dex_record(c["id"], float(c["w"]), ib, int(c.get("q", 0)) >= 3)
		lifetime_catches += 1
		best_quality = maxi(best_quality, int(c.get("q", 0)))
		if ib:
			caught_giant = true
		total_v += int(c["v"])
		if top.is_empty() or int(c["v"]) > int(top["v"]):
			top = c
		if FishData.tier_of(c["id"]) >= 3 or int(c.get("q", 0)) >= 2:
			notable.append(c)
	if n > 0:
		_offline_report = {"count": n, "value": total_v, "top": top, "notable": notable}
	return n


func _fmt_dur(sec: float) -> String:
	var h := int(sec) / 3600
	var m := (int(sec) % 3600) / 60
	if h > 0:
		return "%d 小时 %d 分" % [h, m]
	return "%d 分钟" % max(1, m)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()
		get_tree().quit()


func _quit_game() -> void:
	_save()
	get_tree().quit()
