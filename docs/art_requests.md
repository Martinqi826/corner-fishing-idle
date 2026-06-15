# 美术需求清单（驱动 Codex 生成）

工程侧（Claude）负责逻辑与接入；美术（Codex）按本清单产出。统一风格：**安静、冬日、水彩/淡墨、桌面挂件、低干扰**，柔和不抢眼，避免高饱和与生硬描边。
当前游戏逻辑用现有资源已可完整运行；下列为"锦上添花/未来系统"所需，按优先级排列。

> **给 Codex 的统一美术要求（务必遵守）**：风格必须匹配现有
> `assets/art/background/corner_scene_winter_base.png`——安静、冬日、水彩/淡墨、桌面挂件、
> 低饱和、**右下角构图、左上透明羽化**。**不要**生成厚重矩形背景，**不要**把 UI 按钮画进背景，
> **不要**高饱和卡通风。背景统一 **520×400 透明 PNG**，绘于场景右下角，左上向透明羽化。

## P0 · 多钓点资源（当前最高优先级 — 多钓点系统已上线，缺图按回退运行）

多钓点系统（新手河湾 / 静水湖泊 / 海岸码头）已实现并通过测试；缺图时：背景回退现有主图、
事件图标暂不显示、新鱼图标回退「按品阶通用鱼图标」。下列资源到位即自动接入（防御式加载）。

### P0-1 钓点背景（`assets/art/background/`，520×400 透明 PNG，左上羽化，无 UI）

- `spot_river_bend.png`：**沿用当前主图，不重做**（缺此文件时代码自动用 `corner_scene_winter_base.png`）。
- `spot_still_lake.png`：右下角**静水湖泊**，冬日水彩，水草丰茂、乱石/枯树根的静水湾，左上羽化透明，无 UI。
- `spot_coast_pier.png`：右下角**海岸码头/海面/小灯**（栈桥木桩、海面、桥尽头一盏小灯），水彩低干扰，左上羽化透明，无 UI。
- 接入：`scene_painter.set_spot(bg_key)` 按 `assets/art/background/spot_<bg_key>.png` 加载，缺则回退主图。

### P0-2 事件图标（`assets/art/ui/`，64×64 透明 PNG，小型水彩图标，低饱和）

- `event_fish_run.png`（鱼汛/顺水鱼群：跃动鱼群剪影）
- `event_fog.png`（晨雾/寒潮：雾气/雪花淡墨）
- `event_tide.png`（涨潮：浪涌）
- `event_crate.png`（漂流木箱：水上小木箱）
- `event_release.png`（保护鱼放流：放归的鱼+涟漪）
- 接入：`EventData.EVENTS[*].icon` 已用上述键名；HUD/钓点页将在文件到位后显示。

### P0-3 新鱼图标（`assets/art/fish/<id>.png`，与现有鱼图同风格同画幅）

缺图自动回退「按品阶通用鱼图标」（程序化品阶色小鱼剪影，已上线，不崩）。**优先**先出每个新钓点 8 个代表鱼：

- **静水湖泊（8）**：`largemouth`(大口黑鲈) `perch`(河鲈) `catfish`(鲇鱼) `bluegill`(蓝鳃太阳鱼) `yellowcheek`(鳡鱼) `eel`(鳗鲡) `wels_catfish`(六须鲇) `tilapia`(罗非鱼)
- **海岸码头（8）**：`seabass`(海鲈) `blackbream`(黑鲷) `seabream`(真鲷) `hairtail`(带鱼) `grouper`(石斑鱼) `yellowcroaker`(大黄鱼) `tuna`(金枪鱼) `sailfish`(旗鱼)
- 其余新鱼（暂用回退图标，余力再补）：
  - 湖：`icefish`(银鱼) `bitterling`(鳑鲏) `swampeel`(黄鳝)
  - 海：`sardine`(沙丁鱼) `filefish`(马面鲀) `goby`(虾虎鱼) `mackerel`(鲐鱼) `small_croaker`(小黄鱼) `mullet`(鲻鱼) `rockfish`(许氏平鲉) `flounder`(牙鲆) `conger`(海鳗) `pufferfish`(红鳍东方鲀) `spanish_mackerel`(马鲛鱼) `pomfret`(银鲳) `giant_grouper`(龙趸石斑)
- （可选）`assets/art/fish/generic_tier0.png`…`generic_tier5.png`：6 张按品阶的通用鱼图标，替代程序化回退，更精致。

## P1 · 订单类型图标（提升订单可读性）

- 用途：每日订单 4 类各一个小图标（指定鱼种 / 指定品阶 / 大物≥Wkg / 完美品质★★★），替代当前"用一条代表鱼图标"的临时做法。
- 尺寸：64×64，透明背景 PNG。
- 风格：水彩单色调小徽记（鱼篓/天平/大鱼剪影/星）。
- 路径：`assets/art/ui/order_species.png` `order_tier.png` `order_weight.png` `order_perfect.png`
- 数量：4。
- 用法：`_fill_order_tab` 标题左侧图标；HUD 订单 chip 前缀（可选）。

## P2 · 成就徽章图标（成就页质感）

- 用途：16 项成就的小徽章（或按线分组的 ~6 个通用徽章：渔获/财富/收集/品阶/品相/装备）。
- 尺寸：48×48，透明背景 PNG。
- 风格：水彩奖章/印章感，已达成亮、未达成可由代码降透明度。
- 路径：`assets/art/ui/ach_<line>.png`（如 ach_catch / ach_coin / ach_collect / ach_tier / ach_quality / ach_gear）
- 数量：6（分组方案）或 16（逐项）。
- 用法：`_ach_row` 左侧替换当前 ✓/○ 文字标记。

## P3 · 季节/天气主图变体（未来 昼夜/天气 系统）

- 用途：主场景 `corner_scene_winter_base.png` 的 黄昏 / 夜晚 / 雪天 / 晴日 变体，用于未来时间/天气循环。
- 尺寸：与现主图一致（当前 520×400 美术区，绘于 760×560 画布右下，左上羽化透明）。
- 风格：与现冬日主图同构图、同机位，仅光照/天气不同。
- 路径：`assets/art/background/corner_scene_winter_<dusk|night|snow|clear>.png`
- 数量：3~4。
- 用法：按游戏内时间在 scene_painter 切换底图（需配套羽化/锚点不变）。

## P1.5 · 陈列/装饰系统（已上线 decor.gd，现可接入美术）

- 状态：**逻辑已上线**（陈列架 5 槽 + 卖价加成 + 存档 v9 + 陈列页签）。当前用鱼图标占位，下列美术到位即可升级观感。
- 需求：
  - `assets/art/ui/decor_shelf.png`：陈列架/标本架底图（横向木架，水彩淡墨，透明背景，约 480×120），用作陈列页槽位背景。
  - `assets/art/ui/decor_slot_empty.png`：空槽位纹样（约 64×64，透明，淡描边"◇"感）。
  - （未来）桌面小景：把陈列的鱼以小标本/鱼拓形式画进场景右下角一角（与各钓点背景同风格），供 scene_painter 叠加渲染。
- 风格：与 winter_base 一致；安静水彩、低饱和、透明、低干扰。
- 用法：缺图自动回退现有"纸面卡片 + 鱼图标"实现（不阻塞）。

## P4 · 更多展示形态（未来，待立项）

- 用途：鱼拓/灯笼挂饰/可自定义摆放的桌面陈列，进一步做外观变现点（见 fishing-design-inspiration 报告）。
- 状态：方向待用户确认后再细化，不急。

## 备注

- 暂缺以上资源不阻塞逻辑：订单/成就当前用文字与代表图标可正常运行。
- Codex 产出后放入对应路径即可，工程侧会做"缺失自动回退"接入（参照 scene_painter / audio_manager 的防御式加载）。
