# 怎么把这套设计交给 Claude Code(三步,只需复制粘贴)

> 你不用懂代码。照下面做就行。

## 第 1 步:把文件夹放到游戏旁边

1. 下载我给你的 zip,解压。解压出来是一个文件夹(里面有 `playable`、`tokens`、`components`、
   `_HANDOFF_INDEX.md` 等)。
2. 把这个文件夹**整个拖进你的游戏文件夹里**,改名为 `design-ref`。
   - 也就是说,最终是:`fish-idle/design-ref/`(和游戏代码并排)。

## 第 2 步:放一个"常驻说明"让 CC 每次自动看

1. 打开 `design-ref/handoff/游戏仓库-CLAUDE.md` 这个文件,**全选、复制**里面的全部文字。
2. 在你的**游戏文件夹根目录**(`fish-idle/`)里:
   - 如果已经有一个叫 `CLAUDE.md` 的文件 → 打开它,把刚才复制的内容**粘到最上面**。
   - 如果没有 → 新建一个文本文件,命名为 `CLAUDE.md`,把内容粘进去保存。
3. 这样 Claude Code **每次开工都会自动读到它**,不用你每次重新解释。

## 第 3 步:让 CC 干活时,粘这句话

每次想让 CC 改 UI,把下面这段直接发给它(按需改最后一句要改的内容):

```
UI 以 design-ref/ 为准。开始前先读 design-ref/_HANDOFF_INDEX.md 和 design-ref/handoff/。

要看每屏长什么样,用浏览器打开 design-ref/playable/Corner Fishing.html,
点开底部 5 个页签(鱼篓/装备/图鉴/任务/钓点),逐屏看真实布局、配色、间距、状态、交互——
不要只凭截图猜,需要精确数值就读 design-ref/playable/*.js 和 design-ref/tokens/*.css。
游戏已整合过的入口/按钮以 design-ref/handoff/ 为准,别用旧设计稿回滚。

这次请帮我改:_____________(写你要改的那一屏/那个细节)
```

## 就这样

- 以后设计有更新,我重新给你一版 zip,你**覆盖** `design-ref` 文件夹即可,其它都不用动。
- CC 改完会让你看截图,你只要判断"对不对味"就行。
