extends Node
## 统一音频管理（Autoload 名 Audio）。集中按 manifest 加载音频、播放音效/环境音、管理音量与静音。
## 业务代码只调用 Audio.play_sfx("cast") 等，不在各处散落 AudioStreamPlayer。
## 音频文件缺失时静默跳过（Codex 资源逐步到位，启动不报错）。

const MANIFEST := "res://assets/audio/audio_manifest.json"
const SETTINGS := "user://audio_settings.json"
const SFX_POOL := 6

# 高频音效冷却（毫秒）：避免连续疯狂叠加
const COOLDOWN := {"coin": 70, "ui_click": 55, "ui_error": 120, "bobber_splash": 150, "cast": 150}

var master_volume := 0.8
var sfx_volume := 0.9
var ambience_volume := 0.5
var muted := false

var _streams := {}                     # id -> AudioStream
var _sfx_players: Array = []           # 轮询的一次性音效播放器
var _sfx_next := 0
var _ambience: AudioStreamPlayer
var _last_ms := {}                     # id -> 上次播放时刻


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停菜单时音频仍可控
	_load_manifest()
	for i in SFX_POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	_ambience = AudioStreamPlayer.new()
	add_child(_ambience)
	_load_settings()


# ============================ 加载 ============================

func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not (data is Dictionary):
		return
	for id in data:
		var entry: Variant = data[id]
		if not (entry is Dictionary):
			continue
		var path := str(entry.get("path", ""))
		if path == "" or not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path)
		if stream == null:
			continue
		if bool(entry.get("loop", false)) and stream is AudioStreamMP3:
			stream = stream.duplicate()
			stream.loop = true
		_streams[id] = stream


func has(id: String) -> bool:
	return _streams.has(id)


# ============================ 播放 ============================

## 通用入口：按 id 自动分流（环境/UI/音效）。
func play(id: String) -> void:
	if id == "ambience_water_loop":
		start_ambience()
	else:
		play_sfx(id)


func play_ui(id: String) -> void:
	play_sfx(id)


func play_sfx(id: String) -> void:
	if muted or not _streams.has(id) or _on_cooldown(id):
		return
	var p: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	p.stream = _streams[id]
	p.volume_db = linear_to_db(maxf(0.0001, master_volume * sfx_volume))
	p.play()


func start_ambience() -> void:
	if not _streams.has("ambience_water_loop"):
		return
	if _ambience.stream != _streams["ambience_water_loop"]:
		_ambience.stream = _streams["ambience_water_loop"]
	_ambience.volume_db = _ambience_db()
	if not _ambience.playing:
		_ambience.play()


func stop_ambience() -> void:
	_ambience.stop()


func _on_cooldown(id: String) -> bool:
	var cd := int(COOLDOWN.get(id, 0))
	if cd <= 0:
		return false
	var now := Time.get_ticks_msec()
	if _last_ms.has(id) and now - int(_last_ms[id]) < cd:
		return true
	_last_ms[id] = now
	return false


func _ambience_db() -> float:
	if muted:
		return -80.0
	return linear_to_db(maxf(0.0001, master_volume * ambience_volume))


# ============================ 音量 / 静音 ============================

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	_ambience.volume_db = _ambience_db()
	_save_settings()


func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	_save_settings()


func set_ambience_volume(v: float) -> void:
	ambience_volume = clampf(v, 0.0, 1.0)
	_ambience.volume_db = _ambience_db()
	_save_settings()


func set_muted(m: bool) -> void:
	muted = m
	_ambience.volume_db = _ambience_db()
	_save_settings()


# ============================ 设置持久化 ============================

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS))
	if not (data is Dictionary):
		return
	master_volume = clampf(float(data.get("master", master_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(data.get("sfx", sfx_volume)), 0.0, 1.0)
	ambience_volume = clampf(float(data.get("ambience", ambience_volume)), 0.0, 1.0)
	muted = bool(data.get("muted", muted))


func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"master": master_volume, "sfx": sfx_volume,
			"ambience": ambience_volume, "muted": muted,
		}))
