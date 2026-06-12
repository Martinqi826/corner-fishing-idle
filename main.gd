extends Node2D
## 角落垂钓 · 主控
## 职责：透明角落窗形态 + 挂机钓鱼状态机 + 经济 + 即时反馈（后续接存档/离线/面板）。

@onready var painter: Node2D = $ScenePainter
@onready var ui_root: Control = $HUD/Root
@onready var coins_label: Label = $HUD/Root/Coins
@onready var toast_label: Label = $HUD/Root/Toast

# 可交互区：右下角可见场景 + 按钮；其余透明区点击穿透到桌面。
const INTERACT_RECT := Rect2(160, 148, 360, 252)
# 合成主图里三按钮的中心（与 corner_scene_winter_base.png 烤进的按钮对齐）。
const COMPOSITE_BTNS := [[Vector2(460, 384), "catch"], [Vector2(481, 384), "rod"], [Vector2(502, 384), "set"]]

# —— 钓鱼状态机 ——
enum {ST_WAIT, ST_BITE}
var _state := ST_WAIT
var _state_t := 0.0
var _started := false

# —— 存档数据 ——
var coins := 0
var rod_level := 1
var lifetime_coins := 0
var lifetime_catches := 0
var dex := {}  # id -> true（钓到过的鱼）

var save_enabled := true
var rng := RandomNumberGenerator.new()
var _font: SystemFont
var _msg_id := 0
var _panel: Control = null
var _panel_kind := ""
var _opacity := 1.0

const SAVE_PATH := "user://corner_fishing_save.json"
const OFFLINE_CAP := 8.0 * 3600.0     # 离线最多结算 8 小时
const OFFLINE_EFFICIENCY := 0.5       # 离线效率 50%
var _save_t := 10.0
var _pending_offline := ""


func _ready() -> void:
	rng.randomize()
	Engine.max_fps = 30  # 挂件省电
	get_tree().set_auto_accept_quit(false)  # 退出前存档
	_setup_theme()
	_setup_window()
	_load_save()
	_build_buttons()
	_update_hud()
	_begin_wait()
	_started = true
	if _pending_offline != "":
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
	_place_corner()
	_update_passthrough()


func _place_corner() -> void:
	var scr := DisplayServer.window_get_current_screen()
	var usable := DisplayServer.screen_get_usable_rect(scr)
	var ws := DisplayServer.window_get_size()
	DisplayServer.window_set_position(Vector2i(
		usable.position.x + usable.size.x - ws.x,
		usable.position.y + usable.size.y - ws.y))


func _update_passthrough() -> void:
	var r := INTERACT_RECT
	DisplayServer.window_set_mouse_passthrough(PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]))


# ============================ 钓鱼循环 ============================

func _process(delta: float) -> void:
	if not _started:
		return
	if save_enabled:
		_save_t -= delta
		if _save_t <= 0.0:
			_save_t = 10.0
			_save()
	_state_t -= delta
	match _state:
		ST_WAIT:
			painter.dip = lerpf(painter.dip, 0.0, delta * 6.0)
			if _state_t <= 0.0:
				_begin_bite()
		ST_BITE:
			painter.dip = lerpf(painter.dip, 1.0, delta * 10.0)
			if _state_t <= 0.0:
				_do_catch()


func _begin_wait() -> void:
	_state = ST_WAIT
	var w := rng.randf_range(3.5, 7.0) * maxf(0.4, 1.0 - float(rod_level - 1) * 0.06)
	_state_t = w


func _begin_bite() -> void:
	_state = ST_BITE
	_state_t = 0.9
	painter.add_ripple(painter.bobber_pos(), 22.0)


func _do_catch() -> void:
	var id := FishData.roll_fish(FishData.weights_for_rod(rod_level), rng)
	var f: Dictionary = FishData.FISH[id]
	var val := FishData.value_of(id, rng, rod_level)
	var rarity := int(f["rarity"])
	coins += val
	lifetime_coins += val
	lifetime_catches += 1
	dex[id] = true
	var col: Color = FishData.RARITY_COLORS[rarity]
	_popup("%s +%d" % [f["name"], val], painter.bobber_pos() + Vector2(-18, -8), col)
	painter.add_ripple(painter.bobber_pos(), 34.0)
	if rarity >= 2:
		_toast("%s！钓到 %s（+%d）" % [FishData.RARITY_NAMES[rarity], f["name"], val], 2.4, col)
	if rarity == 3:
		_flash()
	_update_hud()
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
	coins_label.text = "金币 %d" % coins


func _popup(text: String, pos: Vector2, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("outline_size", 3)
	l.position = pos
	l.z_index = 20
	ui_root.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", pos.y - 28.0, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.25)
	tw.tween_callback(l.queue_free)


func _toast(text: String, duration: float, color := Color.WHITE) -> void:
	_msg_id += 1
	var id := _msg_id
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
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


# 合成主图模式：按钮已烤进主图，这里只放透明命中区（带悬停高亮），点击可用、无重影。
func _build_hit_areas() -> void:
	for c in COMPOSITE_BTNS:
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(22, 26)
		b.size = Vector2(22, 26)
		b.position = (c[0] as Vector2) - Vector2(11, 13)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		var hov := StyleBoxFlat.new()
		hov.bg_color = Color(1, 1, 1, 0.16)
		hov.set_corner_radius_all(13)
		b.add_theme_stylebox_override("hover", hov)
		b.pressed.connect(_toggle_panel.bind(c[1]))
		ui_root.add_child(b)


# 程序化回退模式：纸色圆按钮（篓/竿/设）。
func _build_round_buttons() -> void:
	var defs := [["篓", "catch"], ["竿", "rod"], ["设", "set"]]
	var x := 404.0
	for d in defs:
		var b := _round_button(d[0])
		b.position = Vector2(x, 362)
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
	if _panel_kind == kind:
		_close_panel()
	else:
		_open_panel(kind)


func _open_panel(kind: String) -> void:
	_close_panel()
	var titles := {"catch": "鱼篓 · 图鉴", "rod": "鱼竿 · 升级", "set": "设置"}
	var card := _make_card(str(titles.get(kind, "")))
	var v: VBoxContainer = card.get_node("M/V")
	match kind:
		"catch": _fill_catch_log(v)
		"rod": _fill_upgrades(v)
		"set": _fill_settings(v)
	ui_root.add_child(card)
	_panel = card
	_panel_kind = kind
	_set_interactive_full(true)


func _close_panel() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	_panel_kind = ""
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


func _make_card(title: String) -> Control:
	var p := PanelContainer.new()
	p.position = Vector2(64, 36)
	p.custom_minimum_size = Vector2(392, 312)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.93, 0.87, 0.97)
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.5, 0.5, 0.45, 0.6)
	p.add_theme_stylebox_override("panel", sb)
	var m := MarginContainer.new()
	m.name = "M"
	for side in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 16)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", 9)
	m.add_child(v)
	# 标题行 + 关闭
	var hb := HBoxContainer.new()
	var tl := Label.new()
	tl.text = title
	tl.add_theme_font_size_override("font_size", 18)
	tl.add_theme_color_override("font_color", Color(0.25, 0.25, 0.22))
	hb.add_child(tl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	var cb := Button.new()
	cb.text = "×"
	cb.flat = true
	cb.focus_mode = Control.FOCUS_NONE
	cb.add_theme_color_override("font_color", Color(0.4, 0.4, 0.38))
	cb.pressed.connect(_close_panel)
	hb.add_child(cb)
	v.add_child(hb)
	return p


func _fill_catch_log(v: VBoxContainer) -> void:
	var stat := Label.new()
	stat.text = "终身渔获 %d　终身金币 %d　图鉴 %d/%d" % [
		lifetime_catches, lifetime_coins, dex.size(), FishData.FISH.size()]
	stat.add_theme_color_override("font_color", Color(0.35, 0.35, 0.32))
	v.add_child(stat)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 7)
	var ids := FishData.FISH.keys()
	ids.sort_custom(func(a, b): return int(FishData.FISH[a]["rarity"]) < int(FishData.FISH[b]["rarity"]))
	for id in ids:
		var f: Dictionary = FishData.FISH[id]
		var lbl := Label.new()
		if dex.has(id):
			lbl.text = "%s·%s" % [FishData.RARITY_NAMES[int(f["rarity"])], f["name"]]
			lbl.add_theme_color_override("font_color", FishData.RARITY_COLORS[int(f["rarity"])])
		else:
			lbl.text = "？？？"
			lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.58))
		grid.add_child(lbl)
	v.add_child(grid)


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
	desc.custom_minimum_size = Vector2(360, 0)
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
	btn.pressed.connect(_try_upgrade_rod)
	v.add_child(btn)


func _fill_settings(v: VBoxContainer) -> void:
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
	reset.pressed.connect(_place_corner)
	v.add_child(reset)
	var quit := Button.new()
	quit.text = "退出游戏"
	quit.focus_mode = Control.FOCUS_NONE
	quit.pressed.connect(_quit_game)
	v.add_child(quit)


func _rod_cost() -> int:
	return int(round(40.0 * pow(1.8, rod_level - 1)))


func _try_upgrade_rod() -> void:
	var cost := _rod_cost()
	if coins < cost:
		_toast("金币不足", 1.5, Color(1.0, 0.5, 0.4))
		return
	coins -= cost
	rod_level += 1
	_update_hud()
	_toast("鱼竿升到 Lv.%d！" % rod_level, 2.0, Color(0.5, 0.8, 1.0))
	_open_panel("rod")


func _set_opacity(val: float) -> void:
	_opacity = val
	painter.modulate.a = val
	coins_label.modulate.a = val


# ============================ 存档 / 离线 ============================

func _save() -> void:
	if not save_enabled:
		return
	var data := {
		"coins": coins,
		"rod_level": rod_level,
		"lt_coins": lifetime_coins,
		"lt_catches": lifetime_catches,
		"dex": dex.keys(),
		"opacity": _opacity,
		"ts": Time.get_unix_time_from_system(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data))


func _load_save() -> void:
	if not save_enabled or not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not (data is Dictionary):
		return
	coins = int(data.get("coins", 0))
	rod_level = max(1, int(data.get("rod_level", 1)))
	lifetime_coins = int(data.get("lt_coins", 0))
	lifetime_catches = int(data.get("lt_catches", 0))
	dex = {}
	for id in data.get("dex", []):
		dex[str(id)] = true
	_opacity = float(data.get("opacity", 1.0))
	_set_opacity(_opacity)
	# 离线收益
	var elapsed: float = Time.get_unix_time_from_system() - float(data.get("ts", 0))
	elapsed = clampf(elapsed, 0.0, OFFLINE_CAP)
	if elapsed > 30.0:
		var gain := _offline_gain(elapsed)
		if gain > 0:
			coins += gain
			lifetime_coins += gain
			_pending_offline = "离线 %s，挂竿钓得 %d 金币" % [_fmt_dur(elapsed), gain]


## 离线渔获 = (离线时长 / 平均上鱼间隔) × 单条期望金币 × 离线效率
func _offline_gain(elapsed: float) -> int:
	var wait_factor: float = maxf(0.4, 1.0 - float(rod_level - 1) * 0.06)
	var avg_interval := 5.25 * wait_factor + 0.9
	var catches := elapsed / avg_interval
	return int(catches * _expected_value() * OFFLINE_EFFICIENCY)


## 单条鱼的期望金币（按当前鱼竿权重 + 增值）
func _expected_value() -> float:
	var w := FishData.weights_for_rod(rod_level)
	var total := 0.0
	for r in w:
		total += w[r]
	var count_by_rarity := {0: 0, 1: 0, 2: 0, 3: 0}
	for id in FishData.FISH:
		count_by_rarity[int(FishData.FISH[id]["rarity"])] += 1
	var ev := 0.0
	for id in FishData.FISH:
		var f: Dictionary = FishData.FISH[id]
		var r := int(f["rarity"])
		var p: float = (float(w[r]) / total) / float(count_by_rarity[r])
		ev += p * (float(f["vmin"]) + float(f["vmax"])) * 0.5
	return ev * (1.0 + float(rod_level - 1) * 0.08)


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
