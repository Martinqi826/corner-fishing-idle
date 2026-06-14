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
## tags = 生态标签，决定鱼出现在哪些钓点（SpotData.habitat_tags 与之求交集）：
##   river 河流 / lake 静水湖泊 / stream 山涧溪流 / coast 海岸 / deep 深水 /
##   cold 冷水 / night 夜行 / protected 保护鱼（养殖放流设定）。
## 旧 28 种 id 与数值保持不变（旧存档兼容），全部带 river 标签 → 新手河湾仍是全鱼池、体验不变。
## 60 种鱼谱系/选种依据见 docs/spot-research-20260614.md。
const FISH := {
	# —— 0 普通（常见杂鱼，基本盘）——
	"whitebait": {"name": "白条", "tier": 0, "wmin": 0.01, "wmax": 0.02, "vmin": 1, "vmax": 3, "tags": ["river", "lake"]},
	"topmouth": {"name": "麦穗鱼", "tier": 0, "wmin": 0.01, "wmax": 0.03, "vmin": 1, "vmax": 3, "tags": ["river", "lake"]},
	"loach": {"name": "泥鳅", "tier": 0, "wmin": 0.03, "wmax": 0.15, "vmin": 2, "vmax": 5, "tags": ["river", "lake", "night"]},
	"crucian": {"name": "鲫鱼", "tier": 0, "wmin": 0.1, "wmax": 0.6, "vmin": 3, "vmax": 9, "tags": ["river", "lake"]},
	"bighead": {"name": "鲢鳙", "tier": 0, "wmin": 1.5, "wmax": 3.0, "vmin": 6, "vmax": 14, "tags": ["river", "lake"]},
	"yellowhead": {"name": "黄颡鱼", "tier": 0, "wmin": 0.1, "wmax": 0.3, "vmin": 8, "vmax": 18, "tags": ["river", "lake", "night"]},
	# 新增 · 湖
	"bluegill": {"name": "蓝鳃太阳鱼", "tier": 0, "wmin": 0.05, "wmax": 0.4, "vmin": 2, "vmax": 6, "tags": ["lake"]},
	"icefish": {"name": "银鱼", "tier": 0, "wmin": 0.005, "wmax": 0.02, "vmin": 3, "vmax": 8, "tags": ["lake", "cold"]},
	"bitterling": {"name": "鳑鲏", "tier": 0, "wmin": 0.005, "wmax": 0.02, "vmin": 1, "vmax": 3, "tags": ["lake"]},
	# 新增 · 海
	"sardine": {"name": "沙丁鱼", "tier": 0, "wmin": 0.02, "wmax": 0.1, "vmin": 2, "vmax": 5, "tags": ["coast"]},
	"filefish": {"name": "马面鲀", "tier": 0, "wmin": 0.1, "wmax": 0.5, "vmin": 4, "vmax": 10, "tags": ["coast"]},
	"goby": {"name": "虾虎鱼", "tier": 0, "wmin": 0.01, "wmax": 0.08, "vmin": 1, "vmax": 4, "tags": ["coast"]},
	# —— 1 优良（常见经济鱼）——
	"dace": {"name": "雅罗鱼", "tier": 1, "wmin": 0.3, "wmax": 1.0, "vmin": 14, "vmax": 26, "tags": ["river", "cold"]},
	"carp": {"name": "鲤鱼", "tier": 1, "wmin": 1.0, "wmax": 8.0, "vmin": 16, "vmax": 40, "tags": ["river", "lake"]},
	"grass": {"name": "草鱼", "tier": 1, "wmin": 2.0, "wmax": 12.0, "vmin": 16, "vmax": 42, "tags": ["river", "lake"]},
	"bream": {"name": "鳊鱼", "tier": 1, "wmin": 0.5, "wmax": 2.0, "vmin": 18, "vmax": 36, "tags": ["river", "lake"]},
	"blackcarp": {"name": "青鱼", "tier": 1, "wmin": 4.0, "wmax": 15.0, "vmin": 24, "vmax": 55, "tags": ["river", "lake"]},
	# 新增 · 湖
	"perch": {"name": "河鲈", "tier": 1, "wmin": 0.2, "wmax": 1.2, "vmin": 18, "vmax": 38, "tags": ["lake"]},
	"catfish": {"name": "鲇鱼", "tier": 1, "wmin": 0.5, "wmax": 4.0, "vmin": 16, "vmax": 44, "tags": ["lake", "night"]},
	"swampeel": {"name": "黄鳝", "tier": 1, "wmin": 0.1, "wmax": 0.7, "vmin": 20, "vmax": 45, "tags": ["lake", "night"]},
	"tilapia": {"name": "罗非鱼", "tier": 1, "wmin": 0.2, "wmax": 1.5, "vmin": 14, "vmax": 30, "tags": ["lake"]},
	# 新增 · 海
	"mackerel": {"name": "鲐鱼", "tier": 1, "wmin": 0.2, "wmax": 1.0, "vmin": 14, "vmax": 30, "tags": ["coast"]},
	"small_croaker": {"name": "小黄鱼", "tier": 1, "wmin": 0.1, "wmax": 0.4, "vmin": 20, "vmax": 44, "tags": ["coast"]},
	"mullet": {"name": "鲻鱼", "tier": 1, "wmin": 0.3, "wmax": 2.0, "vmin": 16, "vmax": 36, "tags": ["coast"]},
	"rockfish": {"name": "许氏平鲉", "tier": 1, "wmin": 0.2, "wmax": 1.5, "vmin": 22, "vmax": 48, "tags": ["coast"]},
	# —— 2 稀有（地方名贵，"三花五罗"层 + 湖海中坚）——
	"bass": {"name": "鲈鱼", "tier": 2, "wmin": 0.5, "wmax": 3.0, "vmin": 55, "vmax": 120, "tags": ["river", "lake"]},
	"fangbream": {"name": "三角鲂", "tier": 2, "wmin": 0.5, "wmax": 5.0, "vmin": 60, "vmax": 130, "tags": ["river", "lake"]},
	"barbel": {"name": "花䱻", "tier": 2, "wmin": 0.3, "wmax": 1.5, "vmin": 70, "vmax": 140, "tags": ["river", "stream"]},
	"culter": {"name": "翘嘴鲌", "tier": 2, "wmin": 1.0, "wmax": 5.0, "vmin": 80, "vmax": 170, "tags": ["river", "lake"]},
	"mandarin": {"name": "鳜鱼", "tier": 2, "wmin": 0.5, "wmax": 3.0, "vmin": 90, "vmax": 190, "tags": ["river", "lake", "night"]},
	# 新增 · 湖
	"largemouth": {"name": "大口黑鲈", "tier": 2, "wmin": 0.5, "wmax": 4.0, "vmin": 70, "vmax": 160, "tags": ["lake"]},
	# 新增 · 海
	"seabass": {"name": "海鲈", "tier": 2, "wmin": 0.5, "wmax": 5.0, "vmin": 70, "vmax": 160, "tags": ["coast"]},
	"blackbream": {"name": "黑鲷", "tier": 2, "wmin": 0.3, "wmax": 2.5, "vmin": 65, "vmax": 150, "tags": ["coast"]},
	"hairtail": {"name": "带鱼", "tier": 2, "wmin": 0.2, "wmax": 1.5, "vmin": 60, "vmax": 140, "tags": ["coast", "deep", "night"]},
	"flounder": {"name": "牙鲆", "tier": 2, "wmin": 0.5, "wmax": 4.0, "vmin": 80, "vmax": 180, "tags": ["coast"]},
	"conger": {"name": "海鳗", "tier": 2, "wmin": 0.5, "wmax": 5.0, "vmin": 60, "vmax": 140, "tags": ["coast", "night"]},
	"pufferfish": {"name": "红鳍东方鲀", "tier": 2, "wmin": 0.3, "wmax": 2.0, "vmin": 90, "vmax": 190, "tags": ["coast"]},
	# —— 3 史诗（冷水掠食/高端食用鱼）——
	"snakehead": {"name": "黑鱼", "tier": 3, "wmin": 1.0, "wmax": 6.0, "vmin": 200, "vmax": 420, "tags": ["river", "lake", "night"]},
	"trout": {"name": "虹鳟", "tier": 3, "wmin": 0.8, "wmax": 4.0, "vmin": 210, "vmax": 430, "tags": ["river", "stream", "cold"]},
	"pike": {"name": "白斑狗鱼", "tier": 3, "wmin": 1.0, "wmax": 8.0, "vmin": 220, "vmax": 450, "tags": ["river", "lake", "cold"]},
	"zander": {"name": "梭鲈", "tier": 3, "wmin": 1.0, "wmax": 14.0, "vmin": 240, "vmax": 500, "tags": ["river", "lake"]},
	"longsnout": {"name": "江团", "tier": 3, "wmin": 1.0, "wmax": 5.0, "vmin": 260, "vmax": 520, "tags": ["river", "night"]},
	"lenok": {"name": "细鳞鱼", "tier": 3, "wmin": 0.5, "wmax": 3.0, "vmin": 280, "vmax": 560, "tags": ["river", "stream", "cold"]},
	# 新增 · 湖
	"yellowcheek": {"name": "鳡鱼", "tier": 3, "wmin": 2.0, "wmax": 30.0, "vmin": 240, "vmax": 560, "tags": ["lake"]},
	"eel": {"name": "鳗鲡", "tier": 3, "wmin": 0.3, "wmax": 3.0, "vmin": 220, "vmax": 460, "tags": ["lake", "night"]},
	# 新增 · 海
	"seabream": {"name": "真鲷", "tier": 3, "wmin": 0.5, "wmax": 4.0, "vmin": 240, "vmax": 500, "tags": ["coast"]},
	"spanish_mackerel": {"name": "马鲛鱼", "tier": 3, "wmin": 1.0, "wmax": 8.0, "vmin": 220, "vmax": 470, "tags": ["coast"]},
	"pomfret": {"name": "银鲳", "tier": 3, "wmin": 0.2, "wmax": 1.5, "vmin": 230, "vmax": 480, "tags": ["coast"]},
	"grouper": {"name": "石斑鱼", "tier": 3, "wmin": 0.8, "wmax": 8.0, "vmin": 260, "vmax": 560, "tags": ["coast", "deep"]},
	"yellowcroaker": {"name": "大黄鱼", "tier": 3, "wmin": 0.3, "wmax": 3.0, "vmin": 300, "vmax": 580, "tags": ["coast"]},
	# —— 4 传说（洄游名贵 / 湖海巨物 / 运动钓目标鱼）——
	"koi": {"name": "锦鲤", "tier": 4, "wmin": 1.0, "wmax": 8.0, "vmin": 750, "vmax": 1600, "tags": ["river", "lake"]},
	"salmon": {"name": "大马哈鱼", "tier": 4, "wmin": 3.0, "wmax": 14.0, "vmin": 800, "vmax": 1700, "tags": ["river", "coast", "cold"]},
	"sturgeon": {"name": "施氏鲟", "tier": 4, "wmin": 5.0, "wmax": 30.0, "vmin": 900, "vmax": 1900, "tags": ["river", "lake", "deep"]},
	"taimen": {"name": "哲罗鲑", "tier": 4, "wmin": 3.0, "wmax": 50.0, "vmin": 1000, "vmax": 2200, "tags": ["river", "stream", "cold"]},
	# 新增 · 湖
	"wels_catfish": {"name": "六须鲇", "tier": 4, "wmin": 5.0, "wmax": 100.0, "vmin": 850, "vmax": 2000, "tags": ["lake", "deep", "night"]},
	# 新增 · 海
	"tuna": {"name": "金枪鱼", "tier": 4, "wmin": 5.0, "wmax": 200.0, "vmin": 900, "vmax": 2000, "tags": ["coast", "deep"]},
	"giant_grouper": {"name": "龙趸石斑", "tier": 4, "wmin": 10.0, "wmax": 300.0, "vmin": 1000, "vmax": 2200, "tags": ["coast", "deep"]},
	# —— 5 神话（"活化石"国宝层 + 海洋顶级运动钓；游戏设定为养殖放流/限时个体）——
	"chinese_sturgeon": {"name": "中华鲟", "tier": 5, "wmin": 20.0, "wmax": 300.0, "vmin": 4500, "vmax": 9500, "tags": ["river", "coast", "protected"]},
	"kaluga": {"name": "达氏鳇", "tier": 5, "wmin": 50.0, "wmax": 1000.0, "vmin": 5000, "vmax": 11000, "tags": ["river", "deep", "protected"]},
	# 新增 · 海
	"sailfish": {"name": "旗鱼", "tier": 5, "wmin": 20.0, "wmax": 90.0, "vmin": 5000, "vmax": 10000, "tags": ["coast", "deep"]},
}

# 基础品阶权重（rod Lv.1）：58/25/11/4.5/1.3/0.2（%）
const BASE_WEIGHTS := {0: 58.0, 1: 25.0, 2: 11.0, 3: 4.5, 4: 1.3, 5: 0.2}

# —— 星级品质（WEBFISHING 模板：逐级 roll，鱼饵决定每级通过率）——
const QUALITY_NAMES := ["", "上品", "极品", "完美"]
const QUALITY_MULTS := [1.0, 1.8, 4.0, 8.0]
## 鱼饵：金币永久升级（线性进阶，参考 Melvor 自动化的游戏币门控）。
## probs[i] = 从 i-1 星升到 i 星的通过率；P(★)=p1，P(★★)=p1·p2，P(★★★)=p1·p2·p3。
const BAITS := [
	{"name": "蚯蚓", "cost": 0, "probs": [1.0, 0.08, 0.02, 0.05], "desc": "河边随手挖的"},
	{"name": "红虫", "cost": 800, "probs": [1.0, 0.22, 0.10, 0.08], "desc": "冬钓利器，上品率明显提升"},
	{"name": "活虾", "cost": 5000, "probs": [1.0, 0.45, 0.18, 0.12], "desc": "大鱼爱追活食"},
	{"name": "秘制饵", "cost": 24000, "probs": [1.0, 0.70, 0.35, 0.18], "desc": "老钓翁的祖传配方"},
]

# —— 鱼钩：第三条成长线，决定「双钩」几率（一次钓上两条）。鱼竿管稀有度、鱼饵管星级、鱼钩管产量。——
const HOOKS := [
	{"name": "基础鱼钩", "cost": 0, "double": 0.0, "desc": "普普通通的单钩"},
	{"name": "宽门钩", "cost": 2000, "double": 0.10, "desc": "钩门更宽，偶尔双钩"},
	{"name": "倒刺钩", "cost": 12000, "double": 0.20, "desc": "倒刺挂得牢，双钩更常见"},
	{"name": "双叉钩", "cost": 60000, "double": 0.32, "desc": "一线两钩，常常成对上鱼"},
]


## 星级抽取：逐级 roll，失败即停。
static func roll_quality(bait_idx: int, rng: RandomNumberGenerator) -> int:
	var probs: Array = BAITS[clampi(bait_idx, 0, BAITS.size() - 1)]["probs"]
	var q := 0
	for lvl in range(1, probs.size()):
		if rng.randf() < float(probs[lvl]):
			q = lvl
		else:
			break
	return q


static func quality_label(q: int) -> String:
	if q <= 0:
		return ""
	return QUALITY_NAMES[clampi(q, 0, 3)] + "★".repeat(q) + "·"


## 按权重抽品阶，再在该品阶内随机选种，返回鱼 id。
## pool 非空时只在该钓点鱼池内抽（多钓点生态）：抽到的品阶在池内无鱼时，
## 就近降阶/升阶到池内最近有鱼的品阶，绝不逸出到全鱼池（保证钓点隔离）。
static func roll_fish(weights: Dictionary, rng: RandomNumberGenerator, pool: Array = []) -> String:
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
	var ids: Array = pool if not pool.is_empty() else FISH.keys()
	var candidates := _ids_of_tier(ids, tier)
	if candidates.is_empty():
		# 就近品阶回退（先降后升），始终留在同一鱼池内
		for d in range(1, 6):
			candidates = _ids_of_tier(ids, tier - d)
			if candidates.is_empty():
				candidates = _ids_of_tier(ids, tier + d)
			if not candidates.is_empty():
				break
	if candidates.is_empty():
		candidates = ids
	return candidates[rng.randi() % candidates.size()]


static func _ids_of_tier(ids: Array, tier: int) -> Array:
	var out: Array = []
	if tier < 0 or tier > 5:
		return out
	for id in ids:
		if int(FISH[id]["tier"]) == tier:
			out.append(id)
	return out


static func tags_of(id: String) -> Array:
	return FISH[id].get("tags", ["river"]) if FISH.has(id) else []


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


## 钓一条鱼：抽种 + 抽体重 + 抽星级 + 算价值。返回 {"id", "w"(kg), "v"(金币), "q"(星级)}。
## 体重 roll 偏向小个体（k²），卖价与体重线性挂钩（Fisch 模型）再乘星级倍率。
## luck：额外品阶运气（如鱼汛事件 +N），仅抬高高阶权重，不影响鱼价基准。
## pool 非空时只在该钓点鱼池内出鱼（多钓点）；为空保持旧行为（全鱼池）。
static func roll_catch(rng: RandomNumberGenerator, rod_level: int, bait_idx := 0, luck := 0, pool: Array = []) -> Dictionary:
	var id := roll_fish(weights_for_rod(rod_level + luck), rng, pool)
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
	var q := roll_quality(bait_idx, rng)
	return {
		"id": id,
		"w": snappedf(w, 0.01),
		"v": max(1, int(round(base * rod_mult * jitter * QUALITY_MULTS[q]))),
		"q": q,
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
