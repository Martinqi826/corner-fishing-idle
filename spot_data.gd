class_name SpotData
## 钓点数据（纯数据）：多钓点生态挂机的可扩展骨架。
## 每个钓点用 habitat_tags 圈定鱼池（与 FishData 每条鱼的 tags 求交集），
## event_pool 决定可触发的随机事件（见 event_data.gd），可选 wait/value/luck 修正整体手感。
## 谱系/选种依据见 docs/spot-research-20260614.md（FishBase 生境 + 中文垂钓习性 + IGFA 目标鱼）。
##
## unlock：{} 表示默认解锁；否则 {"kind": catches/coins/species, "n": 阈值}。
## habitat_tags：river/lake/stream/coast/deep/cold/night/protected（与 FishData tags 对应）。
## order_bias：每日订单优先从本钓点鱼池生成（保证订单可在当前钓点完成）。
## wait_mult/value_mult/luck_bonus：钓点常驻系数（叠加在鱼竿/事件之上），默认中性。

const SPOTS := {
	"river_bend": {
		"name": "新手河湾",
		"desc": "最初的那方静水，缓流绕过雪岸。从白条到国宝鲟，什么都可能上钩——新手友好的全能钓点。",
		"unlock": {},  # 默认解锁
		"habitat_tags": ["river"],
		"event_pool": ["fish_run", "lucky_current", "morning_fog", "drift_crate"],
		"bg_key": "river_bend",
		"order_bias": "river",
		"wait_mult": 1.0,
		"value_mult": 1.0,
		"luck_bonus": 0,
	},
	"still_lake": {
		"name": "静水湖泊",
		"desc": "水草丰茂的冬日湖湾，掠食者潜伏在乱石与树根间。鲈、鳜、黑鱼、狗鱼当家，偶有巨鲟与欧鲶。",
		"unlock": {"kind": "catches", "n": 80},
		"habitat_tags": ["lake"],
		"event_pool": ["fish_run", "morning_fog", "cold_front", "lucky_current"],
		"bg_key": "still_lake",
		"order_bias": "lake",
		"wait_mult": 1.08,    # 静水咬钩略慢
		"value_mult": 1.06,   # 但鱼更肥、更值钱
		"luck_bonus": 0,
	},
	"coast_pier": {
		"name": "海岸码头",
		"desc": "海风咸涩，浪拍木桩，小灯在栈桥尽头摇。海鲈、鲷、带鱼、石斑、马鲛轮番登场，深处藏着金枪与旗鱼。",
		"unlock": {"kind": "catches", "n": 300},
		"habitat_tags": ["coast"],
		"event_pool": ["fish_run", "tide_in", "drift_crate", "protected_release"],
		"bg_key": "coast_pier",
		"order_bias": "coast",
		"wait_mult": 0.96,    # 海里鱼多，咬钩略勤
		"value_mult": 1.12,   # 海鱼整体更值钱
		"luck_bonus": 0,
	},
}

## 显示与解锁推荐顺序（UI 列表、解锁提示用）。
const SPOT_ORDER := ["river_bend", "still_lake", "coast_pier"]

## 默认钓点（旧存档迁移落点）。
const DEFAULT_SPOT := "river_bend"


static func has(id: String) -> bool:
	return SPOTS.has(id)


static func get_spot(id: String) -> Dictionary:
	return SPOTS.get(id, SPOTS[DEFAULT_SPOT])


static func display_name(id: String) -> String:
	return str(get_spot(id)["name"])


## 钓点鱼池：FishData 中 tags 与本钓点 habitat_tags 有交集的鱼 id（按品阶、id 稳定排序）。
## 没有 tags 的鱼默认视为 river（保证扩 tags 之前 river_bend 仍是全鱼池，旧体验不变）。
static func pool_for(id: String) -> Array:
	var spot := get_spot(id)
	var want: Array = spot.get("habitat_tags", ["river"])
	var out: Array = []
	for fid in FishData.FISH:
		var tags: Array = FishData.FISH[fid].get("tags", ["river"])
		for t in want:
			if t in tags:
				out.append(fid)
				break
	out.sort_custom(func(a, b):
		var ta := FishData.tier_of(str(a))
		var tb := FishData.tier_of(str(b))
		if ta != tb:
			return ta < tb
		return str(a) < str(b))
	return out


## 该钓点是否默认解锁（无 unlock 条件）。
static func default_unlocked(id: String) -> bool:
	return (get_spot(id).get("unlock", {}) as Dictionary).is_empty()


## 解锁条件一句话（UI 显示）。已解锁/默认解锁返回空串。
static func unlock_text(id: String) -> String:
	var u: Dictionary = get_spot(id).get("unlock", {})
	if u.is_empty():
		return ""
	match str(u.get("kind", "")):
		"catches": return "累计钓到 %d 条鱼解锁" % int(u.get("n", 0))
		"coins": return "累计卖鱼赚 %d 金币解锁" % int(u.get("n", 0))
		"species": return "图鉴收集 %d 种鱼解锁" % int(u.get("n", 0))
	return ""


## 判定某钓点是否满足解锁条件。catches/coins 用终身累计，species 用图鉴种数。
static func unlock_met(id: String, lifetime_catches: int, lifetime_coins: int, species: int) -> bool:
	var u: Dictionary = get_spot(id).get("unlock", {})
	if u.is_empty():
		return true
	var n := int(u.get("n", 0))
	match str(u.get("kind", "")):
		"catches": return lifetime_catches >= n
		"coins": return lifetime_coins >= n
		"species": return species >= n
	return true


## 钓点常驻系数访问器（带默认值，便于 main 安全读取）。
static func wait_mult(id: String) -> float:
	return float(get_spot(id).get("wait_mult", 1.0))


static func value_mult(id: String) -> float:
	return float(get_spot(id).get("value_mult", 1.0))


static func luck_bonus(id: String) -> int:
	return int(get_spot(id).get("luck_bonus", 0))


static func event_pool(id: String) -> Array:
	return get_spot(id).get("event_pool", [])
