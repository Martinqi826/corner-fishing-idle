# AGENTS.md — 给所有 AI 编码代理的总入口

> 任何 AI（Claude / Codex / Cursor / WorkBuddy / …）在本仓库**动手前必读本文**。
> 完整协作守则见 [CONTRIBUTING.md](CONTRIBUTING.md)；项目全貌见 [VISION.md](VISION.md) / [ROADMAP.md](ROADMAP.md) / [BACKLOG.md](BACKLOG.md)；Claude 另读 [CLAUDE.md](CLAUDE.md)。

## 这是什么

角落垂钓：贴桌面角落、水彩风、自动挂机钓鱼的 **Godot 4.6 / GDScript** 桌面挂件。完整玩法 / 模块职责 / 存档版本以 [README.md](README.md) 为准。

## 铁规矩（违背会造成混乱 / 改坏 main）

1. **`main` 受保护 —— 走分支 + PR，绝不直推 `main`。** 开 `feat|fix|art|docs/简短名` 分支 → 改 → 推分支 → 开 PR → 等 Owner 批准后合并。
2. **动手前先 `git fetch`，以 `origin/main` 为基**（别信本地旧状态）。
3. **只 `git add <显式文件>`，绝不 `git add -A`。** 本仓库 `.import` 噪声多、且常有多个 agent 在跑，`-A` 会卷入别人未提交的活儿。
4. **不共用工作区。** 每个 agent / 人用自己的 clone 或 `git worktree`；一份副本里，同一时间只让一个 agent 动同一文件。
5. **改完即验证**：逻辑改动跑 `godot --headless -s tools/validate_game.gd`（必须 **0 失败**）；视觉改动跑 `tools/dev_screenshot.gd` 出图自查。
6. **改了功能就同步文档**（否则视为没做完）：在 ROADMAP 勾选 / 移动焦点、在 BACKLOG 记一句决策、README 数字同步。
7. **拿不准、或要动商业化方向（自动卖鱼等）→ 停下问 Owner，别擅自做。**

## 标准工作流

```
git fetch && git switch -c feat/我的任务 origin/main   # 自己的分支，从最新 main 起
… 改 + 跑 validate（0 失败）…
git add <显式文件>  &&  git commit                       # 绝不 -A
git push -u origin feat/我的任务
# 在 GitHub 开 PR，按模板填「改了什么 / 为什么 / 怎么验证」，等 Owner Approve + Merge
```

## 区域归属（减少撞车，细则见 [CONTRIBUTING.md](CONTRIBUTING.md) §4 与 [docs/parallel-dev-contract.md](docs/parallel-dev-contract.md)）

逻辑/引擎：`main.gd` 及拆出模块 ｜ 数据/数值：`fish_data.gd`·`fish_lore.gd` 等 ｜ 美术/音频：`assets/art|audio/**`（只接入不覆盖）｜ 场景绘制：`scene_painter.gd`（易撞，动前必同步）｜ UI 真值：`design-ref/` ｜ 文档：根目录三件套 + `docs/**`。
**原则：一个文件，同一时间只一个任务在动。**

## 提交信息

中文一句话标题 +（可选）一句为什么；AI 提交结尾加 `Co-Authored-By: <模型名> <noreply@…>`。
