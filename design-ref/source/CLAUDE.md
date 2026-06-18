# 角落垂钓 Corner Fishing — 项目约定

## UI 以 `design-ref/` 为准
UI 的真理来源是 `design-ref/`（角落垂钓设计系统：HTML/React/CSS 设计稿 + 令牌 + 美术 + 规范）。
**改任何 UI 前先读**：
- `design-ref/_HANDOFF_INDEX.md` —— 移植总入口 + 文件对照表 + 「该改/别碰」清单。
- `design-ref/readme.md` —— 配色/字体/两种表面/图标/文案声音/动效规则总览。
- `design-ref/handoff/*.md` —— 单条说死的改动单；有就先做。

## 移植关系（别搞反）
`design-ref/` 是 **HTML/React 设计稿**，是规格；游戏是 **Godot 4.6 / GDScript**，是实现。
任务是「读懂设计意图 → 用 GDScript 落地」，**不要**把 `.jsx/.css` 当成能直接 import/运行的代码。
- 颜色令牌 `design-ref/tokens/colors.css` → `main.gd::_tier_color()` / `ui_panels.gd` 各 `StyleBoxFlat`。
- 字号/间距/圆角 → `Label` 字号覆盖、StyleBox `corner_radius/content_margin`、容器 `separation`。
- 字体方案需真的搬字体文件进 `assets/fonts/` 再接 Theme（光改 CSS 不生效，见 `_HANDOFF_INDEX.md` §4）。
- 整窗组合参考 `design-ref/ui_kits/corner_fishing/app.jsx`。

## 该改 / 别碰
- **别碰**（游戏特有、设计稿没有）：逐像素透明窗 + 鼠标穿透（`main.gd::_update_passthrough`）、拖动、羽化 shader、存档迁移、无头测试。
- **以游戏现状为准**：主界面入口已收敛——所有入口走 HUD（点金币栏开面板，钓点签/订单签深链页签），右下角不再有独立按钮。**勿用旧设计稿回滚此整合**。
  - 备注：`design-ref/handoff/2026-06-16_corner-entry-consolidation.md` 描述的改动 **游戏已落地完成**（`main.gd:162-166` 金币栏可点、`main.gd:732/779` 已撤独立按钮）。该 handoff 已结案。
- **该应用**：配色、字体、字号、圆角、间距、阴影、暗玻璃/暖纸两种表面、品阶色信号、慢而无弹跳的动效、安静文学的简中文案（价格写在按钮上）。

## 每次改完都验证
```sh
godot --headless -s tools/validate_game.gd     # 无头回归，必须全过
godot --path . -s tools/dev_screenshot.gd      # 带 alpha 的面板截图 → docs/img/，供人/设计侧把关观感
```
视觉类改动跑截图，让人在图上确认「对不对味」——机器不自我担保。改后把 `.gd` 或截图回传设计侧，避免两边漂移。
