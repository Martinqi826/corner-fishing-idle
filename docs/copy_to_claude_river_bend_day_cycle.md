# Copy To Claude: River Bend Day Cycle Integration

请只实现默认钓点 `river_bend` 的日夜交替案例，不要扩展到其他钓点，不要重做美术资源。

我已经准备好正式运行时美术资源：

```text
assets/art/background/spot_river_bend_dawn.png
assets/art/background/spot_river_bend_day.png
assets/art/background/spot_river_bend_dusk.png
assets/art/background/spot_river_bend_night.png
```

参考/源文件在：

```text
assets/art/source/scenic_variants/river_bend_cycle/
```

请修改代码实现：

1. `scene_painter.gd`

让 `set_spot(bg_key)` 和昼夜阶段共同决定背景。加载顺序必须是：

```text
res://assets/art/background/spot_<bg_key>_<phase>.png
res://assets/art/background/spot_<bg_key>.png
res://assets/art/background/spot_river_bend.png 或现有 _base
```

其中 `phase` 是 `dawn/day/dusk/night`。

要求：

- 缺任意时段图时不能报错、不能黑屏，必须回退现有 `spot_<bg_key>.png`。
- 不要覆盖现有 `spot_river_bend.png`。
- 保持现有渔夫、宠物、灯笼、钓线、浮漂、涟漪、水光、雾、雪、灯光呼吸等叠加层顺序。
- 背景切换不要硬切。请做一个慢 crossfade，建议 60 到 120 秒，可先用常量 `SPOT_FADE_DUR := 90.0`。
- 如果实现 crossfade 太复杂，先做可回退的加载逻辑，但请把 TODO 标清楚。

2. `weather.gd` / `main.gd`

保留现有 `Weather` 四阶段，不要这次改成完整游戏内时间循环。

在 `main.gd` 的 `_apply_phase()` 里，把当前 `day_phase` 传给 `ScenePainter`，例如：

```gdscript
painter.set_phase_tint(Weather.tint(day_phase), day_phase)
```

如果你需要保持旧签名兼容，可以让 `set_phase_tint(c: Color, phase_id := "")` 第二个参数默认空串。

3. `spot_data.gd`

给 `river_bend` 添加招牌景观：

```gdscript
"best_view": {
	"phase": "dawn",
	"name": "晨雾日出",
	"asset_phase": "dawn"
}
```

增加安全 helper：

```gdscript
static func best_view(id: String) -> Dictionary:
	return get_spot(id).get("best_view", {})

static func scenic_name(id: String, phase: String) -> String:
	var bv := best_view(id)
	if not bv.is_empty() and str(bv.get("phase", "")) == phase:
		return str(bv.get("name", ""))
	return ""
```

4. `main.gd` HUD

在 `_update_spot_chip()` 中，如果当前时段命中钓点招牌景观，就显示景观名：

```gdscript
var scenic := SpotData.scenic_name(current_spot, day_phase)
if scenic != "":
	txt += " · " + scenic
```

例如黎明时显示：

```text
新手河湾 · 黎明 · 晨雾日出
```

5. 验证

请跑：

```text
godot --headless --import
godot --headless -s tools/validate_game.gd
```

如果 Godot 自动生成 `.import` 文件，请保留这些新增背景图对应的 `.import`。

请新增或更新测试覆盖：

- `SpotData.scenic_name("river_bend", "dawn") == "晨雾日出"`。
- `SpotData.scenic_name("river_bend", "day") == ""`。
- `ScenePainter.set_spot("river_bend")` 在时段图缺失时仍可回退。
- `set_phase_tint(Weather.tint("dawn"), "dawn")` 不会报错。
- 运行时四张图存在时，`river_bend` 能随 `dawn/day/dusk/night` 加载不同背景。

不要做：

- 不要把普通鱼硬锁到某个时间。
- 不要改存档结构。
- 不要扩展湖泊/码头。
- 不要生成新美术。
- 不要覆盖已有基础背景。
