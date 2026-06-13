class_name AchievementData
## 成就配置（纯数据）。kind 决定达成判定，n 为阈值，reward 为达成奖励金币。
## 判定逻辑在 main.gd::_ach_done()。轻量 16 项，覆盖渔获/财富/收集/品阶/品相/装备多条线。

const LIST := [
	{"id": "first_cast", "name": "初次垂钓", "desc": "钓到第一条鱼", "kind": "catches", "n": 1, "reward": 0},
	{"id": "catch_50", "name": "小有渔获", "desc": "累计钓到 50 条鱼", "kind": "catches", "n": 50, "reward": 200},
	{"id": "catch_300", "name": "老钓客", "desc": "累计钓到 300 条鱼", "kind": "catches", "n": 300, "reward": 800},
	{"id": "catch_1000", "name": "钓鱼大师", "desc": "累计钓到 1000 条鱼", "kind": "catches", "n": 1000, "reward": 3000},
	{"id": "coin_1k", "name": "第一桶金", "desc": "累计卖鱼赚 1,000 金币", "kind": "coins", "n": 1000, "reward": 100},
	{"id": "coin_50k", "name": "富甲一方", "desc": "累计卖鱼赚 50,000 金币", "kind": "coins", "n": 50000, "reward": 2000},
	{"id": "species_10", "name": "鱼类学徒", "desc": "图鉴收集 10 种鱼", "kind": "species", "n": 10, "reward": 500},
	{"id": "species_all", "name": "图鉴大全", "desc": "集齐所有鱼种", "kind": "species_all", "n": 0, "reward": 5000},
	{"id": "tier_rare", "name": "名贵之鱼", "desc": "钓到稀有及以上品阶", "kind": "tier", "n": 2, "reward": 150},
	{"id": "tier_legend", "name": "传说降临", "desc": "钓到传说及以上品阶", "kind": "tier", "n": 4, "reward": 1000},
	{"id": "tier_myth", "name": "国宝入篓", "desc": "钓到神话品阶", "kind": "tier", "n": 5, "reward": 5000},
	{"id": "giant", "name": "巨物猎手", "desc": "钓到一条「巨物」", "kind": "giant", "n": 0, "reward": 600},
	{"id": "perfect", "name": "完美品相", "desc": "钓到完美★★★渔获", "kind": "quality", "n": 3, "reward": 800},
	{"id": "bag_40", "name": "大鱼篓", "desc": "鱼篓扩到 40 格", "kind": "bag", "n": 5, "reward": 0},
	{"id": "rod_5", "name": "精良渔具", "desc": "鱼竿升到 Lv.5", "kind": "rod", "n": 5, "reward": 0},
	{"id": "bait_master", "name": "秘饵传人", "desc": "用上秘制饵", "kind": "bait", "n": 3, "reward": 0},
	{"id": "hook_master", "name": "一线双钩", "desc": "用上双叉钩", "kind": "hook", "n": 3, "reward": 0},
]
