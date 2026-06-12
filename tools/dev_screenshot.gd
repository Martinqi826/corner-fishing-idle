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

	# 4) 动态层：强制小动物事件（中段全亮）+ 涟漪帧动画
	_main._close_panel()
	_main.painter._start_wild("rabbit")
	_main.painter._wild_t = _main.painter._wild_dur * 0.5
	_main.painter.add_ripple(_main.painter.bobber_pos(), 28.0)
	await _settle(4)
	_snap("scene_dynamic.png")

	# 5) 动效校验：间隔 3 秒拍两帧，供外部做像素差对比（证明肉眼可见的动态）
	await _settle(6)
	_snap("motion_a.png")
	await _settle(90)  # 30fps × 90 帧 = 3 秒
	_snap("motion_b.png")

	# 6) UI 对位校验：按钮命中区/落水点画红色标记，美术更新后跑一遍核对是否错位
	for k in ["catch", "rod", "set"]:
		var m := ColorRect.new()
		m.color = Color(1, 0, 0, 0.4)
		m.size = Vector2(30, 32)
		m.position = (_main.btn_centers[k] as Vector2) - Vector2(15, 16)
		_main.ui_root.add_child(m)
	var bp := ColorRect.new()
	bp.color = Color(0, 1, 0, 0.5)
	bp.size = Vector2(8, 8)
	bp.position = _main.painter.bite_point - Vector2(4, 4)
	_main.ui_root.add_child(bp)
	await _settle(2)
	_snap("ui_align_check.png")

	quit()


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _snap(filename: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(OUT_DIR + "/" + filename)
	print("SNAP %s size=%s" % [filename, str(img.get_size())])
