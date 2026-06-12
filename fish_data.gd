class_name FishData
## 鱼种图鉴与抽取配置（纯数据）。仿 godot-pet-idle 的稀有度+权重分层抽取。
## value = 钓上后获得的金币（vmin..vmax 随机）。

const RARITY_NAMES := ["普通", "稀有", "史诗", "传说"]
const RARITY_COLORS := [
	Color(0.78, 0.78, 0.80),  # 0 普通 灰
	Color(0.35, 0.65, 1.00),  # 1 稀有 蓝
	Color(0.78, 0.42, 1.00),  # 2 史诗 紫
	Color(1.00, 0.76, 0.20),  # 3 传说 金
]

const FISH := {
	# —— 普通 ——
	"crucian": {"name": "鲫鱼", "rarity": 0, "vmin": 3, "vmax": 6},
	"carp": {"name": "鲤鱼", "rarity": 0, "vmin": 5, "vmax": 9},
	"whitebait": {"name": "白条", "rarity": 0, "vmin": 2, "vmax": 5},
	"loach": {"name": "泥鳅", "rarity": 0, "vmin": 4, "vmax": 7},
	# —— 稀有 ——
	"bass": {"name": "鲈鱼", "rarity": 1, "vmin": 14, "vmax": 24},
	"grass": {"name": "草鱼", "rarity": 1, "vmin": 12, "vmax": 20},
	"mandarin": {"name": "鳜鱼", "rarity": 1, "vmin": 18, "vmax": 30},
	# —— 史诗 ——
	"snakehead": {"name": "黑鱼", "rarity": 2, "vmin": 48, "vmax": 80},
	"trout": {"name": "鳟鱼", "rarity": 2, "vmin": 56, "vmax": 92},
	"sturgeon": {"name": "鲟鱼", "rarity": 2, "vmin": 70, "vmax": 110},
	# —— 传说 ——
	"koi": {"name": "锦鲤", "rarity": 3, "vmin": 200, "vmax": 360},
	"arowana": {"name": "金龙鱼", "rarity": 3, "vmin": 280, "vmax": 480},
}

# 基础稀有度权重（鱼竿等级/鱼饵后续在此基础上调整）
const BASE_WEIGHTS := {0: 70.0, 1: 22.0, 2: 6.5, 3: 1.5}


## 按权重抽稀有度，再在该稀有度内随机选一种鱼，返回鱼 id。
static func roll_fish(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for r in weights:
		total += weights[r]
	var pick := rng.randf() * total
	var rarity := 0
	for r in weights:
		pick -= weights[r]
		if pick <= 0.0:
			rarity = r
			break
	var candidates: Array = []
	for id in FISH:
		if FISH[id]["rarity"] == rarity:
			candidates.append(id)
	if candidates.is_empty():
		candidates = FISH.keys()
	return candidates[rng.randi() % candidates.size()]


## 鱼竿等级 -> 稀有度权重（等级越高，高稀有占比越大）。
static func weights_for_rod(rod_level: int) -> Dictionary:
	var lv := float(rod_level - 1)
	return {
		0: maxf(20.0, BASE_WEIGHTS[0] - lv * 3.0),
		1: BASE_WEIGHTS[1] + lv * 1.2,
		2: BASE_WEIGHTS[2] + lv * 1.4,
		3: BASE_WEIGHTS[3] + lv * 0.5,
	}


## 一条鱼的金币价值（含鱼竿增值加成）。
static func value_of(id: String, rng: RandomNumberGenerator, rod_level: int) -> int:
	var f: Dictionary = FISH[id]
	var base := rng.randi_range(int(f["vmin"]), int(f["vmax"]))
	var mult := 1.0 + float(rod_level - 1) * 0.08
	return int(round(base * mult))
