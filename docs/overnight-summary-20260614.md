# 通宵迭代总结 · 2026-06-14 早

睡前基线之后的自主迭代。全程：调研 → 需求 → 实现 → 无头回归(0 失败) → 截图验证 → 文档 → 独立提交。
存档全程无损迁移；游戏客户端已带全部新内容重启。

## 一、做了哪些功能（含灵感来源）

| # | 功能 | 灵感来源 | 提交 |
|---|---|---|---|
| 1 | **HUD 每日订单进度** 金币行下方常驻「订单 鲢鳙 0/4」，点击开订单页 | Stardew/Animal Crossing 每日目标常驻可见 | `4e6c8fd` |
| 2 | **鱼篓排序/筛选** 最新·价值·品阶·重量 + 只看订单鱼 | Melvor Idle 背包管理 | `d263e15` |
| 3 | **图鉴长期徽章** 每种鱼 集齐10条 / 巨物 / 完美★★★ + 进度 | Chillquarium 收集深度 + Fisch 奖杯 | `a6feb3d` |
| 4 | **多类型订单** 指定鱼种 / 指定品阶 / 大物≥Wkg / 完美品质 | Stardew 捆绑多样性 + WEBFISHING 品质 | `03ccf5a` |
| 5 | **数值平衡** 鱼竿成本 `40×1.8ⁿ`→`200×2.0ⁿ`，修复"零成本"通胀 | idle 经济曲线（成本增速 > 产出增速） | `f9d0a21` |
| 6 | **专注/安静模式** 停小动物事件 + 抑制飘字 + 场景轻微变暗 | Rusty's Retirement Focus Mode | `15cadb2` |
| — | 调研文档（6 方向）+ README/白皮书/美术需求 全面同步 | — | `e2dc11b` `508fec4` |

> 另：睡前基线提交 `97bde8f` 本身是「离线小结面板」（回屏弹时长/渔获/最值钱一条/合计可卖）。

## 二、关键文件改了什么

- `main.gd`（主控）：HUD 订单 chip（`_build_order_chip`/`_update_order_chip`）；鱼篓排序筛选（`_sorted_bag_indices` + 排序行）；图鉴徽章（`_dex_badges`，`dex` 条目加 big/perf）；订单 4 类（`_order_matches`/`_order_title`/`_order_short`/`_make_daily_order` 重构）；鱼竿成本 `_rod_cost`；专注模式（`_set_focus` + `_popup` 守卫 + 设置开关）。
- `scene_painter.gd`：`set_quiet()` 专注模式停 wildlife。
- `fish_data.gd`：未改（鱼/品阶/星级/鱼饵沿用）。
- `tools/validate_game.gd`：新增 排序/筛选、多类型订单、图鉴徽章往返、专注模式 用例。
- `tools/balance_probe.gd`：**新增** 数值平衡探针（产出曲线/升级回本，只读）。
- `docs/`：`overnight-research-20260614.md`（调研）、`art_requests.md`（美术需求）、`README.md`、`project_overview.html`（白皮书）同步。

## 三、测试结果

- `godot --headless -s tools/validate_game.gd` → **0 失败**（15 段：数据/分布/体重价格/背包卖鱼/排序筛选/鱼竿/鱼饵星级/成就/鱼贩/每日订单(含多类型)/存档v2往返/v1迁移/离线/动态层/专注模式）。
- `godot --headless -s tools/balance_probe.gd` → 鱼竿回本 0.3 分(Lv1)→7.3 分(Lv8) 递增；鱼饵回本 4~17 分；离线受背包截断。

## 四、截图（docs/img/）

- `scene.png` 主场景 + HUD 订单 chip
- `panel_bag.png` 鱼篓（排序行）｜`panel_dex.png` 图鉴徽章｜`panel_order.png` 大物订单
- `panel_settings.png` 设置（音量/专注模式）｜`panel_ach.png` 成就

## 五、git 提交列表（睡前基线之后）

```
15cadb2 通宵⑥ 专注/安静模式
508fec4 文档：README/白皮书/美术需求
f9d0a21 通宵⑤ 数值平衡：鱼竿成本曲线
03ccf5a 通宵④ 更多订单类型
a6feb3d 通宵③ 图鉴长期目标徽章
d263e15 通宵② 鱼篓排序/筛选
4e6c8fd 通宵① HUD 每日订单进度
e2dc11b 通宵调研文档
```

## 六、如果不满意，如何回退到睡前基线

```sh
cd E:\claude\corner-fishing-idle
git reset --hard 睡前基线-20260614     # 回到睡前那一版（已推送，安全）
```

或用桌面完整备份：`C:\Users\Martin\Desktop\角落垂钓-睡前备份-20260614\`
（含 project/ 全量 + 存档快照；用法见该文件夹「说明.txt」）。
存档本身在 `user://`（`...\app_userdata\角落垂钓\corner_fishing_save.json`），回退代码不动存档；
新结构对旧存档向后兼容，回退也能读。

## 七、后续候选（未做，留给下一轮）

鱼贩×订单联动、装饰/陈列系统（Chillquarium 式）、多钓点生态、昼夜与天气（已在 art_requests 备主图变体）、
鱼钩第三条成长线、自动卖鱼（建议做成付费/长期解锁——**需你定商业化方向**）。
