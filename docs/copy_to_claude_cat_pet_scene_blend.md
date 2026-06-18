# 给 Claude：让小馋猫融入雪景默认钓点

当前问题：橘猫本身好看，但在游戏里像贴上去的独立素材，主要因为颜色太暖太亮、脚底没有被场景接住、比例略抢眼。请只处理宠物视觉融入，不改宠物玩法。

## 已更新资源

当前运行时路径已经换成“雪景融合版”：

- `res://assets/art/pets/cat_idle.png`
- `res://assets/art/pets/cat_blink.png`
- `res://assets/art/pets/cat_paw.png`
- `res://assets/art/pets/cat_steal.png`
- `res://assets/art/pets/cat_sleep.png`
- `res://assets/art/pets/cat_sprite_sheet.png`

这些 PNG 已做过：

- 降低饱和度和亮度。
- 加轻微冷灰环境光。
- 保留一点灯笼侧暖光。
- 在图内烘焙了很轻的脚底接触阴影。

源稿/对照：

- `assets/art/source/pets/cat_v1/cat_scene_blend_contact_sheet.png`
- `assets/art/source/pets/cat_v1/cat_scene_blend_final_only.png`
- `assets/art/source/pets/cat_v1/warm_runtime_before_scene_blend/`：未处理暖色原版备份。
- `assets/art/source/pets/cat_v1/scene_blend_final/`：当前融合版备份。

另外有一个可选软阴影资源：

- `res://assets/art/pets/cat_shadow_soft.png`

注意：当前 `cat_*.png` 已经烘焙了轻微阴影。默认不要再额外叠 `cat_shadow_soft.png`，除非你明确决定改成代码侧阴影并避免双重阴影。

## 代码接入建议

在 `scene_painter.gd` 中保留现有 `pet_react(kind)`、`pet_action`、`_pet_blink_t` 等逻辑，只微调绘制表现。

1. 比例建议从 `0.38` 降到 `0.34 ~ 0.36`。截图里猫比环境更“贴纸”的一部分原因是略大且太亮。

```gdscript
const PET_SPRITE_SCALE := 0.35
```

2. 继续以 `pet_anchor` 做底部中心对齐，但如果猫脚底悬浮，优先把绘制 offset 下移 `1 ~ 2px`，不要大幅改构图。

```gdscript
var offset := Vector2(0, sin(t * 1.7) * 0.5 + 1.0)
```

3. 绘制时可以用很轻的 modulate 降低贴纸感，但不要再强烈压色，因为 PNG 已经做过场景融合。

```gdscript
draw_texture_rect(tex, Rect2(top_left, sz), false, Color(0.96, 0.98, 1.0, 0.96))
```

如果实际截图仍然偏灰，就把 modulate 改回 `Color(1, 1, 1, 1)`；如果仍然偏亮，再降到 `Color(0.92, 0.94, 0.96, 0.96)`。

4. 绘制顺序要让宠物吃到场景氛围层。也就是说小馋猫应该在 `_draw_phase_tint()`、雾、雪粒、灯光呼吸等场景叠层之前绘制，不要放到最后当 UI 贴图画。

理想顺序接近：

```gdscript
draw background
_draw_fisher()
_draw_pet()
_draw_lantern()
_draw_fishing_line()
_draw_mist_layer()
_draw_shimmer_layer()
_draw_snow_layer()
_draw_phase_tint()
...
_draw_glow_layer()
```

5. 如果想改成代码侧阴影，不要用图内烘焙阴影版本再叠阴影。可选方案是改用 warm 原版 + `cat_shadow_soft.png`，但当前更推荐直接使用已融合的运行时 PNG。

## 不要改

- 不要改 `main.gd` 的 `PET_STEAL_CHANCE`、`PET_STEAL_MAX_VALUE`、`pet_steals`。
- 不要改 `_maybe_pet_steal()` 和 `_pet_steal_cheapest()`。
- 不要改成就 `cat_tax`。
- 不要新增宠物养成系统。
- 不要把猫重新画成程序化椭圆或低质 SVG。

## 验收标准

1. 默认雪景钓点里，猫仍然可爱，但不应该比灯笼和渔夫更亮更抢眼。
2. 猫脚底要和木桥/雪地有接触感，不能像悬浮贴纸。
3. 夜间/雾雪/昼夜 tint 应该覆盖猫，不能把猫作为 UI 层绕过场景氛围。
4. `paw`、`steal`、`sleep` 状态仍然正确显示。
5. 不出现双重阴影、绿边、透明边框或导入报错。

## 验证

请运行：

```powershell
godot --headless --editor --path . --quit
godot --headless -s tools/validate_game.gd
```

然后截一张默认雪景钓点截图，重点看猫和渔夫、灯笼、桥面的明度关系。
