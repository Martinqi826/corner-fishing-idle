extends Node

const MANIFEST_PATH := "res://assets/audio/audio_manifest.json"
const SETTINGS_PATH := "user://audio_settings.json"
const SFX_POOL_SIZE := 8
const SILENT_DB := -80.0

const DEFAULT_COOLDOWNS_MS := {
	"ui_click": 55,
	"ui_error": 120,
	"coin": 100,
	"cast": 180,
	"bobber_splash": 160,
	"bite": 250,
}

var master_volume := 0.8
var sfx_volume := 0.85
var ambience_volume := 0.42
var muted := false

var _streams := {}
var _metadata := {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _ambience_player: AudioStreamPlayer   # water base 层 player（保留旧名以兼容引用）
var _last_played_ms := {}

# —— 分层环境音床：多条循环音叠加，按「钓点生态 × 昼夜时段」配方平滑淡入淡出 ——
# 缺素材的层自动不建 player、配方里也被跳过 → 零素材时优雅退化为现有单层水声，不报错不退化。
# 即使只剩 water 一层，配方里的时段动态增益（夜静/晨昏柔/白昼足）也能听出氛围差异。
const AMB_FADE := 2.5   # 层增益淡入淡出到位的近似秒数（柔和过渡，绝不突变）
const AMBIENCE_LAYERS := [
	"ambience_water_loop",  # 通用静水底噪（已有素材；多数淡水钓点的 base）
	"amb_stream_loop",      # 急流溪声（山溪/河湾，比 water 更有流动感）
	"amb_birds_day",        # 白昼林鸟啁啾（淡水/林地，昼与晨昏）
	"amb_wind_loop",        # 旷野风声（湖泊/极地，轻铺）
	"amb_night_insects",    # 夜虫（暖季夜晚，非极地/海洋）
	"amb_waves_loop",       # 海浪涌动（海洋钓点 base）
	"amb_gulls_day",        # 海鸥（海岸，昼）
	"amb_cave_drip",        # 洞穴水滴回声（cavern_pool base）
]
# 钓点 → 生态分类（决定环境床配方）；未列出的回退 freshwater。
const SPOT_BIOME := {
	"river_bend": "freshwater", "still_lake": "lake", "mountain_stream": "stream",
	"urban_pond": "freshwater", "coast_pier": "sea", "estuary": "sea",
	"deep_sea": "sea", "coral_reef": "sea", "polar_lake": "polar", "cavern_pool": "cavern",
}
var _amb := {}                 # id -> {player, gain, target}
var _amb_scene_key := ""       # 当前 "biome|phase"，相同则不重排配方


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_manifest()
	_build_players()
	_load_settings()
	_apply_current_volumes()


func _exit_tree() -> void:
	stop_ambience()
	for player in _sfx_players:
		player.stop()
		player.stream = null
	for id in _amb:
		_amb[id]["player"].stream = null
	_amb.clear()
	_streams.clear()
	_metadata.clear()


func has(id: String) -> bool:
	return _streams.has(id)


func play(id: String) -> void:
	if id == "ambience_water_loop":
		start_ambience()
	else:
		play_sfx(id)


func play_ui(id: String) -> void:
	play_sfx(id)


func play_sfx(id: String) -> void:
	if muted or not _streams.has(id) or _is_on_cooldown(id):
		return
	if _sfx_players.is_empty():
		return
	var player := _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	player.stop()
	player.stream = _streams[id]
	player.volume_db = _sfx_db()
	player.play()


## 兼容旧入口：未设置过场景时，起一个默认淡水白昼床（正常路径走 set_ambience_scene）。
func start_ambience() -> void:
	if _amb_scene_key == "":
		set_ambience_scene("river_bend", "day")


func stop_ambience() -> void:
	for id in _amb:
		_amb[id]["target"] = 0.0
		_amb[id]["gain"] = 0.0
		var pl: AudioStreamPlayer = _amb[id]["player"]
		if pl.playing:
			pl.stop()


## 按「钓点生态 × 时段」铺设环境床：出现的层淡入到目标增益，未出现的层淡出到 0。
## 缺素材的层（未建 player）自动跳过；同一配方重复调用直接返回，不打断当前过渡。
func set_ambience_scene(spot_key: String, phase: String) -> void:
	var biome := str(SPOT_BIOME.get(spot_key, "freshwater"))
	var key := biome + "|" + phase
	if key == _amb_scene_key:
		return
	_amb_scene_key = key
	var recipe := _ambience_recipe(biome, phase)
	for id in _amb:
		var want := float(recipe.get(id, 0.0))
		_amb[id]["target"] = want
		if want > 0.0:
			var pl: AudioStreamPlayer = _amb[id]["player"]
			if not pl.playing:
				pl.play()


## 环境床配方：返回 {层id: 相对增益0..1}。先按生态选层，再叠加全局时段动态。
func _ambience_recipe(biome: String, phase: String) -> Dictionary:
	var r := {}
	var night := phase == "night"
	var golden := phase == "dawn" or phase == "dusk"
	match biome:
		"sea":
			r["amb_waves_loop"] = 1.0
			r["ambience_water_loop"] = 0.25       # 海浪缺素材时仍有水声兜底
			if not night:
				r["amb_gulls_day"] = 0.6 if phase == "day" else 0.4
		"cavern":
			r["amb_cave_drip"] = 0.9
			r["ambience_water_loop"] = 0.3
		"stream":
			r["amb_stream_loop"] = 0.9
			r["ambience_water_loop"] = 0.4
			if not night:
				r["amb_birds_day"] = 0.5 if phase == "day" else 0.35
		"lake":
			r["ambience_water_loop"] = 0.7
			r["amb_wind_loop"] = 0.45
			if not night:
				r["amb_birds_day"] = 0.4 if phase == "day" else 0.3
			if night:
				r["amb_night_insects"] = 0.35
		"polar":
			r["ambience_water_loop"] = 0.5
			r["amb_wind_loop"] = 0.7              # 极地风更显，无虫鸟
		_:  # freshwater
			r["ambience_water_loop"] = 0.8
			if not night:
				r["amb_birds_day"] = 0.55 if phase == "day" else 0.4
			if night:
				r["amb_night_insects"] = 0.4
	# 全局时段动态：夜最静、晨昏略柔、白昼最足（只有 water 一层时也能听出差异）
	var bed := 1.0
	if night:
		bed = 0.7
	elif golden:
		bed = 0.88
	for k in r:
		r[k] = clampf(float(r[k]) * bed, 0.0, 1.0)
	return r


## 每帧把各环境层增益平滑推向目标，并据此设音量；淡出到 0 的层停播省资源。
func _process(delta: float) -> void:
	if _amb.is_empty():
		return
	var step := delta / AMB_FADE
	for id in _amb:
		var L: Dictionary = _amb[id]
		var g: float = move_toward(float(L["gain"]), float(L["target"]), step)
		if g == float(L["gain"]):
			continue
		L["gain"] = g
		var pl: AudioStreamPlayer = L["player"]
		pl.volume_db = _amb_layer_db(g)
		if g <= 0.0001 and float(L["target"]) <= 0.0 and pl.playing:
			pl.stop()


func _amb_layer_db(gain: float) -> float:
	if muted or gain <= 0.001:
		return SILENT_DB
	return _linear_volume_to_db(master_volume * ambience_volume * gain)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_current_volumes()
	_save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_current_volumes()
	_save_settings()


func set_ambience_volume(value: float) -> void:
	ambience_volume = clampf(value, 0.0, 1.0)
	_apply_current_volumes()
	_save_settings()


func set_muted(value: bool) -> void:
	muted = value
	_apply_current_volumes()
	_save_settings()


func _load_manifest() -> void:
	_streams.clear()
	_metadata.clear()
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("Audio manifest missing: %s" % MANIFEST_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not (parsed is Dictionary):
		push_warning("Audio manifest is not a dictionary: %s" % MANIFEST_PATH)
		return
	for id in parsed:
		var entry: Variant = parsed[id]
		if not (entry is Dictionary):
			continue
		var path := str(entry.get("path", ""))
		if path == "" or not ResourceLoader.exists(path):
			push_warning("Audio asset missing for id '%s': %s" % [str(id), path])
			continue
		var stream := load(path) as AudioStream
		if stream == null:
			push_warning("Audio asset failed to load for id '%s': %s" % [str(id), path])
			continue
		stream = _configure_stream_looping(stream, bool(entry.get("loop", false)))
		_streams[str(id)] = stream
		_metadata[str(id)] = entry


func _configure_stream_looping(stream: AudioStream, should_loop: bool) -> AudioStream:
	if not should_loop:
		return stream
	var copy := stream.duplicate()
	if copy is AudioStreamWAV:
		copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
		copy.loop_begin = 0
		# 必须显式设循环终点为全长帧数：导入档 loop_mode=Disabled 时 loop_end=0，
		# 仅运行时改 LOOP_FORWARD 会让循环区间退化为 [0,0] → 卡在首帧 = 无声。
		copy.loop_end = int(round(copy.get_length() * copy.mix_rate))
	elif copy is AudioStreamMP3:
		copy.loop = true
	elif copy is AudioStreamOggVorbis:
		copy.loop = true
	return copy


func _build_players() -> void:
	for i in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_sfx_players.append(player)
	# 环境床：仅为「素材已就位」的层建 player（缺素材的层不建，配方里被跳过）
	for id in AMBIENCE_LAYERS:
		if not _streams.has(id):
			continue
		var pl := AudioStreamPlayer.new()
		pl.name = "Amb_" + id
		pl.stream = _streams[id]
		pl.volume_db = SILENT_DB     # 初始静音，由床淡入
		add_child(pl)
		_amb[id] = {"player": pl, "gain": 0.0, "target": 0.0}
		if id == "ambience_water_loop":
			_ambience_player = pl    # 保留旧引用语义


func _is_on_cooldown(id: String) -> bool:
	var cooldown_ms := int(DEFAULT_COOLDOWNS_MS.get(id, 0))
	if cooldown_ms <= 0:
		return false
	var now := Time.get_ticks_msec()
	var last := int(_last_played_ms.get(id, -cooldown_ms))
	if now - last < cooldown_ms:
		return true
	_last_played_ms[id] = now
	return false


func _sfx_db() -> float:
	if muted:
		return SILENT_DB
	return _linear_volume_to_db(master_volume * sfx_volume)


func _ambience_db() -> float:
	if muted:
		return SILENT_DB
	return _linear_volume_to_db(master_volume * ambience_volume)


func _linear_volume_to_db(value: float) -> float:
	if value <= 0.001:
		return SILENT_DB
	return linear_to_db(clampf(value, 0.001, 1.0))


func _apply_current_volumes() -> void:
	for player in _sfx_players:
		player.volume_db = _sfx_db()
	for id in _amb:
		_amb[id]["player"].volume_db = _amb_layer_db(float(_amb[id]["gain"]))


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if not (parsed is Dictionary):
		return
	master_volume = clampf(float(parsed.get("master", master_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(parsed.get("sfx", sfx_volume)), 0.0, 1.0)
	ambience_volume = clampf(float(parsed.get("ambience", ambience_volume)), 0.0, 1.0)
	muted = bool(parsed.get("muted", muted))


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"master": master_volume,
		"sfx": sfx_volume,
		"ambience": ambience_volume,
		"muted": muted,
	}))
