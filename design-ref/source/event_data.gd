class_name EventData
## 随机事件（纯数据）：把原本硬编码在 main.gd 的"鱼汛"抽成可扩展的数据驱动事件表。
## 全部低干扰，适合桌面挂机：同一时刻最多一个 buff 事件在场，间隔很长，instant 事件一次性结算。
##
## kind：
##   "buff"    持续型修正：在 dur 时长内叠加 wait_mult / value_mult / luck 到钓鱼结算。
##   "instant" 一次性事件：触发即结算（发金币/放流），不占用 buff 槽。
## 时间字段（秒）：dur=持续时长区间，gap=两次之间间隔区间，first=首次出现区间。
## spots：[] 表示全钓点共享；否则仅在列出的钓点可触发（与 SpotData.event_pool 双向约束）。
## hud：HUD 角标短文案；toast_in/out：进出场提示；color：提示色 [r,g,b]；icon：assets/art/ui/event_*.png 键名。
## reward_base：instant 事件的基础金币区间，main 按鱼竿等级缩放。

const EVENTS := {
	# —— 全钓点共享：高潮事件（沿用原鱼汛数值，迁到数据驱动）——
	"fish_run": {
		"name": "鱼汛", "icon": "event_fish_run", "kind": "buff",
		"dur": [45.0, 70.0], "gap": [900.0, 1800.0], "first": [240.0, 480.0],
		"spots": [],
		"wait_mult": 0.5, "value_mult": 1.0, "luck": 7,
		"hud": "🌊鱼汛!", "color": [0.5, 0.78, 0.95], "flash": true,
		"toast_in": "🌊 鱼汛来了！咬钩更勤，大鱼更多！",
		"toast_out": "鱼汛退了，水面又归于平静。",
	},
	# —— 晨雾：清晨静水，节奏更慢但渔获略肥（低干扰）——
	"morning_fog": {
		"name": "晨雾", "icon": "event_fog", "kind": "buff",
		"dur": [60.0, 110.0], "gap": [600.0, 1200.0], "first": [120.0, 300.0],
		"spots": ["river_bend", "still_lake"],
		"wait_mult": 1.12, "value_mult": 1.12, "luck": 1,
		"hud": "🌫️晨雾", "color": [0.72, 0.76, 0.80], "flash": false,
		"toast_in": "🌫️ 晨雾漫上水面，水底安静，上来的多是肥鱼。",
		"toast_out": "雾散了，视野重新开阔。",
	},
	# —— 寒潮：湖/冷水，上鱼变慢但个体更大 ——
	"cold_front": {
		"name": "寒潮", "icon": "event_fog", "kind": "buff",
		"dur": [55.0, 90.0], "gap": [800.0, 1500.0], "first": [300.0, 600.0],
		"spots": ["still_lake"],
		"wait_mult": 1.45, "value_mult": 1.28, "luck": 2,
		"hud": "❄️寒潮", "color": [0.62, 0.72, 0.88], "flash": false,
		"toast_in": "❄️ 寒潮压境，鱼口转慢，但咬钩的往往是大家伙。",
		"toast_out": "寒潮过去，水温回稳。",
	},
	# —— 顺水鱼群：温和提速（河/湖）——
	"lucky_current": {
		"name": "顺水鱼群", "icon": "event_fish_run", "kind": "buff",
		"dur": [40.0, 75.0], "gap": [700.0, 1400.0], "first": [180.0, 400.0],
		"spots": ["river_bend", "still_lake"],
		"wait_mult": 0.7, "value_mult": 1.0, "luck": 3,
		"hud": "🐟顺水", "color": [0.55, 0.82, 0.70], "flash": false,
		"toast_in": "🐟 一群鱼顺水游过，浮漂动得勤了些。",
		"toast_out": "鱼群游远，水面恢复平常。",
	},
	# —— 涨潮：海岸专属上鱼窗口（提速 + 略增值）——
	"tide_in": {
		"name": "涨潮", "icon": "event_tide", "kind": "buff",
		"dur": [50.0, 85.0], "gap": [600.0, 1200.0], "first": [120.0, 300.0],
		"spots": ["coast_pier"],
		"wait_mult": 0.6, "value_mult": 1.1, "luck": 4,
		"hud": "🌊涨潮", "color": [0.45, 0.74, 0.92], "flash": false,
		"toast_in": "🌊 涨潮了！鱼群随浪涌向栈桥，正是好时候。",
		"toast_out": "潮水退去，海面归于平缓。",
	},
	# —— 漂流木箱：一次性金币奖励（河/海）——
	"drift_crate": {
		"name": "漂流木箱", "icon": "event_crate", "kind": "instant",
		"dur": [0.0, 0.0], "gap": [900.0, 2000.0], "first": [300.0, 700.0],
		"spots": ["river_bend", "coast_pier"],
		"reward_base": [40, 120],
		"hud": "", "color": [0.85, 0.72, 0.42], "flash": false,
		"toast_in": "📦 一只漂流木箱靠了岸，里面有些散碎金币：+%d！",
		"toast_out": "",
	},
	# —— 保护鱼放流：放流一条养殖保护鱼，得保育奖励（河/海）——
	"protected_release": {
		"name": "保护鱼放流", "icon": "event_release", "kind": "instant",
		"dur": [0.0, 0.0], "gap": [1200.0, 2400.0], "first": [600.0, 1200.0],
		"spots": ["river_bend", "coast_pier"],
		"reward_base": [60, 160],
		"hud": "", "color": [0.62, 0.86, 0.70], "flash": false,
		"toast_in": "🐟 协助放流了一条养殖保护鱼，获得保育奖励：+%d 金币。",
		"toast_out": "",
	},
}


static func has(id: String) -> bool:
	return EVENTS.has(id)


static func get_event(id: String) -> Dictionary:
	return EVENTS.get(id, {})


static func is_buff(id: String) -> bool:
	return str(get_event(id).get("kind", "")) == "buff"


static func is_instant(id: String) -> bool:
	return str(get_event(id).get("kind", "")) == "instant"


## 该事件是否适用于某钓点（spots 为空 = 全钓点）。
static func applies_to(id: String, spot_id: String) -> bool:
	if not has(id):
		return false
	var spots: Array = get_event(id).get("spots", [])
	return spots.is_empty() or spot_id in spots


## 访问器（带默认值，main 安全读取）。
static func wait_mult(id: String) -> float:
	return float(get_event(id).get("wait_mult", 1.0))


static func value_mult(id: String) -> float:
	return float(get_event(id).get("value_mult", 1.0))


static func luck(id: String) -> int:
	return int(get_event(id).get("luck", 0))


static func display_name(id: String) -> String:
	return str(get_event(id).get("name", ""))


static func hud_text(id: String) -> String:
	return str(get_event(id).get("hud", ""))


static func color(id: String) -> Color:
	var c: Array = get_event(id).get("color", [1, 1, 1])
	return Color(float(c[0]), float(c[1]), float(c[2]))


static func wants_flash(id: String) -> bool:
	return bool(get_event(id).get("flash", false))
