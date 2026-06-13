extends Node2D
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
var order_chip: Button = null   # HUD 上的每日订单进度小字（可点开订单页）

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

# —— 鱼汛：随机限时事件，咬钩更快 + 高阶鱼概率大增（仿宠物游戏流星雨）——
const RUN_LUCK := 7                                # 鱼汛期间品阶运气加成（高潮事件，大鱼明显变多）
const RUN_WAIT_MULT := 0.5                         # 鱼汛期间等待时长系数
const RUN_DUR := Vector2(45.0, 70.0)
const RUN_GAP := Vector2(900.0, 1800.0)
const RUN_FIRST := Vector2(240.0, 480.0)
var _run_active := false
var _run_t := 0.0

# —— 每日订单：每天 1 单，交付指定鱼种，按原价 ×2.5 结算 ——
const DAILY_ORDER_MULT := 2.5
var daily_order := {}  # {"date": yyyy-mm-dd, "fish": id, "need": int, "done": bool}


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
	_build_order_chip()
	_setup_window()
	_load_ui_layout()
	_load_save()
	_ensure_daily_order()
	_build_buttons()
	_merchant_t = rng.randf_range(MERCHANT_FIRST.x, MERCHANT_FIRST.y)
	_run_t = rng.randf_range(RUN_FIRST.x, RUN_FIRST.y)
	_update_hud()
	_begin_wait()
	_started = true
	Audio.start_ambience()
	if not _offline_report.is_empty():
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
	if _saved_win_pos != null:
		DisplayServer.window_set_position(_saved_win_pos)
	else:
		_place_corner()
	_update_passthrough()


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
	_tick_fish_run(delta)
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
	if _run_active:
		w *= RUN_WAIT_MULT  # 鱼汛期间咬钩更勤
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


func _do_catch() -> void:
	if _bag_full():
		_begin_wait()
		return
	var luck := RUN_LUCK if _run_active else 0
	var c := FishData.roll_catch(rng, rod_level, bait_level, luck)
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
		var c2 := FishData.roll_catch(rng, rod_level, bait_level, luck)
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
	var bag := "鱼篓 %d/%d" % [inventory.size(), _bag_capacity()]
	if _bag_full():
		bag += "（满）"
	var mer := "　收鱼郎×1.5" if _merchant_active else ""
	var run := "　🌊鱼汛!" if _run_active else ""
	coins_label.text = "金币 %d　%s%s%s" % [coins, bag, mer, run]
	var col := Color(0.92, 0.92, 0.9)
	if _run_active:
		col = Color(0.55, 0.80, 0.96)
	elif _merchant_active:
		col = Color(0.98, 0.82, 0.40)
	elif _bag_full():
		col = Color(1.0, 0.78, 0.45)
	coins_label.add_theme_color_override("font_color", col)
	_update_order_chip()


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


func _open_panel(kind: String) -> void:
	if is_instance_valid(_panel):
		_panel_saved_pos = _panel.position
	_close_panel()
	var titles := {"catch": "鱼篓", "rod": "鱼竿 · 升级", "set": "设置", "offline": "离线小结"}
	var card := _make_card(str(titles.get(kind, "")))
	if kind != "offline" and _panel_saved_pos != null:
		card.position = _clamp_panel_position(_panel_saved_pos, card.custom_minimum_size)
	var v: VBoxContainer = card.get_node("M/V")
	match kind:
		"catch": _fill_bag_panel(v)
		"rod": _fill_upgrades(v)
		"set": _fill_settings(v)
		"offline": _fill_offline_report(v)
	ui_root.add_child(card)
	_panel = card
	_panel_kind = kind
	_set_interactive_full(true)


func _close_panel() -> void:
	if is_instance_valid(_panel):
		_panel_saved_pos = _panel.position
		_panel.queue_free()
	_panel = null
	_panel_kind = ""
	_panel_dragging = false
	_set_interactive_full(false)


func _set_interactive_full(full: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if full:
		var ws := Vector2(DisplayServer.window_get_size())
		DisplayServer.window_set_mouse_passthrough(PackedVector2Array([
			Vector2(0, 0), Vector2(ws.x, 0), ws, Vector2(0, ws.y)]))
	else:
		_update_passthrough()


func _panel_bg_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.13, 0.12, 0.94)
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.88, 0.84, 0.74, 0.72)
	sb.shadow_color = Color(0, 0, 0, 0.32)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(4, 6)
	return sb


func _paper_style(alpha := 0.88) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.91, 0.88, 0.78, alpha)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.96, 0.84, 0.46)
	return sb


func _dark_row_style(alpha := 0.52) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.20, 0.21, 0.19, alpha)
	sb.set_corner_radius_all(9)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.86, 0.82, 0.70, 0.16)
	return sb


func _button_style(primary := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.66, 0.49, 0.25, 0.92) if primary else Color(0.36, 0.36, 0.32, 0.84)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(1)
	sb.border_color = Color(1.0, 0.87, 0.55, 0.28) if primary else Color(0.84, 0.80, 0.68, 0.22)
	return sb


func _apply_button_skin(b: Button, primary := false) -> void:
	b.focus_mode = Control.FOCUS_NONE
	var normal := _button_style(primary)
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
	# 统一按钮点击音（带功能音的按钮会在其逻辑里再叠加 coin/upgrade，听感上 click=按下、后者=结果）
	b.pressed.connect(func() -> void: Audio.play_ui("ui_click"))


func _fish_icon(id: String, size := 42) -> TextureRect:
	var tr := TextureRect.new()
	tr.custom_minimum_size = Vector2(size, size)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var path := "res://assets/art/fish/%s.png" % id
	if ResourceLoader.exists(path):
		tr.texture = load(path) as Texture2D
	return tr


func _tier_color(tier: int) -> Color:
	return FishData.TIER_COLORS[clampi(tier, 0, FishData.TIER_COLORS.size() - 1)]


func _ui_tier_color(tier: int, on_paper := false) -> Color:
	if tier == 0:
		return Color(0.38, 0.37, 0.33) if on_paper else Color(0.86, 0.84, 0.78)
	return _tier_color(tier)


func _make_card(title: String) -> Control:
	var p := PanelContainer.new()
	p.z_index = 50
	# 居中在更大的窗口里，面板更宽更高、不再受角落小窗约束
	var card := Vector2(520, 476)
	p.position = ((Vector2(WIN) - card) * 0.5).round()
	p.custom_minimum_size = card
	p.add_theme_stylebox_override("panel", _panel_bg_style())
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
	hb.gui_input.connect(_panel_drag_input.bind(p))
	var tl := Label.new()
	tl.text = title
	tl.add_theme_font_size_override("font_size", 20)
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
	cb.pressed.connect(_close_panel)
	hb.add_child(cb)
	v.add_child(hb)
	return p


func _clamp_panel_position(pos: Vector2, size: Vector2) -> Vector2:
	var max_pos := Vector2(WIN) - size
	return Vector2(clampf(pos.x, 0.0, maxf(0.0, max_pos.x)),
		clampf(pos.y, 0.0, maxf(0.0, max_pos.y)))


func _panel_drag_input(event: InputEvent, panel: Control) -> void:
	if not is_instance_valid(panel):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_panel_dragging = true
			_panel_drag_offset = panel.get_global_mouse_position() - panel.position
		else:
			_panel_dragging = false
			_panel_saved_pos = panel.position
	elif event is InputEventMouseMotion and _panel_dragging:
		panel.position = _clamp_panel_position(panel.get_global_mouse_position() - _panel_drag_offset,
			panel.custom_minimum_size)


func _set_catch_tab(tab: int) -> void:
	_catch_tab = tab
	_open_panel("catch")


func _fill_bag_panel(v: VBoxContainer) -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	var names := ["背包", "图鉴", "订单", "成就", "统计"]
	for i in range(names.size()):
		var tb := Button.new()
		tb.text = names[i]
		tb.custom_minimum_size = Vector2(50, 28)
		_apply_button_skin(tb, i == _catch_tab)
		if i != _catch_tab:
			tb.pressed.connect(_set_catch_tab.bind(i))
		tabs.add_child(tb)
	v.add_child(tabs)
	match _catch_tab:
		0: _fill_bag_tab(v)
		1: _fill_dex_tab(v)
		2: _fill_order_tab(v)
		3: _fill_ach_tab(v)
		_: _fill_stats_tab(v)


## 统计页：长期成长看板（只读）。
func _fill_stats_tab(v: VBoxContainer) -> void:
	# 找最大一条（图鉴每种存了最大体重纪录）
	var big_id := ""
	var big_w := 0.0
	for id in dex:
		if float(dex[id]["w"]) > big_w:
			big_w = float(dex[id]["w"])
			big_id = str(id)
	var biggest := "—"
	if big_id != "":
		biggest = "%s %.2fkg" % [FishData.display_name(big_id), big_w]
	var q := best_quality
	var q_txt: String = (str(FishData.QUALITY_NAMES[clampi(q, 0, 3)]) + "★".repeat(q)) if q > 0 else "普通"
	var rows := [
		["终身渔获", "%d 条" % lifetime_catches],
		["终身卖鱼收入", "%d 金币" % lifetime_coins],
		["当前金币", "%d" % coins],
		["图鉴收集", "%d / %d 种" % [dex.size(), FishData.FISH.size()]],
		["成就达成", "%d / %d" % [achievements_done.size(), AchievementData.LIST.size()]],
		["最高品相", q_txt],
		["最大渔获", biggest],
		["巨物纪录", "已钓到" if caught_giant else "尚无"],
		["鱼篓容量", "%d 格" % _bag_capacity()],
		["当前装备", "鱼竿 Lv.%d · %s · %s" % [
			rod_level, FishData.BAITS[bait_level]["name"], FishData.HOOKS[hook_level]["name"]]],
	]
	var sc0 := ScrollContainer.new()
	sc0.custom_minimum_size = Vector2(0, 360)
	sc0.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	for r in rows:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", _paper_style(0.86))
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


func _fill_ach_tab(v: VBoxContainer) -> void:
	var stat := Label.new()
	stat.text = "已达成 %d/%d" % [achievements_done.size(), AchievementData.LIST.size()]
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 330)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	# 已达成的排前面
	var sorted: Array = AchievementData.LIST.duplicate()
	sorted.sort_custom(func(a, b):
		return achievements_done.has(a["id"]) and not achievements_done.has(b["id"]))
	for a in sorted:
		list.add_child(_ach_row(a))
	sc.add_child(list)
	v.add_child(sc)


func _ach_row(a: Dictionary) -> Control:
	var done: bool = achievements_done.has(a["id"])
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _paper_style(0.88) if done else _dark_row_style(0.42))
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


# ============================ 每日订单 ============================

func _today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


func _ensure_daily_order() -> void:
	var today := _today_key()
	if daily_order.has("date") and str(daily_order.get("date", "")) == today \
			and FishData.FISH.has(str(daily_order.get("fish", ""))) \
			and int(daily_order.get("need", 0)) > 0:
		return
	daily_order = _make_daily_order(today)


## 生成每日订单。kind ∈ species/tier/weight/perfect（perfect 需鱼饵≥2 才出，避免难以达成）。
## fish 字段恒为一个有效鱼 id（作图标与 species 目标），保证旧存档守卫兼容。
func _make_daily_order(date_key: String) -> Dictionary:
	var local := RandomNumberGenerator.new()
	local.seed = int(abs(("%s:%d" % [date_key, rod_level]).hash()))
	var max_tier := clampi(1 + int(float(rod_level - 1) / 3.0), 1, 3)
	var candidates: Array = []
	var ids := FishData.FISH.keys()
	ids.sort()
	for id in ids:
		if FishData.tier_of(str(id)) <= max_tier:
			candidates.append(str(id))
	if candidates.is_empty():
		candidates = FishData.FISH.keys()
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
			order["fish"] = _rep_fish_of_tier(mt, local)
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
	return order


## 取某品阶的代表鱼 id（仅用于订单图标）。
func _rep_fish_of_tier(t: int, local: RandomNumberGenerator) -> String:
	var pool: Array = []
	for id in FishData.FISH:
		if FishData.tier_of(str(id)) == t:
			pool.append(str(id))
	if pool.is_empty():
		return str(FishData.FISH.keys()[0])
	pool.sort()
	return str(pool[local.randi() % pool.size()])


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
	return int(ceil(float(total) * DAILY_ORDER_MULT))


func _fill_order_tab(v: VBoxContainer) -> void:
	_ensure_daily_order()
	var target := str(daily_order.get("fish", ""))
	if not FishData.FISH.has(target):
		var bad := Label.new()
		bad.text = "今日订单生成失败。"
		bad.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
		v.add_child(bad)
		return
	var done := bool(daily_order.get("done", false))
	var need := int(daily_order.get("need", 1))
	var indices := _daily_order_indices()
	var have := indices.size()
	var reward := _daily_order_reward(indices)
	var kind := str(daily_order.get("kind", "species"))

	var stat := Label.new()
	stat.text = "每日订单 · %s" % str(daily_order.get("date", ""))
	stat.add_theme_color_override("font_color", Color(0.78, 0.74, 0.66))
	v.add_child(stat)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 150)
	panel.add_theme_stylebox_override("panel", _paper_style(0.90) if not done else _dark_row_style(0.44))
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10 if side in ["left", "right"] else 9)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	row.add_child(_fish_icon(target, 64))

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = _order_title()
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color",
		Color(0.28, 0.25, 0.20) if not done else Color(0.74, 0.70, 0.62))
	info.add_child(title)
	var kind_label: String = {"species": "指定鱼种", "tier": "指定品阶", "weight": "大物", "perfect": "完美品质"}.get(kind, "")
	var desc := Label.new()
	desc.text = "%s订单 · 交付未上锁的符合渔获，按鱼价 ×%.1f 结算" % [kind_label, DAILY_ORDER_MULT]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(220, 0)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color",
		Color(0.46, 0.42, 0.34) if not done else Color(0.64, 0.60, 0.54))
	info.add_child(desc)
	var progress := Label.new()
	if done:
		progress.text = "今日已完成"
	else:
		progress.text = "可交付 %d/%d%s" % [have, need, " · 预计 +%d 金币" % reward if have >= need else ""]
	progress.add_theme_color_override("font_color",
		Color(0.84, 0.58, 0.18) if have >= need and not done else Color(0.56, 0.51, 0.42))
	info.add_child(progress)
	row.add_child(info)

	var btn := Button.new()
	btn.text = "已完成" if done else "交付"
	btn.custom_minimum_size = Vector2(64, 34)
	btn.disabled = done or have < need
	_apply_button_skin(btn, have >= need and not done)
	btn.pressed.connect(_try_complete_daily_order)
	row.add_child(btn)
	v.add_child(panel)

	var hint := Label.new()
	hint.text = "锁定的目标鱼会留在鱼篓里，不会被订单交付。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.70, 0.66, 0.58))
	v.add_child(hint)


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
	_toast("每日订单完成：+%d 金币" % reward, 2.6, Color(0.98, 0.82, 0.40))
	_check_achievements()
	_update_hud()
	_refresh_panel()
	_save()


func _fill_bag_tab(v: VBoxContainer) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	var cap := Label.new()
	cap.text = "%d/%d" % [inventory.size(), _bag_capacity()]
	cap.custom_minimum_size = Vector2(46, 0)
	cap.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42) if _bag_full() else Color(0.78, 0.74, 0.66))
	head.add_child(cap)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var total := 0
	var unlocked := 0
	var junk := 0
	for c in inventory:
		if not bool(c.get("lock", false)):
			total += _sell_value(c)
			unlocked += 1
			if not _order_matches(c):
				junk += 1
	var sell_junk := Button.new()
	sell_junk.text = "卖杂鱼"
	sell_junk.custom_minimum_size = Vector2(64, 28)
	sell_junk.disabled = junk == 0
	sell_junk.tooltip_text = "卖出 %d 条非订单、非收藏的鱼（保留订单目标鱼与锁定）" % junk
	_apply_button_skin(sell_junk, false)
	sell_junk.pressed.connect(_sell_junk)
	head.add_child(sell_junk)
	var sell_all := Button.new()
	sell_all.text = "全部卖出"
	sell_all.custom_minimum_size = Vector2(76, 28)
	sell_all.disabled = unlocked == 0
	sell_all.tooltip_text = "卖出 %d 条未上锁的鱼，+%d 金币%s（锁定的会留下）" % [
		unlocked, total, "（收鱼郎×1.5）" if _merchant_active else ""]
	_apply_button_skin(sell_all, true)
	sell_all.pressed.connect(_sell_all)
	head.add_child(sell_all)
	if bag_level <= BAG_COSTS.size():
		var cost: int = BAG_COSTS[bag_level - 1]
		var expand := Button.new()
		expand.text = "扩容"
		expand.custom_minimum_size = Vector2(52, 28)
		expand.disabled = coins < cost
		expand.tooltip_text = "扩到 %d 格，花费 %d 金币" % [BAG_CAPS[bag_level], cost]
		_apply_button_skin(expand, false)
		expand.pressed.connect(_try_expand_bag)
		head.add_child(expand)
	v.add_child(head)

	if inventory.is_empty():
		var empty_panel := PanelContainer.new()
		empty_panel.custom_minimum_size = Vector2(0, 86)
		empty_panel.add_theme_stylebox_override("panel", _paper_style(0.86))
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

	# 排序 / 筛选 行
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 4)
	var sort_lbl := Label.new()
	sort_lbl.text = "排序"
	sort_lbl.add_theme_font_size_override("font_size", 12)
	sort_lbl.add_theme_color_override("font_color", Color(0.6, 0.57, 0.5))
	tools.add_child(sort_lbl)
	for m in BAG_SORT_NAMES.size():
		var sb := Button.new()
		sb.text = BAG_SORT_NAMES[m]
		sb.custom_minimum_size = Vector2(44, 24)
		sb.add_theme_font_size_override("font_size", 12)
		_apply_button_skin(sb, m == _bag_sort)
		if m != _bag_sort:
			sb.pressed.connect(func(mm = m) -> void:
				_bag_sort = mm
				_open_panel("catch"))
		tools.add_child(sb)
	var fsp := Control.new()
	fsp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tools.add_child(fsp)
	var filt := Button.new()
	filt.text = "订单鱼"
	filt.custom_minimum_size = Vector2(56, 24)
	filt.add_theme_font_size_override("font_size", 12)
	filt.tooltip_text = "只看今日订单的目标鱼"
	_apply_button_skin(filt, _bag_filter_order)
	filt.pressed.connect(func() -> void:
		_bag_filter_order = not _bag_filter_order
		_open_panel("catch"))
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
	var order_target := str(daily_order.get("fish", "")) if _bag_filter_order else ""
	var idxs := _sorted_bag_indices(order_target)
	if idxs.is_empty():
		var none := Label.new()
		none.text = "没有符合条件的鱼"
		none.add_theme_color_override("font_color", Color(0.6, 0.57, 0.5))
		grid.add_child(none)
	for i in idxs:
		grid.add_child(_fish_entry(inventory[i], i, false, true))
	sc.add_child(grid)
	v.add_child(sc)


## 按当前排序/筛选返回背包显示用的真实索引序列。
func _sorted_bag_indices(order_target: String) -> Array:
	var idxs: Array = []
	for i in inventory.size():
		if order_target != "" and str(inventory[i].get("id", "")) != order_target:
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


func _fish_entry(c: Dictionary, idx: int, featured := false, compact := false) -> Control:
	var tier := FishData.tier_of(c["id"])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(232 if compact else 0, 58 if compact else (76 if featured else 52))
	panel.add_theme_stylebox_override("panel", _paper_style(0.92) if featured else _dark_row_style(0.48))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7 if compact else (8 if featured else 6))
	margin.add_theme_constant_override("margin_top", 5 if compact else (6 if featured else 3))
	margin.add_theme_constant_override("margin_right", 6 if compact else (8 if featured else 5))
	margin.add_theme_constant_override("margin_bottom", 5 if compact else (6 if featured else 3))
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5 if compact else 7)
	margin.add_child(row)
	row.add_child(_fish_icon(str(c["id"]), 34 if compact else (58 if featured else 38)))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	var nm := Label.new()
	nm.text = "%s %s%s%s" % [FishData.TIER_NAMES[tier], FishData.size_tag(c["id"], c["w"]),
		FishData.display_name(c["id"]), "★".repeat(int(c.get("q", 0)))]
	nm.clip_text = true
	nm.add_theme_font_size_override("font_size", 12 if compact else (15 if featured else 13))
	nm.add_theme_color_override("font_color", _ui_tier_color(tier, featured) if featured else _ui_tier_color(tier, false))
	info.add_child(nm)
	var meta := Label.new()
	meta.text = "%.2fkg  %d 金币" % [c["w"], c["v"]]
	meta.clip_text = true
	meta.add_theme_font_size_override("font_size", 11 if compact else (13 if featured else 12))
	meta.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42) if featured else Color(0.78, 0.68, 0.45))
	info.add_child(meta)
	row.add_child(info)
	var locked: bool = bool(c.get("lock", false))
	var lk := Button.new()
	lk.text = "解" if locked else "锁"
	lk.tooltip_text = "解除收藏锁" if locked else "上锁收藏（不会被卖出）"
	lk.custom_minimum_size = Vector2(28, 32 if featured else 30)
	lk.focus_mode = Control.FOCUS_NONE
	_apply_button_skin(lk, false)
	if locked:
		lk.add_theme_color_override("font_color", Color(0.95, 0.78, 0.42))
	lk.pressed.connect(_toggle_lock.bind(idx))
	row.add_child(lk)
	var sell := Button.new()
	sell.text = "藏" if locked else "卖"
	sell.disabled = locked
	sell.custom_minimum_size = Vector2(34 if featured else 28, 32 if featured else 30)
	_apply_button_skin(sell, featured)
	sell.pressed.connect(_sell_one.bind(idx))
	row.add_child(sell)
	return panel


func _fill_dex_tab(v: VBoxContainer) -> void:
	var stat := Label.new()
	stat.text = "收集 %d/%d  /  渔获 %d" % [dex.size(), FishData.FISH.size(), lifetime_catches]
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
		grid.add_child(_dex_card(str(id)))
	sc.add_child(grid)
	v.add_child(sc)


func _dex_card(id: String) -> Control:
	var known := dex.has(id)
	var tier := FishData.tier_of(id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(112, 98)
	panel.add_theme_stylebox_override("panel", _paper_style(0.88) if known else _dark_row_style(0.40))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)
	var icon := _fish_icon(id, 42)
	icon.modulate = Color(1, 1, 1, 1.0 if known else 0.28)
	box.add_child(icon)
	var name := Label.new()
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.clip_text = true
	name.text = FishData.display_name(id) if known else "未发现"
	name.add_theme_font_size_override("font_size", 12)
	name.add_theme_color_override("font_color", _ui_tier_color(tier, true) if known else Color(0.58, 0.56, 0.50))
	box.add_child(name)
	if known:
		var r: Dictionary = dex[id]
		var rec := Label.new()
		rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rec.clip_text = true
		rec.text = "×%d · 最大 %.2fkg" % [int(r["n"]), float(r["w"])] \
			if float(r["w"]) > 0.0 else "×%d" % int(r["n"])
		rec.add_theme_font_size_override("font_size", 10)
		rec.add_theme_color_override("font_color", Color(0.55, 0.50, 0.42))
		box.add_child(rec)
		box.add_child(_dex_badges(r))
	return panel


## 图鉴长期目标徽章行：集齐(10条)/巨物/完美。已达成亮色，未达成淡色提示进度。
func _dex_badges(r: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	var n := int(r["n"])
	var col10 := Label.new()
	col10.add_theme_font_size_override("font_size", 10)
	if n >= 10:
		col10.text = "✦集齐"
		col10.add_theme_color_override("font_color", Color(0.95, 0.80, 0.35))
	else:
		col10.text = "%d/10" % n
		col10.add_theme_color_override("font_color", Color(0.52, 0.49, 0.43))
	row.add_child(col10)
	if bool(r.get("big", false)):
		var b := Label.new()
		b.text = "巨"
		b.add_theme_font_size_override("font_size", 10)
		b.add_theme_color_override("font_color", Color(0.90, 0.66, 0.34))
		row.add_child(b)
	if bool(r.get("perf", false)):
		var p := Label.new()
		p.text = "完★"
		p.add_theme_font_size_override("font_size", 10)
		p.add_theme_color_override("font_color", Color(0.80, 0.62, 0.92))
		row.add_child(p)
	return row


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


## 鱼汛：限时高潮事件，咬钩更快 + 高阶鱼概率大增。
func _tick_fish_run(delta: float) -> void:
	_run_t -= delta
	if _run_t > 0.0:
		return
	if _run_active:
		_run_active = false
		_run_t = rng.randf_range(RUN_GAP.x, RUN_GAP.y)
		_toast("鱼汛退了，水面又归于平静。", 2.4, Color(0.62, 0.70, 0.74))
	else:
		_run_active = true
		_run_t = rng.randf_range(RUN_DUR.x, RUN_DUR.y)
		if not focus_mode:
			_flash()
		_toast("🌊 鱼汛来了！咬钩更勤，大鱼更多！", 3.5, Color(0.5, 0.78, 0.95))
		_begin_wait()  # 立刻按更快节奏重排下一口
	_update_hud()


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


func _fill_upgrades(v: VBoxContainer) -> void:
	var info := Label.new()
	info.text = "当前：鱼竿 Lv.%d" % rod_level
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.3, 0.3, 0.28))
	v.add_child(info)
	var desc := Label.new()
	desc.text = "升级效果：等待更短 · 稀有鱼更易上钩 · 鱼价 +%d%%" % int((rod_level - 1) * 8)
	desc.add_theme_color_override("font_color", Color(0.4, 0.4, 0.38))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(238, 0)
	v.add_child(desc)
	var cost := _rod_cost()
	var costlbl := Label.new()
	costlbl.text = "升级费用：%d 金币" % cost
	costlbl.add_theme_color_override("font_color",
		Color(0.85, 0.6, 0.2) if coins >= cost else Color(0.7, 0.4, 0.4))
	v.add_child(costlbl)
	var btn := Button.new()
	btn.text = "升级鱼竿"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 34)
	_apply_button_skin(btn, true)
	btn.pressed.connect(_try_upgrade_rod)
	v.add_child(btn)
	# —— 鱼饵（星级品质线）——
	v.add_child(HSeparator.new())
	var bait: Dictionary = FishData.BAITS[bait_level]
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
	if bait_level < FishData.BAITS.size() - 1:
		var nxt: Dictionary = FishData.BAITS[bait_level + 1]
		var bcost := int(nxt["cost"])
		var bcostlbl := Label.new()
		bcostlbl.text = "换用 %s：%d 金币" % [nxt["name"], bcost]
		bcostlbl.add_theme_color_override("font_color",
			Color(0.85, 0.6, 0.2) if coins >= bcost else Color(0.7, 0.4, 0.4))
		v.add_child(bcostlbl)
		var bbtn := Button.new()
		bbtn.text = "升级鱼饵"
		bbtn.focus_mode = Control.FOCUS_NONE
		bbtn.custom_minimum_size = Vector2(0, 34)
		_apply_button_skin(bbtn, false)
		bbtn.pressed.connect(_try_upgrade_bait)
		v.add_child(bbtn)
	# —— 鱼钩（双钩几率线）——
	v.add_child(HSeparator.new())
	var hook: Dictionary = FishData.HOOKS[hook_level]
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
	if hook_level < FishData.HOOKS.size() - 1:
		var hnxt: Dictionary = FishData.HOOKS[hook_level + 1]
		var hcost := int(hnxt["cost"])
		var hcostlbl := Label.new()
		hcostlbl.text = "换用 %s（双钩 %d%%）：%d 金币" % [
			hnxt["name"], int(float(hnxt["double"]) * 100.0), hcost]
		hcostlbl.add_theme_color_override("font_color",
			Color(0.85, 0.6, 0.2) if coins >= hcost else Color(0.7, 0.4, 0.4))
		v.add_child(hcostlbl)
		var hbtn := Button.new()
		hbtn.text = "升级鱼钩"
		hbtn.focus_mode = Control.FOCUS_NONE
		hbtn.custom_minimum_size = Vector2(0, 34)
		_apply_button_skin(hbtn, false)
		hbtn.pressed.connect(_try_upgrade_hook)
		v.add_child(hbtn)


## 设置面板用的「标签 + 滑条」一行；value_changed 直连 Audio 的 setter。
func _audio_slider(v: VBoxContainer, label: String, value: float, setter: Callable) -> void:
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


func _fill_settings(v: VBoxContainer) -> void:
	# 高级功能占位（锁定）：自动卖鱼
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
	# 音频
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
	_audio_slider(v, "主音量", Audio.master_volume, Audio.set_master_volume)
	_audio_slider(v, "音效", Audio.sfx_volume, Audio.set_sfx_volume)
	_audio_slider(v, "环境音", Audio.ambience_volume, Audio.set_ambience_volume)
	v.add_child(HSeparator.new())
	# 专注/安静模式
	var focus_row := HBoxContainer.new()
	focus_row.add_theme_constant_override("separation", 8)
	var focus_lbl := Label.new()
	focus_lbl.text = "专注模式（少打扰）"
	focus_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.32))
	focus_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_row.add_child(focus_lbl)
	var focus_btn := CheckButton.new()
	focus_btn.button_pressed = focus_mode
	focus_btn.focus_mode = Control.FOCUS_NONE
	focus_btn.toggled.connect(func(on: bool) -> void:
		_set_focus(on)
		_save())
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
	sl.value = _opacity
	sl.custom_minimum_size = Vector2(220, 18)
	sl.value_changed.connect(_set_opacity)
	v.add_child(sl)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	v.add_child(gap)
	var reset := Button.new()
	reset.text = "回到右下角"
	reset.focus_mode = Control.FOCUS_NONE
	_apply_button_skin(reset, false)
	reset.pressed.connect(_place_corner)
	v.add_child(reset)
	var quit := Button.new()
	quit.text = "退出游戏"
	quit.focus_mode = Control.FOCUS_NONE
	_apply_button_skin(quit, false)
	quit.pressed.connect(_quit_game)
	v.add_child(quit)


## 离线小结面板：欢迎回来 + 时长/渔获/最值钱一条/合计可卖/稀有清单。
func _fill_offline_report(v: VBoxContainer) -> void:
	var rep := _offline_report
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
	# 最值钱一条
	var top: Dictionary = rep.get("top", {})
	if not top.is_empty():
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _paper_style(0.9))
		var mg := MarginContainer.new()
		for s in ["left", "top", "right", "bottom"]:
			mg.add_theme_constant_override("margin_" + s, 8 if s in ["left", "right"] else 6)
		card.add_child(mg)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		mg.add_child(row)
		row.add_child(_fish_icon(str(top["id"]), 48))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		var t := FishData.tier_of(str(top["id"]))
		var nm := Label.new()
		nm.text = "最值钱 · %s %s%s" % [FishData.TIER_NAMES[t],
			FishData.size_tag(str(top["id"]), float(top["w"])), FishData.display_name(str(top["id"]))]
		nm.add_theme_color_override("font_color", _ui_tier_color(t, true))
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
	# 稀有清单
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
			rl.add_theme_color_override("font_color", _ui_tier_color(t2, false))
			v.add_child(rl)
			shown += 1
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	v.add_child(gap)
	var go := Button.new()
	go.text = "去鱼篓看看"
	go.focus_mode = Control.FOCUS_NONE
	go.custom_minimum_size = Vector2(0, 34)
	_apply_button_skin(go, true)
	go.pressed.connect(func() -> void:
		_offline_report = {}
		_catch_tab = 0
		_open_panel("catch"))
	v.add_child(go)


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
	var inv: Array = []
	for c in inventory:
		inv.append([c["id"], c["w"], c["v"], int(c.get("q", 0)),
			1 if bool(c.get("lock", false)) else 0])
	var data := {
		"ver": 6,
		"coins": coins,
		"rod_level": rod_level,
		"bag_level": bag_level,
		"bait": bait_level,
		"hook": hook_level,
		"inv": inv,
		"lt_coins": lifetime_coins,
		"lt_catches": lifetime_catches,
		"dex": _dex_to_save(),
		"daily_order": daily_order,
		"best_q": best_quality,
		"giant": caught_giant,
		"ach": achievements_done.keys(),
		"opacity": _opacity,
		"focus": focus_mode,
		"ts": Time.get_unix_time_from_system(),
	}
	if DisplayServer.get_name() != "headless":
		var wp := DisplayServer.window_get_position()
		data["win_pos"] = [wp.x, wp.y]
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


func _dex_to_save() -> Dictionary:
	var out := {}
	for id in dex:
		var r: Dictionary = dex[id]
		out[id] = [int(r["n"]), float(r["w"]),
			1 if bool(r.get("big", false)) else 0,
			1 if bool(r.get("perf", false)) else 0]
	return out


func _load_save() -> void:
	if not save_enabled or not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return
	coins = int(data.get("coins", 0))
	rod_level = max(1, int(data.get("rod_level", 1)))
	bag_level = max(1, int(data.get("bag_level", 1)))  # v1 存档无此字段 → 默认 1
	bait_level = clampi(int(data.get("bait", 0)), 0, FishData.BAITS.size() - 1)  # v2 及更早 → 蚯蚓
	hook_level = clampi(int(data.get("hook", 0)), 0, FishData.HOOKS.size() - 1)  # 旧档 → 基础钩
	inventory = []
	for e in data.get("inv", []):           # v1 存档无此字段 → 空背包
		if e is Array and e.size() >= 3 and FishData.FISH.has(str(e[0])):
			inventory.append({"id": str(e[0]), "w": float(e[1]), "v": int(e[2]),
				"q": int(e[3]) if e.size() >= 4 else 0,    # v2 三元组 → 无星级
				"lock": e.size() >= 5 and int(e[4]) == 1}) # v3 及更早 → 未锁定
	lifetime_coins = int(data.get("lt_coins", 0))
	lifetime_catches = int(data.get("lt_catches", 0))
	best_quality = int(data.get("best_q", 0))
	caught_giant = bool(data.get("giant", false))
	achievements_done = {}
	for id in data.get("ach", []):
		achievements_done[str(id)] = true
	dex = {}
	var dex_raw: Variant = data.get("dex", [])
	if dex_raw is Dictionary:                # v4+：{id: [n, w_max, big?, perf?]}（后两位 v7 新增）
		for id in dex_raw:
			if FishData.FISH.has(str(id)) and dex_raw[id] is Array and (dex_raw[id] as Array).size() >= 2:
				var e: Array = dex_raw[id]
				dex[str(id)] = {"n": int(e[0]), "w": float(e[1]),
					"big": e.size() >= 3 and int(e[2]) == 1,
					"perf": e.size() >= 4 and int(e[3]) == 1}
	elif dex_raw is Array:                   # v1~v3：仅 id 列表 → 纪录从头积累
		for id in dex_raw:
			if FishData.FISH.has(str(id)):   # 老存档里已改名/移除的鱼种直接丢弃
				dex[str(id)] = {"n": 1, "w": 0.0, "big": false, "perf": false}
	daily_order = {}
	var order_raw: Variant = data.get("daily_order", {})
	if order_raw is Dictionary:
		var od: Dictionary = order_raw
		var fish_id := str(od.get("fish", ""))
		if FishData.FISH.has(fish_id):
			daily_order = {
				"date": str(od.get("date", "")),
				"kind": str(od.get("kind", "species")),  # 旧档无 kind → 指定鱼种
				"fish": fish_id,
				"need": max(1, int(od.get("need", 1))),
				"tier": clampi(int(od.get("tier", 1)), 1, 5),
				"minw": float(od.get("minw", 1.0)),
				"done": bool(od.get("done", false)),
			}
	_opacity = float(data.get("opacity", 1.0))
	_set_opacity(_opacity)
	if bool(data.get("focus", false)):
		_set_focus(true)
	var wp: Variant = data.get("win_pos", null)
	if wp is Array and wp.size() >= 2:
		_saved_win_pos = Vector2i(int(wp[0]), int(wp[1]))
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
		var c := FishData.roll_catch(rng, rod_level, bait_level)
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
