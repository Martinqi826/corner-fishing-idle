shader_type canvas_item;
// 场景整体羽化遮罩：以右下角艺术核心为中心，透明度沿椭圆半径平滑递减到 0，
// 让窗口边界"渐进消散"融入桌面，而不是清晰的矩形切边。
// 用屏幕像素坐标而非 UV：所有 draw 调用（含带偏移的雾/雪层）按窗口位置统一淡出。

uniform vec2 center = vec2(478.0, 388.0);  // 椭圆中心（画布像素，靠右下角）
uniform vec2 radii = vec2(350.0, 270.0);   // 椭圆半径
uniform float core = 0.55;                  // r < core 完全不透明；core→1.0 平滑过渡到全透明

void fragment() {
	vec2 scr = SCREEN_UV / SCREEN_PIXEL_SIZE;
	float r = length((scr - center) / radii);
	COLOR.a *= 1.0 - smoothstep(core, 1.0, r);
}
