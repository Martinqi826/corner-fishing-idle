extends SceneTree
## 开发工具：把 AI 生成的夜景图缩放到 520×400 并落位为河湾夜景底图。
## 源图请存到 SRC 路径（任意尺寸/比例，会缩到 520×400；4:3 输入几乎无形变）。
## 运行: E:\Godot\Godot_v4.6.3-stable_win64_console.exe --path . --headless -s tools/import_night_bg.gd
## 之后必须 --import 重导，游戏才能看到新图。

const SRC := "res://assets/art/source/river_bend_night_src.png"
const DST := "res://assets/art/background/spot_river_bend_night.png"


func _init() -> void:
	var p := ProjectSettings.globalize_path(SRC)
	if not FileAccess.file_exists(p):
		push_error("找不到源图，请先把夜景图存到: " + p)
		quit()
		return
	var img := Image.load_from_file(p)
	if img == null:
		push_error("载入失败: " + p)
		quit()
		return
	var ow := img.get_width()
	var oh := img.get_height()
	img.resize(520, 400, Image.INTERPOLATE_LANCZOS)
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var err := img.save_png(ProjectSettings.globalize_path(DST))
	print("IMPORT_NIGHT_DONE err=%d  %dx%d -> 520x400  -> %s" % [err, ow, oh, DST])
	quit()
