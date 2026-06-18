class_name DT
## 角落垂钓 · 设计令牌（从 design-ref/tokens/*.css 1:1 落成 GDScript）。
## UI 的唯一配色/字号/圆角/间距真值源——改观感先改这里，全 UI 一处生效。
## 颜色命名与 design-ref/tokens/colors.css 对齐；改 CD 设计稿时同步此文件即可。

# ============================ 暗玻璃面板 ============================
const GLASS            := Color(0.122, 0.129, 0.122, 0.94)   # 面板底 rgba(31,33,31,.94)
const GLASS_SOLID      := Color(0.122, 0.129, 0.122)         # #1F211F 不透明
const GLASS_BORDER     := Color(0.878, 0.839, 0.741, 0.72)   # 暖米色细描边
const GLASS_ROW        := Color(0.200, 0.212, 0.188, 0.52)   # 暗内嵌行
const GLASS_ROW_BORDER := Color(0.859, 0.820, 0.698, 0.16)
const GLASS_ROW_HOVER  := Color(0.251, 0.263, 0.227, 0.62)

# ============================ 暖纸卡片 ============================
const PAPER        := Color(0.910, 0.878, 0.780, 0.88)
const PAPER_SOLID  := Color(0.910, 0.878, 0.780)   # #E8E0C7
const PAPER_2      := Color(0.969, 0.953, 0.922)   # #F7F3EB
const PAPER_BORDER := Color(1.000, 0.961, 0.839, 0.46)

# ============================ 文字 ============================
const TEXT_TITLE       := Color(0.922, 0.878, 0.780)  # 面板标题
const TEXT_ON_GLASS    := Color(0.925, 0.910, 0.878)  # 暗面板正文
const TEXT_MUTED_GLASS := Color(0.780, 0.741, 0.659)  # 次要标签
const TEXT_FAINT_GLASS := Color(0.502, 0.490, 0.447)  # 禁用/锁定
const INK              := Color(0.259, 0.247, 0.220)  # 纸上主墨
const INK_SOFT         := Color(0.459, 0.431, 0.369)  # 纸上次墨
const INK_ON_GOLD      := Color(0.180, 0.149, 0.102)  # 金/铜按钮上的字

# ============================ 暖强调（灯笼金→铜） ============================
const GOLD         := Color(0.839, 0.659, 0.365)   # 主暖强调 #D6A85D
const GOLD_BRIGHT  := Color(0.941, 0.788, 0.471)   # 灯笼高光 #F0C978
const BRONZE       := Color(0.659, 0.490, 0.251)   # 金按钮面 #A87D40
const BRONZE_HOVER := Color(0.780, 0.588, 0.310)
const BRONZE_PRESS := Color(0.502, 0.361, 0.180)
const RUST         := Color(0.678, 0.373, 0.302)   # 稀有红/警示 #AD5F4D

# ============================ 次要按钮 ============================
const BTN_SEC_BG       := Color(0.361, 0.361, 0.322, 0.84)
const BTN_SEC_BG_HOVER := Color(0.459, 0.459, 0.400, 0.92)
const BTN_SEC_FG       := Color(0.961, 0.910, 0.800)
const BTN_DISABLED_BG  := Color(0.314, 0.314, 0.282, 0.50)

# ============================ 品阶色（核心稀有度信号） ============================
const TIER := [
	Color(0.780, 0.780, 0.800),  # 0 普通 灰
	Color(0.349, 0.780, 0.302),  # 1 优良 绿
	Color(0.302, 0.620, 0.949),  # 2 稀有 蓝
	Color(0.722, 0.420, 0.949),  # 3 史诗 紫
	Color(1.000, 0.549, 0.122),  # 4 传说 橙
	Color(1.000, 0.380, 0.322),  # 5 神话 红
]
# 纸背景上绿/蓝对比不足时用的暗版
const TIER_INK := { 1: Color(0.180, 0.490, 0.196), 2: Color(0.165, 0.435, 0.710) }

# 变体色（与品阶正交）：0 无 / 1 斑斓 / 2 鎏金 / 3 七彩
const VARIANT := [
	Color(1, 1, 1),
	Color(0.549, 0.851, 0.949),
	Color(1.000, 0.839, 0.349),
	Color(0.949, 0.549, 0.949),
]

# ============================ 状态色 ============================
const POSITIVE := Color(0.455, 0.722, 0.400)  # 完成/解锁
const MERCHANT := Color(0.980, 0.820, 0.400)  # 流动鱼贩 ×1.5
const BAG_FULL := Color(1.000, 0.780, 0.451)  # 满篓警示

# ============================ 圆角 ============================
const R_PANEL := 16
const R_CARD  := 12
const R_CELL  := 11   # 网格卡片/行（CD .fishcell/.row）
const R_ROW   := 9
const R_BTN   := 8
const R_CHIP  := 999

# ============================ 间距（4px 基） ============================
const SP_1 := 4
const SP_2 := 6
const SP_3 := 8
const SP_4 := 10
const SP_5 := 12
const SP_6 := 16
const SP_7 := 18
const PANEL_PAD_X := 18
const PANEL_PAD_Y := 16
const ROW_GAP := 10
const CHIP_GAP := 6

# ============================ 字号（与引擎内字号对齐） ============================
const FS_TITLE   := 20  # 面板标题（衬线）
const FS_HEAD    := 17  # 分区/钓点名
const FS_BODY    := 15  # 正文/按钮
const FS_LABEL   := 14  # HUD
const FS_SM      := 13  # 页签/鱼名/密行
const FS_XS      := 12  # meta/描述
const FS_2XS     := 11  # 子 meta
const FS_MICRO   := 10  # 图鉴角标
const FS_NUMERAL := 34  # 英雄数字（金币/大统计）

# ============================ 取色助手 ============================
static func tier_color(t: int) -> Color:
	return TIER[clampi(t, 0, TIER.size() - 1)]

## 鱼名色：变体优先（斑斓/鎏金/七彩），否则品阶色。
static func name_color(tier: int, variant := 0) -> Color:
	if variant > 0:
		return VARIANT[clampi(variant, 0, VARIANT.size() - 1)]
	return tier_color(tier)
