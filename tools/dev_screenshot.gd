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
	root.add_child(_main)
	for i in 30:
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	# 1) 场景 + 按钮 + 一次上鱼反馈
	_main.coins = 1234
	_main._update_hud()
	_main._toast("传说！钓到 锦鲤（+320）", 3.0, FishData.RARITY_COLORS[3])
	_main._popup("锦鲤 +320", _main.painter.bobber_pos() + Vector2(-18, -8), FishData.RARITY_COLORS[3])
	await _settle(2)
	_snap("scene.png")

	# 2) 打开鱼篓图鉴（先钓几条填充图鉴）
	for i in 30:
		_main._do_catch()
	_main._open_panel("catch")
	await _settle(2)
	_snap("panel_catch.png")

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
