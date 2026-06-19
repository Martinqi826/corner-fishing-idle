extends SceneTree
## 开发工具：把白天底图离线"夜化"成深靛蓝月夜（构图 100% 不变，必定与四时段/锚点对齐）。
## 做法：按亮度把像素映射到 shadow→highlight 的双色调 navy 渐变，掺少量原色避免发死。
## 这是"等 AI 锁构图夜景图"前的对齐版真夜；之后可被 img2img 版替换。
## 运行: E:\Godot\Godot_v4.6.3-stable_win64_console.exe --path . --headless -s tools/bake_night_bg.gd

const SRC := "res://assets/art/background/spot_river_bend_day.png"
const DST := "res://assets/art/background/spot_river_bend_night.png"

# 取自用户参考图的 navy 调色：最暗→最亮（月光雪）
const SHADOW := Vector3(0.06, 0.10, 0.22)
const HI := Vector3(0.50, 0.58, 0.76)
const CHROMA_KEEP := 0.12   # 掺回的原始色相比例


func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	if img == null:
		push_error("载入失败: " + SRC)
		quit()
		return
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var l: float = pow(c.r * 0.299 + c.g * 0.587 + c.b * 0.114, 1.12)
			var nr: float = lerp(SHADOW.x, HI.x, l)
			var ng: float = lerp(SHADOW.y, HI.y, l)
			var nb: float = lerp(SHADOW.z, HI.z, l)
			nr = lerp(nr, c.r * 0.50, CHROMA_KEEP)
			ng = lerp(ng, c.g * 0.55, CHROMA_KEEP)
			nb = lerp(nb, c.b * 0.70, CHROMA_KEEP)
			img.set_pixel(x, y, Color(nr, ng, nb, c.a))
	var err := img.save_png(ProjectSettings.globalize_path(DST))
	print("BAKE_NIGHT_DONE err=%d -> %s (%dx%d)" % [err, DST, w, h])
	quit()
