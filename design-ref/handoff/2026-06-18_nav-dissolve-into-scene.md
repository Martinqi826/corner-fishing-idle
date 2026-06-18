# Handoff · 底部导航去 slab,融入场景 + 安静线描字形

**日期** 2026-06-18
**来源** 设计稿 `playable/Corner Fishing.html`(可玩模拟,UI source of truth)+ `playable/ui.js`
**目标工程** 本机 Godot 项目 `fish-idle/`(`main.gd` / `ui_panels.gd`)
**给谁** 本机 Claude Code(照此在 GDScript 落地)

---

## 1. 设计决定(已在 playable 定稿)

底部那排导航(鱼篓 / 装备 / 图鉴 / 任务 / 钓点)原来坐在一条**不透明深色横条**上,
清晰的按钮 + 深色 chrome 块和水彩世界割裂,**破坏沉浸感**。新方案是**让导航融进画面**,两点:

1. **去掉 slab**:导航不再有独立的深色背景块和那条顶部分隔线。水彩场景**一直延伸到画框底边**,
   导航**浮在场景之上**,只靠一层**从透明向下渐深的暗角(vignette)**把文字托住——
   和顶部 HUD 胶囊"贴"在场景上、无底板是同一套逻辑(见 readme「HUD chips … no plate」)。
2. **换图标**:**去掉 emoji**(原来是 🧺🎣📖📜🗺️,违反设计系统「never substitute emoji」)。
   改成**安静的细线描字形**(篓 / 竿 / 书 / 任务夹 / 地图针),单色描边、暖白偏雾灰,
   **当前页签亮成金色**。字形与文字都带轻微投影,保证在亮雪面上也清晰。

> ⚠ **先核对游戏现状**:playable 是设计意图,游戏底栏的实际结构可能与之不同
> (入口此前已收敛进 HUD,见 `handoff/2026-06-16_corner-entry-consolidation.md`)。
> **先在 `main.gd` / `ui_panels.gd` 里找到现在底部导航/页签到底是怎么搭的**,再按下面落地;
> 若游戏底栏已是别的形态,以"去 slab + 融场景 + 安静字形 + 金色当前态"这套**意图**为准,别机械照搬控件树。

---

## 2. 设计稿里的确切值(从 `Corner Fishing.html` / `tokens` 取)

| 项 | 值 |
|---|---|
| 导航容器背景 | **无实色块**;改为竖直渐变暗角:`rgba(16,18,15,0)` → `rgba(16,18,15,0.22)`(约 42%)→ `rgba(13,15,12,0.6)`(底) |
| 容器顶部分隔线 | **删掉**(原 1px border-top) |
| 轻微磨砂 | 可选,场景透过导航略微 blur ~1.5px(Godot 里用半透明 + 让场景透出即可,blur 非必需) |
| 标签文字色 | `rgba(238,233,224,0.86)`,阴影 `0 1px 3px rgba(0,0,0,0.55)`,字号 ~11、字重 500、字距 0.06em |
| 当前页签(active) | 文字+字形 `--gold-bright #F0C978`,字重 600 |
| 字形描边色 | 同标签文字(`currentColor`),线宽细(SVG 里 1.45 / 21px,换算到游戏图标即"细线、暖白") |
| 字形投影 | `drop-shadow(0 1px 2px rgba(0,0,0,0.5))` |
| hover | 文字提到纯白 `#fff`;**不要**给按钮加背景块 |
| press | 轻微 `scale(0.94)`,不变背景 |

字形参考(playable 用的内联 SVG 路径,在 `playable/ui.js` 的 `SVG` 对象里,可直接照着画 Godot 图标):
basket 篓 / equip 鱼竿 / dex 翻开的书 / orders 任务夹+对勾 / spots 地图针。

---

## 3. 实施要点(GDScript)

1. **找到底栏容器**:定位现在底部导航的 `Control`/`HBoxContainer` 及其 `StyleBoxFlat`(若有)。
2. **去 slab**:把该容器的背景 `StyleBoxFlat` 换成 `StyleBoxEmpty`(或 bg_color 全透明),
   删掉 `border_width_top` / 顶部分隔。容器**浮在场景 Control 之上**(提高其在树里的绘制顺序 / `z_index`),
   而不是占据场景下方一条独立区域——确保水彩场景画到画框底边。
3. **暗角**:在导航下方铺一个**竖直 alpha 渐变**做托底——
   用一张 1×N 的竖直渐变贴图(上透明→下 `rgba(13,15,12,0.6)`)拉满底部宽度,或 `GradientTexture2D`,
   或一个带 vertical gradient 的 shader 薄条。**不是实色 ColorRect**——要能透出场景。
4. **图标**:把 emoji / 旧扁平图标换成**细线描字形 PNG 或矢量**(暖白、细),加 `1px` 暗投影;
   `modulate` 在 active 时设为 `--gold-bright`。
5. **文字**:`Label` 用暖白色 + `font_outline` 或 shadow(`add_theme_constant_override("shadow_offset_y",1)` 等)保证亮雪面可读;
   active 文字 `--gold-bright`。
6. **交互**:hover 只提亮文字/字形,**别加背景框**;press 轻微缩放。
7. **面板打开时**:导航**保持浮在面板之上、当前页签亮金**,这样可直接切页签(playable 即如此)。
   若游戏的面板会盖住底栏,给面板内容底部留出 ≈导航高度的内边距,别让内容被导航遮住。

---

## 4. 验收标准

- [ ] 底部**没有**那条不透明深色横条/分隔线;水彩场景延伸到画框底边。
- [ ] 导航**浮在场景里**,文字/字形清晰(尤其左侧亮雪面),整体感觉是"画面的一部分",不是 chrome 条。
- [ ] 图标**无 emoji**,是安静的细线描字形;**当前页签金色**。
- [ ] hover 只提亮、无背景块;press 轻微缩放。
- [ ] 面板打开时仍能从底栏切页签(或按产品决定是否隐藏——但别回到"深色 slab")。
- [ ] **透明窗**:导航区域可点击不穿透;场景空白处仍可拖动 + 穿透。
- [ ] `godot --headless -s tools/validate_game.gd` 全过;`tools/dev_screenshot.gd` 出图人工核对观感。

---

## 5. 反向同步

落地后把 `dev_screenshot.gd` 出的底栏截图发回,我据此校准设计稿,避免两边漂移。
