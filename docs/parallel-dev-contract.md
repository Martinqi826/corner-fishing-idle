# 并行开发契约（角落垂钓）

> **本文是 AI 车道细则**（拆模块顺序、文件归属、Codex 边界）。多人 / 多 AI 协作的**总则**（分支 + PR + 受保护 main + 角色分工 + 区域归属表）见 [../CONTRIBUTING.md](../CONTRIBUTING.md)——人类贡献者先读那份。

目标：让多 Agent / 多车道能安全并行，提升开发吞吐。用户只用自然语言对话驱动，编排由 Claude 自动完成。

## 协作模型

- **Claude = 总包/编排**：把需求拆成任务；互不重叠的用 Workflow/子 Agent 一回合内并行；有依赖的串行接力；负责集成与回归。
- **Codex = 美术车道**：只产 `assets/art/**`（含音频/装备/动态层）。Claude 只加载/接入、绝不覆盖。
- **安全网**：每里程碑 `--headless -s tools/validate_game.gd` 0 失败 + 涉 UI 跑 `dev_screenshot` 看 docs/img + 独立 git commit（可回退）+ 重启客户端。回退靠普通 commit（不建备份 tag / 桌面备份）。

## 模块拆分目标（main.gd 解耦）

把巨石 `main.gd` 拆成职责单一、文件归属清晰的模块，降低同文件竞争：

| 模块（目标文件） | 职责 | 状态 |
|---|---|---|
| `main.gd` | 状态 + 核心钓鱼循环 + 编排（瘦身后） | 重构中 |
| `save_system.gd` | 序列化/反序列化/迁移/原子写/.bak | ← 第一步 |
| `ui_panels.gd` | 所有面板构建（_make_card/_fill_*/拖动/皮肤） | 待拆 |
| `events.gd` | 限时事件（收鱼郎 / 鱼汛）状态机 | 待拆 |
| `orders.gd` | 每日订单 + 周目标 生成/匹配/结算 | 待拆 |
| 已独立 | `fish_data.gd` `achievements.gd` `audio_manager.gd` `scene_painter.gd` | ✅ |

## 文件归属（并行车道，互不重叠才安全）

- 逻辑/引擎/接入：Claude 主车道（main.gd 及各拆出模块，一次只让一个任务动同一文件）
- 美术/音频/资源：Codex（assets/art/**）
- 数据/数值：fish_data.gd（可独立调）
- 测试/文档：tools/validate_game.gd、docs/**

## 并行纪律

- 一个任务**独占**它要改的文件；跨任务不碰同一文件（否则串行）。
- 改前先 grep 定位（main.gd 已大，勿整文件读）；Codex 可能并行改，动前重读。
- 拆模块本身**串行**做（移动共享文件不可并行）；拆完后的功能开发才并行。
- 商业化/付费方向（自动卖鱼等）需用户决策，遇到停下记录、不擅自实现。
