extends SceneTree
## 开发工具：把 AI 生成的分时段夜/昏/晨景图缩到 520×400 落位到对应底图。
## 改 JOBS 后运行: E:\Godot\Godot_v4.6.3-stable_win64_console.exe --path . --headless -s tools/import_phase_bgs.gd
## 之后必须 --import 重导。

const JOBS := [
	["res://assets/art/source/river_bend_dawn_src.png", "res://assets/art/background/spot_river_bend_dawn.png"],
	["res://assets/art/source/river_bend_dusk_src.png", "res://assets/art/background/spot_river_bend_dusk.png"],
]


func _init() -> void:
	for j in JOBS:
		var p := ProjectSettings.globalize_path(j[0])
		if not FileAccess.file_exists(p):
			push_error("缺源: " + p)
			continue
		var img := Image.load_from_file(p)
		if img == null:
			push_error("载入失败: " + p)
			continue
		var ow := img.get_width()
		var oh := img.get_height()
		img.resize(520, 400, Image.INTERPOLATE_LANCZOS)
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
		var err := img.save_png(ProjectSettings.globalize_path(j[1]))
		print("PHASE_BG_DONE err=%d  %dx%d -> %s" % [err, ow, oh, j[1]])
	quit()
