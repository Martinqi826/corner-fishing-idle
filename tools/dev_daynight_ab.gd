extends SceneTree
## 开发工具：昼夜调色 A/B 对比出图。
## 两个钓点（river_bend 有分时段手绘图 / still_lake 仅单图）× 四个时刻 × {旧平涂染色, 新连续调色}。
## 运行: E:\Godot\Godot_v4.6.3-stable_win64_console.exe --path . -s tools/dev_daynight_ab.gd （勿 --headless）
## 产物: docs/img/daynight/dn_<spot>_<tag>_<old|new>.png

const OUT_DIR := "res://docs/img/daynight"

var _main: Node


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	_main = load("res://main.tscn").instantiate()
	_main.save_enabled = false
	root.add_child(_main)
	for i in 30:
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_main.seen_intro = true
	_main._close_panel()

	var times := [
		{"tag": "0530dawn", "tod": 5.6, "phase": "dawn"},
		{"tag": "1200noon", "tod": 12.0, "phase": "day"},
		{"tag": "1845dusk", "tod": 18.75, "phase": "dusk"},
		{"tag": "2230night", "tod": 22.5, "phase": "night"},
	]
	for spot in ["river_bend", "still_lake"]:
		_main._switch_spot(spot)
		for tt in times:
			_main.painter._spot_phase = ""        # 强制重解析底图（含分时段图 + has_phase_art 标记）
			_main.day_phase = str(tt["phase"])
			_main._apply_phase()
			_finish_spot_fade()
			_main._update_hud()
			# OLD：旧的全屏平涂染色（忽略 debug_tod，按时段定色）
			_main.painter.use_grade = false
			_main.painter.debug_tod = float(tt["tod"])
			await _settle(3)
			_snap("dn_%s_%s_old.png" % [spot, tt["tag"]])
			# NEW：连续调色（按 debug_tod 取色）
			_main.painter.use_grade = true
			await _settle(3)
			_snap("dn_%s_%s_new.png" % [spot, tt["tag"]])
	print("DAYNIGHT_AB_DONE")
	quit()


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


## 立即结束昼夜底图 crossfade（截图需静帧呈现目标时段，不等 90s 慢淡入）。
func _finish_spot_fade() -> void:
	var p: Node2D = _main.painter
	if "_spot_fade" in p:
		p._spot_fade = 1.0
		p._spot_prev = null
		p.queue_redraw()


func _snap(filename: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/" + filename)
	print("SNAP %s size=%s" % [filename, str(img.get_size())])
