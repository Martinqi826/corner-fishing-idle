# 给 Claude：接入小馋猫正式 sprite 资源

请在当前 Godot 项目里接入一组新的“小馋猫”宠物 sprite，但不要改玩法逻辑。目标是把 `scene_painter.gd` 里现有程序化占位猫，替换为真实 PNG 贴图绘制，并保留程序化绘制作为资源缺失时的 fallback。

这组资源已经从高质量绿幕概念图抠透明并切帧，不要再用程序化形状、低质重绘或 SVG 占位替代它们。

## 已新增资源

运行时资源：

- `res://assets/art/pets/cat_idle.png`
- `res://assets/art/pets/cat_blink.png`
- `res://assets/art/pets/cat_paw.png`
- `res://assets/art/pets/cat_steal.png`
- `res://assets/art/pets/cat_sleep.png`
- `res://assets/art/pets/cat_sprite_sheet.png`

预览/源稿：

- `assets/art/source/pets/cat_v1/cat_sprite_contact_sheet.png`
- `assets/art/source/pets/cat_v1/cat_sprite_sheet.png`
- `assets/art/source/pets/cat_v1/cat_sprite_source_green.png`
- `assets/art/source/pets/cat_v1/cat_sprite_sheet_transparent_full.png`

每个单帧 PNG 是 `96x96`、透明背景。`cat_sprite_sheet.png` 是横向 5 帧，顺序为 `idle / blink / paw / steal / sleep`。

## 硬约束

1. 只改小馋猫视觉接入，不新增宠物系统。
2. 不要改 `main.gd` 的宠物玩法数值：`PET_STEAL_CHANCE`、`PET_STEAL_MAX_VALUE`、`pet_steals`、`_maybe_pet_steal()`、`_pet_steal_cheapest()` 都保持不变。
3. 不要改成就逻辑，`achievements.gd` 里的 `cat_tax` 保持不变。
4. 保留现有 `ScenePainter.pet_react(kind)` 接口，仍然支持 `paw` 和 `steal`。
5. 保留现有 `pet_anchor`，不要重排场景主构图。
6. 如果任意宠物贴图加载失败，应该回退到现有程序化猫，不要让场景黑屏或报错。

## 建议实现

在 `scene_painter.gd` 里新增宠物贴图表，接近现有宠物变量处：

```gdscript
const PET_SPRITE_SCALE := 0.38
var _pet_tex: Dictionary = {}
var _pet_paths := {
	"idle": "res://assets/art/pets/cat_idle.png",
	"blink": "res://assets/art/pets/cat_blink.png",
	"paw": "res://assets/art/pets/cat_paw.png",
	"steal": "res://assets/art/pets/cat_steal.png",
	"sleep": "res://assets/art/pets/cat_sleep.png",
}
```

在 `_ready()` 中用现有 `_tex(path)` helper 加载：

```gdscript
for k in _pet_paths.keys():
	var tx := _tex(_pet_paths[k])
	if tx != null:
		_pet_tex[k] = tx
```

把现有 `_draw_pet()` 的程序化绘制内容改名为 `_draw_pet_proc()`，然后新建一个轻薄的 `_draw_pet()` 入口：

```gdscript
func _draw_pet() -> void:
	var key := _pet_state_key()
	if _pet_tex.has(key):
		_draw_pet_sprite(_pet_tex[key])
	else:
		_draw_pet_proc()
```

状态选择建议：

```gdscript
func _pet_state_key() -> String:
	if pet_action == "steal":
		return "steal"
	if pet_action == "paw":
		return "paw"
	if ctx_night and ctx_idle:
		return "sleep"
	if _pet_blink_t < 0.14:
		return "blink"
	return "idle"
```

绘制时保持底部中心对齐 `pet_anchor`，这样不会破坏现有布局：

```gdscript
func _draw_pet_sprite(tex: Texture2D) -> void:
	var sz := Vector2(tex.get_size()) * PET_SPRITE_SCALE
	var offset := Vector2(0, sin(t * 1.7) * 0.7)
	if pet_action != "":
		var pp: float = 1.0 - _pet_action_t / maxf(_pet_action_dur, 0.001)
		if pet_action == "paw":
			offset.y -= sin(pp * PI) * 1.8
		elif pet_action == "steal":
			offset.x += sin(pp * PI) * 2.2
	var top_left := pet_anchor + offset - Vector2(sz.x * 0.5, sz.y)
	draw_texture_rect(tex, Rect2(top_left, sz), false)
```

`sleep` 只在 `ctx_night && ctx_idle` 且没有动作时出现；上鱼挥爪、偷鱼动作优先级更高。

## 验收标准

1. 运行时默认能看到小馋猫 PNG，而不是程序化椭圆猫。
2. 上鱼触发 `pet_react("paw")` 时显示 `cat_paw.png`，动作结束后回到 idle。
3. 偷鱼触发 `pet_react("steal")` 时显示 `cat_steal.png`，不要改变偷鱼概率和筛选规则。
4. 夜间且玩家久未操作时可显示 `cat_sleep.png`，但不能影响钓鱼流程。
5. 临时重命名任一宠物 PNG 后，游戏仍可 fallback 到程序化猫，不崩溃。

## 请运行验证

资源接入后请执行：

```powershell
godot --headless --editor --path . --quit
godot --headless -s tools/validate_game.gd
```

最后请汇报：

- 修改了哪些文件。
- 是否生成了 `.import` 文件。
- 上述验证命令是否通过。
- 是否保持 `main.gd` 玩法逻辑不变。
