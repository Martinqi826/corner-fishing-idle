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
	_main.seen_intro = true
	_main._close_panel()  # 关掉首启引导，场景展示图保持干净

	# 1) 场景 + 按钮 + 一次上鱼反馈
	_main.coins = 1234
	_main._update_hud()
	_main._toast("传说！钓到 锦鲤（3.20kg）", 3.0, FishData.TIER_COLORS[4])
	_main._popup("锦鲤 3.20kg", _main.painter.position + _main.painter.bobber_pos() + Vector2(-22, -8), FishData.TIER_COLORS[4])
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

	# 2c) 鱼种详情卡（点鲤鱼，带真实照片）
	_main._detail_fish = "carp"
	_main._open_panel("fishdetail")
	await _settle(2)
	_snap("panel_fishdetail.png")

	# 3) 升级面板
	_main._open_panel("rod")
	await _settle(2)
	_snap("panel_rod.png")

	# 3a) 设置页（含帧率 30/60/90/120 选择器）
	_main.max_fps = 60
	_main._catch_tab = 8
	_main._open_panel("catch")
	await _settle(2)
	_snap("panel_settings.png")

	# 3b) 多钓点：解锁全部 → 钓点页签 + 切到静水湖泊看 HUD 钓点角标
	_main.lifetime_catches = 400
	_main._refresh_unlocks()
	_main._catch_tab = 5
	_main._open_panel("catch")
	await _settle(2)
	_snap("panel_spot.png")
	# 鱼缸页（活水族箱）：放几条含变体的鱼进缸，展示游动 + 鎏金/七彩光晕 + 上架列表
	for i in 4:
		_main._do_catch()
	_main.display = [
		{"id": "koi", "w": 6.2, "v": 1600, "q": 2, "lock": false, "var": 3},
		{"id": "kaluga", "w": 120.0, "v": 9000, "q": 1, "lock": false, "var": 2},
		{"id": "mandarin", "w": 2.4, "v": 180, "q": 0, "lock": false, "var": 1},
		{"id": "bass", "w": 2.1, "v": 110, "q": 1, "lock": false, "var": 0},
	]
	_main._catch_tab = 6
	_main._open_panel("catch")
	await _settle(30)  # 让缸里的鱼游开、光晕脉动起来再拍
	_snap("panel_decor.png")
	_main._close_panel()
	_main._switch_spot("still_lake")
	_main._fire_event("morning_fog")  # 让 HUD 角标显示「静水湖泊 · 晨雾」
	_main._update_hud()
	await _settle(2)
	_snap("scene_lake.png")
	_main.active_event = ""
	_main._switch_spot("coast_pier")
	_main._fire_event("tide_in")  # 「海岸码头 · 涨潮」
	_main._update_hud()
	await _settle(2)
	_snap("scene_coast.png")
	_main.active_event = ""
	_main._switch_spot("river_bend")
	# 昼夜：强制黄昏，验证时段底图 + 场景染色 + HUD「· 黄昏」
	_main.day_phase = "dusk"
	_main._apply_phase()
	_finish_spot_fade()   # 截图工具：跳过 90s 慢淡入，直接呈现目标时段底图
	_main._update_hud()
	await _settle(2)
	_snap("scene_dusk.png")
	_main.day_phase = Weather.current_phase()
	_main._apply_phase()
	_finish_spot_fade()
	_main._update_hud()

	# 4) 动态层：强制小动物事件（中段全亮）+ 涟漪帧动画
	_main._close_panel()
	_main.painter._start_wild("rabbit")
	_main.painter._wild_t = _main.painter._wild_dur * 0.5
	_main.painter.add_ripple(_main.painter.bobber_pos(), 28.0)
	await _settle(4)
	_snap("scene_dynamic.png")

	# 4b) 渔夫情绪 + 桌面宠物：触发欢呼 + 宠物扒拉，拍一帧（Task 4）
	_main.painter.fisher_cheer()
	_main.painter.pet_react("paw")
	await _settle(6)
	_snap("scene_pet_cheer.png")

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


## 立即结束昼夜底图 crossfade（截图工具需要静帧呈现目标时段，不等 90s 慢淡入）。
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
