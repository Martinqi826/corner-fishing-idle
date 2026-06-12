class_name FishData
## 鱼种图鉴与抽取配置（纯数据）。
## 谱系依据：中国北方冬季冰钓真实鱼种（黑龙江"三花五罗"名贵层 + 冷水鲑科高端层），
## 品阶概率/价格倍率/体重定价参考 Stardew/Fisch/WEBFISHING/动森 调研（docs/fish-research.md）。
## 6 档品阶（见色识阶：灰绿蓝紫橙红）；卖价与体重线性挂钩，大个体更值钱。

const TIER_NAMES := ["普通", "优良", "稀有", "史诗", "传说", "神话"]
const TIER_COLORS := [
	Color(0.78, 0.78, 0.80),  # 0 普通 灰
	Color(0.35, 0.78, 0.30),  # 1 优良 绿
	Color(0.30, 0.62, 0.95),  # 2 稀有 蓝
	Color(0.72, 0.42, 0.95),  # 3 史诗 紫
	Color(1.00, 0.55, 0.12),  # 4 传说 橙
	Color(1.00, 0.38, 0.32),  # 5 神话 红
]

## wmin/wmax = 体重区间(kg)，vmin/vmax = 对应体重端点的卖价(金币)，按体重线性插值。
## 相邻品阶价值倍率 ≈ ×3.5~4.5（调研结论），全谱跨度 ≈ ×5000。
const FISH := {
	# —— 0 普通（常见杂鱼，冰钓基本盘）——
	"whitebait": {"name": "白条", "tier": 0, "wmin": 0.01, "wmax": 0.02, "vmin": 1, "vmax": 3},
	"topmouth": {"name": "麦穗鱼", "tier": 0, "wmin": 0.01, "wmax": 0.03, "vmin": 1, "vmax": 3},
	"loach": {"name": "泥鳅", "tier": 0, "wmin": 0.03, "wmax": 0.15, "vmin": 2, "vmax": 5},
	"crucian": {"name": "鲫鱼", "tier": 0, "wmin": 0.1, "wmax": 0.6, "vmin": 3, "vmax": 9},
	"bighead": {"name": "鲢鳙", "tier": 0, "wmin": 1.5, "wmax": 3.0, "vmin": 6, "vmax": 14},
	"yellowhead": {"name": "黄颡鱼", "tier": 0, "wmin": 0.1, "wmax": 0.3, "vmin": 8, "vmax": 18},
	# —— 1 优良（常见经济鱼）——
	"dace": {"name": "雅罗鱼", "tier": 1, "wmin": 0.3, "wmax": 1.0, "vmin": 14, "vmax": 26},
	"carp": {"name": "鲤鱼", "tier": 1, "wmin": 1.0, "wmax": 8.0, "vmin": 16, "vmax": 40},
	"grass": {"name": "草鱼", "tier": 1, "wmin": 2.0, "wmax": 12.0, "vmin": 16, "vmax": 42},
	"bream": {"name": "鳊鱼", "tier": 1, "wmin": 0.5, "wmax": 2.0, "vmin": 18, "vmax": 36},
	"blackcarp": {"name": "青鱼", "tier": 1, "wmin": 4.0, "wmax": 15.0, "vmin": 24, "vmax": 55},
	# —— 2 稀有（地方名贵，"三花五罗"层）——
	"bass": {"name": "鲈鱼", "tier": 2, "wmin": 0.5, "wmax": 3.0, "vmin": 55, "vmax": 120},
	"fangbream": {"name": "三角鲂", "tier": 2, "wmin": 0.5, "wmax": 5.0, "vmin": 60, "vmax": 130},
	"barbel": {"name": "花䱻", "tier": 2, "wmin": 0.3, "wmax": 1.5, "vmin": 70, "vmax": 140},
	"culter": {"name": "翘嘴鲌", "tier": 2, "wmin": 1.0, "wmax": 5.0, "vmin": 80, "vmax": 170},
	"mandarin": {"name": "鳜鱼", "tier": 2, "wmin": 0.5, "wmax": 3.0, "vmin": 90, "vmax": 190},
	# —— 3 史诗（冷水掠食/高端食用鱼）——
	"snakehead": {"name": "黑鱼", "tier": 3, "wmin": 1.0, "wmax": 6.0, "vmin": 200, "vmax": 420},
	"trout": {"name": "虹鳟", "tier": 3, "wmin": 0.8, "wmax": 4.0, "vmin": 210, "vmax": 430},
	"pike": {"name": "白斑狗鱼", "tier": 3, "wmin": 1.0, "wmax": 8.0, "vmin": 220, "vmax": 450},
	"zander": {"name": "梭鲈", "tier": 3, "wmin": 1.0, "wmax": 14.0, "vmin": 240, "vmax": 500},
	"longsnout": {"name": "江团", "tier": 3, "wmin": 1.0, "wmax": 5.0, "vmin": 260, "vmax": 520},
	"lenok": {"name": "细鳞鱼", "tier": 3, "wmin": 0.5, "wmax": 3.0, "vmin": 280, "vmax": 560},
	# —— 4 传说（洄游名贵/吉祥彩蛋）——
	"koi": {"name": "锦鲤", "tier": 4, "wmin": 1.0, "wmax": 8.0, "vmin": 750, "vmax": 1600},
	"salmon": {"name": "大马哈鱼", "tier": 4, "wmin": 3.0, "wmax": 14.0, "vmin": 800, "vmax": 1700},
	"sturgeon": {"name": "施氏鲟", "tier": 4, "wmin": 5.0, "wmax": 30.0, "vmin": 900, "vmax": 1900},
	"taimen": {"name": "哲罗鲑", "tier": 4, "wmin": 3.0, "wmax": 50.0, "vmin": 1000, "vmax": 2200},
	# —— 5 神话（"活化石"国宝层，游戏设定为养殖放流个体）——
	"chinese_sturgeon": {"name": "中华鲟", "tier": 5, "wmin": 20.0, "wmax": 300.0, "vmin": 4500, "vmax": 9500},
	"kaluga": {"name": "达氏鳇", "tier": 5, "wmin": 50.0, "wmax": 1000.0, "vmin": 5000, "vmax": 11000},
}

# 基础品阶权重（rod Lv.1）：58/25/11/4.5/1.3/0.2（%）
const BASE_WEIGHTS := {0: 58.0, 1: 25.0, 2: 11.0, 3: 4.5, 4: 1.3, 5: 0.2}


## 按权重抽品阶，再在该品阶内随机选种，返回鱼 id。
static func roll_fish(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for r in weights:
		total += weights[r]
	var pick := rng.randf() * total
	var tier := 0
	for r in weights:
		pick -= weights[r]
		if pick <= 0.0:
			tier = r
			break
	var candidates: Array = []
	for id in FISH:
		if FISH[id]["tier"] == tier:
			candidates.append(id)
	if candidates.is_empty():
		candidates = FISH.keys()
	return candidates[rng.randi() % candidates.size()]


## 鱼竿等级 -> 品阶权重（等级越高，高阶占比越大）。
static func weights_for_rod(rod_level: int) -> Dictionary:
	var lv := float(rod_level - 1)
	return {
		0: maxf(16.0, BASE_WEIGHTS[0] - lv * 2.4),
		1: BASE_WEIGHTS[1] + lv * 0.7,
		2: BASE_WEIGHTS[2] + lv * 0.85,
		3: BASE_WEIGHTS[3] + lv * 0.50,
		4: BASE_WEIGHTS[4] + lv * 0.22,
		5: BASE_WEIGHTS[5] + lv * 0.05,
	}


## 钓一条鱼：抽种 + 抽体重 + 算价值。返回 {"id", "w"(kg), "v"(金币)}。
## 体重 roll 偏向小个体（k²），卖价与体重线性挂钩（Fisch 模型）。
static func roll_catch(rng: RandomNumberGenerator, rod_level: int) -> Dictionary:
	var id := roll_fish(weights_for_rod(rod_level), rng)
	var f: Dictionary = FISH[id]
	var k := rng.randf()
	k = k * k  # 偏向小体型，大鱼稀罕
	var w: float = lerpf(float(f["wmin"]), float(f["wmax"]), k)
	var size_ratio: float = 0.0
	if float(f["wmax"]) > float(f["wmin"]):
		size_ratio = (w - float(f["wmin"])) / (float(f["wmax"]) - float(f["wmin"]))
	var base: float = lerpf(float(f["vmin"]), float(f["vmax"]), size_ratio)
	var rod_mult := 1.0 + float(rod_level - 1) * 0.08
	var jitter := rng.randf_range(0.92, 1.08)
	return {
		"id": id,
		"w": snappedf(w, 0.01),
		"v": max(1, int(round(base * rod_mult * jitter))),
	}


## 体型前缀：同种鱼里的大个体（约 13%）标「大·」，顶级个体（约 2.5%）标「巨物·」。
static func size_tag(id: String, w: float) -> String:
	var f: Dictionary = FISH[id]
	if float(f["wmax"]) <= float(f["wmin"]):
		return ""
	var r := (w - float(f["wmin"])) / (float(f["wmax"]) - float(f["wmin"]))
	if r >= 0.95:
		return "巨物·"
	if r >= 0.75:
		return "大·"
	return ""


static func tier_of(id: String) -> int:
	return int(FISH[id]["tier"])


static func display_name(id: String) -> String:
	return str(FISH[id]["name"])
