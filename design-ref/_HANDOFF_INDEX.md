# 设计系统 → 游戏 · 移植总入口(给本机 Claude Code)

> **你(本机 Claude Code)正在做的是"移植/翻译",不是"运行"。**
> 这个文件夹是 **角落垂钓** 的 UI 设计稿(HTML/React/CSS),是 UI 的 source of truth。
> 真正的游戏是隔壁的 **Godot 4.6 / GDScript** 工程。你的任务:读懂这里的设计意图,
> 用 GDScript 在游戏里实现它。**不要**把这里的 `.jsx/.css` 当成能直接运行或导入的代码。

---

## 0. 先读这几个文件(按顺序)

1. `readme.md` —— 整套设计系统的总览:声音/配色/字体/两种表面/图标/动效规则。**必读。**
2. 本文件 `_HANDOFF_INDEX.md` —— 移植工作流 + 文件对照表 + 该改/别碰清单。
3. `handoff/*.md` —— 单条、说死的改动单(如撤角落按钮)。有就先把这些做了。

> ★ **每屏长什么样,以 `playable/Corner Fishing.html` 为准——它是会动的活规格,不是死截图。**
> 这是一个**可玩模拟**:主界面 + 鱼篓 / 装备 / 图鉴 / 任务 / 钓点 五个页签里**每一屏**的真实布局、配色、间距、状态、交互,都在这里跑得起来。
> **要某屏的细节,就用浏览器打开它、点到那屏自己看**(双击即可,资源全在 `assets/` 与 `styles.css`,相对路径自带)。
> 不懂 JS 也能直接读它的源码(`playable/*.js` 是普通 JavaScript,结构和文案一目了然)。
> **永远优先看这个活规格,别只凭别人给的静态截图猜——截图是死的、会缺状态(hover/选中/空态/滚动)。**

---

## 1. 两个世界,谁是谁

| | 这个文件夹(design-ref) | 你要改的游戏 |
|---|---|---|
| 技术 | HTML / React(JSX) / CSS | Godot 4.6 / GDScript |
| 角色 | UI 的**规格 / 真理来源** | **实现** |
| 你怎么用 | **读**,翻译成 GDScript | **写** `.gd` |

游戏里的 UI 不是声明式 CSS,而是在代码里**手搭控件 + StyleBox/Theme**。所以移植 = 把
CSS 的 token 和 JSX 的结构,翻成 `ui_panels.gd` 里的 `StyleBoxFlat`、`Theme`、控件构建。

---

## 2. 文件对照表(design-ref → 游戏 GDScript)

| design-ref | 内容 | 移植到游戏的哪里 |
|---|---|---|
| `tokens/colors.css` | 全部色值(品阶色、表面色、金/铜强调) | `main.gd::_tier_color()` / `_ui_tier_color()`;`ui_panels.gd` 里各 `StyleBoxFlat.bg_color / border_color` |
| `tokens/fonts.css` | 字体替换说明(见 §4) | `ui_panels.gd` 的 Theme 字体 + 标题/数字字体覆盖 |
| `tokens/typography.css` | 字号/字重/行高/tabular 数字 | 各 `Label` 的 `add_theme_font_size_override` 等 |
| `tokens/spacing.css` | 间距刻度、圆角(16 面板/12 卡/9 行/8 钮/999 胶囊) | StyleBox 的 `corner_radius` / `content_margin` / 容器 `separation` |
| `tokens/effects.css` | 阴影、羽化、模糊、动效缓动/时长 | `feather_mask.gdshader`(已存在)、面板阴影 StyleBox、`_process` 里的动效节奏 |
| `components/primitives/*` | 按钮/开关/滑条/进度条/徽章样式 | `ui_panels.gd` 对应控件构建函数 |
| `components/surfaces/*` | Panel(暗玻璃)/Card(暖纸)/TabBar | `ui_panels.gd::open_panel` 及各 `fill_*_panel` |
| `components/game/*` | FishRow/DexCard/SpotCard/HudChip/HudLedger 等 | `ui_panels.gd` 列表行/卡片构建;HUD 在 `main.gd::_build_*` |
| `guidelines/*.html` | 每条规则的可视基准(配色/字体/间距样卡) | 对照用,核对你改出来的观感对不对 |
| **`playable/Corner Fishing.html`** | **★ 每屏的活规格**:可玩模拟,5 个页签每一屏的真实布局/配色/间距/状态/交互。双击即开,点到哪屏看哪屏 | 移植任意一屏前先打开它点到那屏,核对观感与状态;`playable/*.js` 可直接读结构与文案 |
| `ui_kits/corner_fishing/app.jsx` | **整窗组合的参考**:HUD + 面板 + 页签怎么拼 | 对照 `main.gd`(HUD/场景)+ `ui_panels.gd`(面板)的组合 |
| `assets/**` | 美术 PNG(鱼/装备/场景/UI 图标) | 与游戏 `assets/art/**` 对齐,别重复导入冲突 |

> 每个组件目录都有 `.d.ts`(接口)+ `.prompt.md`(用法说明)。拿不准某个组件的意图时读它的 `.prompt.md`。

---

## 3. ⚠ 该改 / 别碰(最重要,否则会改坏游戏)

**游戏在某些地方故意领先或不同于设计稿。设计稿不是无条件覆盖游戏。** 移植前先核对现状:

- **别碰:游戏特有、设计稿里没有的系统** —— 逐像素透明窗、鼠标穿透(`main.gd::_update_passthrough`)、
  拖动、羽化 shader、存档迁移、无头测试。这些是工程现实,设计稿不涉及。
- **以游戏现状为准的地方** —— 例:主界面按钮数量、入口收敛,游戏已经做过整合(见
  `handoff/2026-06-16_corner-entry-consolidation.md`)。**先读 handoff,别用旧设计稿回滚它。**
- **该应用的** —— 配色、字体、字号、圆角、间距、阴影、暗玻璃/暖纸两种表面、品阶色信号、
  动效节奏(慢、无弹跳)、文案声音(安静/文学/简中/价格写按钮上)。
- **拿不准就先列差异问人**,别一次性"照搬全部"。

---

## 4. 字体:不能只看 CSS

`tokens/fonts.css` 用的是 **Google Fonts 在线 Noto Sans SC / Noto Serif SC**,这是**网页替代品**。
游戏出货用 Windows 系统字体(Microsoft YaHei UI / SimHei)。要在游戏里实现设计稿的字体方案:

1. **拿到真字体文件**:下载 Noto Sans SC / Noto Serif SC 的 `.otf/.ttf`(或用 Source Han Sans/Serif),放进 `fish-idle/assets/fonts/`。
2. **Godot 接线**:`load()` 成 `FontFile`,设进 Theme;**标题与主数字**单独用 Serif 覆盖(设计意图:衬线=水彩卷轴味的标题/数字)。
3. 数字用 tabular(等宽数字)对齐。

光改 CSS 不会让游戏变字体——markdown/CSS 带不了字体文件,必须真的搬文件 + 接 Theme。

---

## 5. 验证回环(每次改完都做)

游戏工程里已有工具(见游戏 `README.md`):

```sh
godot --headless -s tools/validate_game.gd     # 无头回归测试,必须全过
godot --path . -s tools/dev_screenshot.gd      # 带 alpha 的各面板截图 → docs/img/
```

- 改完先跑 `validate_game.gd`(逻辑没被改坏)。
- 视觉类改动(字体/配色/间距)跑 `dev_screenshot.gd` 出图,**让人或设计侧在截图上把关**——
  "对不对味"机器不能自我担保。
- 把最终截图或改后的 `.gd` 回传给设计侧,同步设计稿,避免两边再漂移。

---

## 6. 建议的落地方式

把整个 design-ref 文件夹放进游戏仓库旁(如 `fish-idle/design-ref/`),并在仓库根 `CLAUDE.md` 写:

```
UI 以 design-ref/ 为准。改 UI 前先读 design-ref/_HANDOFF_INDEX.md 与 design-ref/handoff/。
配色/字体/间距 token 在 design-ref/tokens/;组合参考 design-ref/ui_kits/corner_fishing/app.jsx。
游戏已整合过的入口/按钮以 handoff 为准,勿用旧设计稿回滚。
```

这样每次开工你都会自动拿它当持久参考,而不是一次性看个 MD。
