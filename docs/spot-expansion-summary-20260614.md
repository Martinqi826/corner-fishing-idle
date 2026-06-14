# 多钓点生态扩展 · 总结（2026-06-14）

把《角落垂钓》从"单钓点挂机"升级为"多钓点生态挂机"。全程：备份 → 调研 → 数据骨架 →
鱼种扩展 → 随机事件 → 钓点 UI/存档 → 文档/截图，每阶段独立 commit + 无头回归 0 失败。
存档向后兼容（旧档默认落点 river_bend）。

## 一、做了什么

| # | 模块 | 内容 |
|---|---|---|
| 0 | 备份 | 工作区干净，打 tag `多钓点基线-20260614`（扩展前基线） |
| 1 | 数据骨架 | 新增 `spot_data.gd`(SpotData) + `event_data.gd`(EventData)，可扩展，逻辑与数据解耦 |
| 2 | 鱼种扩展 | 28 → **60 种**，每条加生态标签（river/lake/stream/coast/deep/cold/night/protected）；旧 28 id/数值不变；抽鱼按钓点鱼池（就近回退不逸出）；缺图回退按品阶通用鱼图标 |
| 3 | 随机事件 | 硬编码鱼汛 → **EventData 驱动**的通用事件管理器；7 事件，按钓点触发，buff/instant 两型，叠加咬钩/价值/运气修正 |
| 4 | 钓点 UI / 存档 v8 | 钓点页签 + HUD 钓点·事件角标 + 切换换池/事件/背景；存档 v8（current_spot/unlocked_spots/seen_spots/active_event）+ 迁移；订单建议钓点 |
| 5 | 文档/截图 | README / project_overview.html / art_requests(P0) / 调研 / 本总结 + 新截图 |

## 二、3 个首发钓点

| 钓点 | id | 解锁 | 招牌鱼 | 专属事件 |
|---|---|---|---|---|
| 新手河湾（保留现有体验，=原 28 种） | river_bend | 默认 | 全谱（白条→中华鲟） | 鱼汛/顺水鱼群/晨雾/漂流木箱 |
| 静水湖泊 | still_lake | 累计 80 渔获 | 大口黑鲈·鳜·黑鱼·狗鱼·鳡·鲟·欧鲶 | 晨雾/寒潮/顺水鱼群 |
| 海岸码头 | coast_pier | 累计 300 渔获 | 海鲈·真鲷·带鱼·石斑·马鲛·黄鱼·金枪·旗鱼 | 涨潮/漂流木箱/保护鱼放流 |

roadmap：山涧溪流（stream/cold：虹鳟·细鳞·哲罗）、远海深钓（deep：金枪·旗鱼·深海石斑），数据骨架已就位。

## 三、关键文件

- `spot_data.gd`（新）：SPOTS 3 项；`pool_for`(habitat_tags ∩ FishData tags) / `unlock_met` / `unlock_text` / 系数访问器。
- `event_data.gd`（新）：EVENTS 7 项；`applies_to` / `is_buff/is_instant` / 效果访问器。
- `fish_data.gd`：FISH 28→60 + 每条 `tags`；`roll_fish/roll_catch` 加 `pool` 参数（就近品阶回退，绝不逸出）。
- `main.gd`：事件管理器（`_tick_events`/`_fire_event`/`_activate_buff`/`_end_buff`/`_resolve_instant`）；
  钓点（`_refresh_unlocks`/`_switch_spot`/`_spot_pool`/`_order_pool`）；钓点页 `_fill_spot_tab`；
  HUD `_build/_update_spot_chip`；鱼图标回退 `_generic_fish_texture`/`_make_generic_fish`。
- `save_system.gd`：v8 `apply_spots`，旧档默认 river_bend。
- `scene_painter.gd`：`set_spot(bg_key)` 按钓点切底图，缺图回退主图。
- `tools/validate_game.gd`：新增 钓点/事件数据、鱼池隔离、随机事件、多钓点切换、存档 v8、图标回退 段。
- `tools/dev_screenshot.gd`：新增 panel_spot / scene_lake / scene_coast。

## 四、测试结果

- `godot --headless -s tools/validate_game.gd` → **0 失败**（钓点/事件数据·鱼池隔离·随机事件·多钓点切换·
  存档 v2/v8 往返与旧档迁移·图标回退 + 原有全部回归）。
- `godot --headless -s tools/balance_probe.gd` → 经济健康（鱼竿回本 0.3→7.1 分递增、鱼饵 4~17、鱼钩 5~46，
  全裸→全满 ≈×20）；扩鱼后各档期望仅微动。
- `godot --path . -s tools/dev_screenshot.gd` → 截图无溢出。

## 五、截图（docs/img/）

- `panel_spot.png` 钓点页签（三钓点解锁/收集进度/前往）
- `scene_lake.png` 静水湖泊 HUD「静水湖泊 · 晨雾」
- `scene_coast.png` 海岸码头 HUD「海岸码头 · 涨潮」
- `panel_dex.png` 图鉴 60 种（缺图回退品阶通用图标）

## 六、数据来源

见 `docs/spot-research-20260614.md`：FishBase/GBIF（生境/体重）、Eschmeyer's Catalog（分类学）、
IGFA World Records（运动钓目标鱼/体重上限）、Fishbrain 与 Pier Fishing 社区（常钓鱼种/钓点偏好）、
中文垂钓资料（本土鱼种与习性）。

## 七、缺资源回退（不阻塞、不崩）

- 钓点背景缺图 → 现有主图；鱼专属图标缺图 → 品阶通用图标；事件图标缺图 → 仅文案；旧档无字段 → river_bend。
- 美术需求已写入 `docs/art_requests.md`（P0 多钓点资源：钓点背景 / 事件图标 / 新鱼图标），交 Codex。

## 八、commit 列表（多钓点基线之后）

```
多钓点① 数据骨架 spot_data.gd + event_data.gd
多钓点② 鱼种扩展 28→60 + 生态标签
多钓点③ 随机事件系统（EventData 驱动）
多钓点④ 钓点 UI、切换、存档 v8
多钓点⑤ 文档/HTML/截图同步 + 美术需求交 Codex（本提交）
```

## 九、如何回退

```sh
cd E:\claude\corner-fishing-idle
git reset --hard 多钓点基线-20260614   # 回到扩展前
```

存档在 `user://`，向后兼容，回退代码不动存档；新结构对旧存档也能读。
</content>
