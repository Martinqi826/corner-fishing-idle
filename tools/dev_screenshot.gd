extends SceneTree
## 开发工具：引擎内视口截图（读渲染纹理，带 alpha，可验证透明）。
## 运行: godot_console --path . -s tools/dev_screenshot.gd   （注意：不能 --headless，无视口）

const OUT_DIR := "res://docs/img"

var _main: Node


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	_main = load("res://main.tscn").instantiate()
	_main.save_enabled = false  # 截图实例不读不写真实存档
	root.add_child(_main)
	for i in 30:
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# 1) 场景 + 按钮 + 一次上鱼反馈
	_main.coins = 1234
	_main._update_hud()
	_main._toast("传说！钓到 锦鲤（3.20kg）", 3.0, FishData.TIER_COLORS[4])
	_main._popup("锦鲤 3.20kg", _main.painter.bobber_pos() + Vector2(-22, -8), FishData.TIER_COLORS[4])
	await _settle(2)
	_snap("scene.png")

	# 2) 背包页签（先钓几条入包）
	for i in 6:
		_main._do_catch()
	_main._catch_tab = 0
	_main._open_panel("catch")
	await _settle(2)
	_snap("panel_bag.png")

	# 2b) 图鉴页签
	_main._catch_tab = 1
	_main._open_panel("catch")
	await _settle(2)
	_snap("panel_dex.png")

	# 3) 升级面板
	_main._open_panel("rod")
	await _settle(2)
	_snap("panel_rod.png")

	quit()


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _snap(filename: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/" + filename)
	print("SNAP %s size=%s" % [filename, str(img.get_size())])
