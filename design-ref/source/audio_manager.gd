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
var _ambience_player: AudioStreamPlayer
var _last_played_ms := {}


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
	if _ambience_player != null:
		_ambience_player.stream = null
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


func start_ambience() -> void:
	if not _streams.has("ambience_water_loop") or _ambience_player == null:
		return
	if _ambience_player.stream != _streams["ambience_water_loop"]:
		_ambience_player.stream = _streams["ambience_water_loop"]
	_ambience_player.volume_db = _ambience_db()
	if not _ambience_player.playing:
		_ambience_player.play()


func stop_ambience() -> void:
	if _ambience_player != null:
		_ambience_player.stop()


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
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	add_child(_ambience_player)


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
	if _ambience_player != null:
		_ambience_player.volume_db = _ambience_db()


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
