class_name SaveSystem
## 存档系统（从 main.gd 拆出）：序列化 / 反序列化 / 迁移 / 原子写 / .bak 回退。
## 纯函数，游戏状态在主节点 g 上读写。main 只保留薄壳调用 + 离线结算。
## 存档结构升级历史：v1 id列表→图鉴纪录轴；inv 三→四→五元组；dex 2→4元组徽章；
## daily_order 补 kind/tier/minw；新增 hook/weekly/day_stat/best_q/giant/ach/seen_intro/focus/win_pos。

const OFFLINE_CAP := 8.0 * 3600.0


## 把主节点状态收集成可序列化字典。
static func collect(g) -> Dictionary:
	var inv: Array = []
	for c in g.inventory:
		inv.append([c["id"], c["w"], c["v"], int(c.get("q", 0)),
			1 if bool(c.get("lock", false)) else 0])
	var data := {
		"ver": 7,
		"coins": g.coins,
		"rod_level": g.rod_level,
		"bag_level": g.bag_level,
		"bait": g.bait_level,
		"hook": g.hook_level,
		"inv": inv,
		"lt_coins": g.lifetime_coins,
		"lt_catches": g.lifetime_catches,
		"dex": dex_to_save(g),
		"daily_order": g.daily_order,
		"weekly": g.weekly,
		"day_stat": g.day_stat,
		"best_q": g.best_quality,
		"giant": g.caught_giant,
		"ach": g.achievements_done.keys(),
		"opacity": g._opacity,
		"focus": g.focus_mode,
		"seen_intro": g.seen_intro,
		"ts": Time.get_unix_time_from_system(),
	}
	if DisplayServer.get_name() != "headless":
		var wp := DisplayServer.window_get_position()
		data["win_pos"] = [wp.x, wp.y]
	return data


static func dex_to_save(g) -> Dictionary:
	var out := {}
	for id in g.dex:
		var r: Dictionary = g.dex[id]
		out[id] = [int(r["n"]), float(r["w"]),
			1 if bool(r.get("big", false)) else 0,
			1 if bool(r.get("perf", false)) else 0]
	return out


## 原子写：临时文件 → 旧档移 .bak → 改名顶替。防进程被杀时截断主档。
static func write_atomic(path: String, data: Dictionary) -> void:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	DirAccess.rename_absolute(tmp, path)


## 读一个存档文件，解析失败返回 null。
static func read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else null


## 把存档字典恢复到主节点（含各版本迁移）。不含离线结算与成就补登（留在 main）。
static func apply(g, data: Dictionary) -> void:
	g.coins = int(data.get("coins", 0))
	g.rod_level = max(1, int(data.get("rod_level", 1)))
	g.bag_level = max(1, int(data.get("bag_level", 1)))  # v1 无此字段 → 1
	g.bait_level = clampi(int(data.get("bait", 0)), 0, FishData.BAITS.size() - 1)  # v2 及更早 → 蚯蚓
	g.hook_level = clampi(int(data.get("hook", 0)), 0, FishData.HOOKS.size() - 1)  # 旧档 → 基础钩
	g.inventory = []
	for e in data.get("inv", []):           # v1 无此字段 → 空背包
		if e is Array and e.size() >= 3 and FishData.FISH.has(str(e[0])):
			g.inventory.append({"id": str(e[0]), "w": float(e[1]), "v": int(e[2]),
				"q": int(e[3]) if e.size() >= 4 else 0,    # v2 三元组 → 无星级
				"lock": e.size() >= 5 and int(e[4]) == 1}) # v3 及更早 → 未锁定
	g.lifetime_coins = int(data.get("lt_coins", 0))
	g.lifetime_catches = int(data.get("lt_catches", 0))
	g.best_quality = int(data.get("best_q", 0))
	g.caught_giant = bool(data.get("giant", false))
	g.achievements_done = {}
	for id in data.get("ach", []):
		g.achievements_done[str(id)] = true
	g.dex = {}
	var dex_raw: Variant = data.get("dex", [])
	if dex_raw is Dictionary:                # v4+：{id: [n, w_max, big?, perf?]}
		for id in dex_raw:
			if FishData.FISH.has(str(id)) and dex_raw[id] is Array and (dex_raw[id] as Array).size() >= 2:
				var e: Array = dex_raw[id]
				g.dex[str(id)] = {"n": int(e[0]), "w": float(e[1]),
					"big": e.size() >= 3 and int(e[2]) == 1,
					"perf": e.size() >= 4 and int(e[3]) == 1}
	elif dex_raw is Array:                   # v1~v3：仅 id 列表 → 纪录从头积累
		for id in dex_raw:
			if FishData.FISH.has(str(id)):
				g.dex[str(id)] = {"n": 1, "w": 0.0, "big": false, "perf": false}
	g.daily_order = {}
	var order_raw: Variant = data.get("daily_order", {})
	if order_raw is Dictionary:
		var od: Dictionary = order_raw
		var fish_id := str(od.get("fish", ""))
		if FishData.FISH.has(fish_id):
			g.daily_order = {
				"date": str(od.get("date", "")),
				"kind": str(od.get("kind", "species")),  # 旧档无 kind → 指定鱼种
				"fish": fish_id,
				"need": max(1, int(od.get("need", 1))),
				"tier": clampi(int(od.get("tier", 1)), 1, 5),
				"minw": float(od.get("minw", 1.0)),
				"done": bool(od.get("done", false)),
			}
	var wk_raw: Variant = data.get("weekly", {})  # 旧档无 → main._ensure_weekly 现生成
	if wk_raw is Dictionary and wk_raw.has("week") and wk_raw.has("kind"):
		g.weekly = {
			"week": int(wk_raw.get("week", -1)),
			"kind": str(wk_raw.get("kind", "catches")),
			"target": max(1, int(wk_raw.get("target", 1))),
			"base": int(wk_raw.get("base", 0)),
			"reward": int(wk_raw.get("reward", 0)),
			"done": bool(wk_raw.get("done", false)),
		}
	var ds_raw: Variant = data.get("day_stat", {})  # 旧档无 → main._ensure_day_stat 现生成
	if ds_raw is Dictionary and ds_raw.has("date"):
		g.day_stat = {
			"date": str(ds_raw.get("date", "")),
			"catches": int(ds_raw.get("catches", 0)),
			"coins": int(ds_raw.get("coins", 0)),
		}
	g._opacity = float(data.get("opacity", 1.0))
	g._set_opacity(g._opacity)
	g.seen_intro = bool(data.get("seen_intro", true))  # 有存档=老玩家，默认已看过引导
	if bool(data.get("focus", false)):
		g._set_focus(true)
	var wp: Variant = data.get("win_pos", null)
	if wp is Array and wp.size() >= 2:
		g._saved_win_pos = Vector2i(int(wp[0]), int(wp[1]))
