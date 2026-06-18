# UI 以 design-ref/ 为准(给本机 Claude Code)

本仓库的 UI **设计真理来源**是同目录下的 `design-ref/` 文件夹(角落垂钓设计系统)。
改任何界面前,**先读** `design-ref/_HANDOFF_INDEX.md` 和 `design-ref/handoff/`。

## 怎么用

- **每屏长什么样 → 看活规格**:用浏览器打开 `design-ref/playable/Corner Fishing.html`,
  点开底部 5 个页签(鱼篓 / 装备 / 图鉴 / 任务 / 钓点),**每一屏的真实布局、配色、间距、
  状态、交互都在里面**。要某屏细节就点到那屏自己看,别只凭静态截图猜——截图会缺
  hover / 选中 / 空态 / 滚动这些状态。需要精确数值时直接读 `design-ref/playable/*.js`(普通 JS)。
- **配色 / 字体 / 字号 / 圆角 / 间距 / 阴影 → 读 token**:`design-ref/tokens/*.css`,
  这是无歧义真值,别从截图取色。
- **组件结构与意图**:`design-ref/components/**` 的 `.d.ts` + `.prompt.md`;
  整窗组合参考 `design-ref/ui_kits/corner_fishing/app.jsx`。

## 规矩(否则会改坏游戏)

- 这是"移植 / 翻译",不是"运行"。`design-ref` 里的 `.jsx/.css/.html` **不要**当成能直接导入或运行的代码;
  用 GDScript 把设计意图实现到 `main.gd` / `ui_panels.gd`。
- **游戏已整合过的入口 / 按钮以 `design-ref/handoff/` 为准,勿用旧设计稿回滚。**
- 游戏特有系统(透明窗、鼠标穿透、羽化 shader、存档迁移等)设计稿不涉及,**别碰**。
- 视觉类改动改完跑 `tools/dev_screenshot.gd` 出图人工把关;逻辑改动跑 `tools/validate_game.gd` 必须全过。
- 拿不准就先列差异问人,别一次性"照搬全部"。
