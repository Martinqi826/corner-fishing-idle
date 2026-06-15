# 通宵迭代总结 · 2026-06-15

自主通宵开发。基线 tag `睡前基线-2026-06-15`（已 push）+ 桌面完整备份
`C:\Users\Martin\Desktop\角落垂钓-睡前备份-2026-06-15\`（含 .git + 存档快照）。
全程每里程碑 commit+push origin main，回归 0 失败。

## 一、做了什么

| # | 里程碑 | 关键文件 | 提交 |
|---|---|---|---|
| 0 | 回退点：tag + 桌面备份 + 接入 Codex 钓点背景（静水湖/海岸码头水彩图） | assets/art/background/spot_*.png | `4580c1b` |
| 1 | **重构①** 抽出 ui_panels.gd（30 个面板/页签/样式函数），main.gd 2596→1475 | ui_panels.gd, main.gd | `4d18c7c` |
| 2 | **重构②** 抽出 events.gd（随机事件管理器 7 函数） | events.gd | `4e99256` |
| 3 | **重构③** 抽出 spots.gd（钓点控制/鱼池/解锁/切换 8 函数） | spots.gd | `90e13ce` |
| 4 | **重构④** 抽出 orders.gd（订单/周目标/今日统计 20 函数），main.gd→1194 | orders.gd | `639490f` |

## 二、重构方式（行为零变化）

- 统一「静态函数 + 主节点 g」模式（与既有 SaveSystem 一致）；为支持类型推断，main.gd
  加 `class_name CornerFishing`，各模块函数签名 `g: CornerFishing`。
- main.gd 留薄壳 wrapper（`func _foo(): Module.foo(self)`），保持测试 / ui_panels / 主控
  原有 `g._foo()` 调用契约不变 → 零行为变化。
- 保留在 main 的工具：_fish_icon/_generic_fish/_tier_color/_ui_tier_color/_sorted_bag_indices
  （被测试/逻辑跨模块引用）。
- 成果：main.gd 2596 → **1194 行**（减半）；UI/事件/钓点/订单四大碰撞面出 main，
  为并行铺功能扫清车道。

## 三、测试结果

- `godot --headless -s tools/validate_game.gd` → **0 失败**（每次重构后均跑）。
- `godot --path . -s tools/dev_screenshot.gd` → 各面板渲染正常、无溢出/错位
  （panel_rod/panel_bag/panel_spot/panel_dex + scene_lake/scene_coast）。

## 四、模块结构（重构后）

| 文件 | 职责 |
|---|---|
| main.gd (`CornerFishing`) | 透明窗/拖动、钓鱼状态机、HUD/chips、卖鱼/升级动作、成就、存档/离线、薄壳 wrapper |
| ui_panels.gd (`UIPanels`) | 所有面板/页签/卡片/样式构建 |
| events.gd (`Events`) | 随机事件管理器（EventData 驱动） |
| spots.gd (`Spots`) | 钓点鱼池/运气增值/解锁/切换/订单候选并集 |
| orders.gd (`Orders`) | 每日订单/周目标/今日统计 |
| fish_data / spot_data / event_data / achievements / save_system / scene_painter / audio_manager | 既有数据/系统模块 |

## 五、灵感来源 / 待办

- 长线 + 公平 F2P + 挂机轻操作 三目标的调研报告见
  `docs/fishing-design-inspiration-20260614.html`（现实垂钓 + 市面钓鱼游戏横评 + 对本项目启示）。
- **下一步（并行铺功能）**：装饰/陈列系统（Chillquarium 式，新文件 decoration.gd，最契合桌面摆件
  本质，健康非数值长线 + 未来外观变现点）、更多鱼种与图鉴深度、节日/天气、手感打磨。
- **待用户拍板（已记录、未擅自做）**：自动卖鱼/背包扩容等付费点——见
  `docs/fishing-design-inspiration-20260614.html` 第三部分的风险评估与替代方案。

## 六、如何回退到睡前基线

```sh
cd E:\claude\corner-fishing-idle
git reset --hard 睡前基线-2026-06-15      # 已 push，安全
```
或用桌面完整备份 `角落垂钓-睡前备份-2026-06-15\`（含 .git 与存档快照）。
存档在 `user://`，向后兼容，回退代码不动存档。

## 七、提交列表（睡前基线之后）

```
639490f 重构④ orders.gd（main 2596→1194）
90e13ce 重构③ spots.gd
4e99256 重构② events.gd
4d18c7c 重构① ui_panels.gd（main 2596→1475）
4580c1b 接入 Codex 多钓点背景美术
```
