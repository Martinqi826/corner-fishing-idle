# Audio Engine Handoff

This document is for Claude/Codex coordination. The audio system is implemented and should be treated as active project infrastructure.

## Implementation Files

- `res://audio_manager.gd`
  - Autoload name: `Audio`
  - Registered in `project.godot` under `[autoload]`
  - Loads `res://assets/audio/audio_manifest.json`
  - Manages SFX player pool, ambience loop, cooldowns, mute, and saved volume settings
- `res://assets/audio/audio_manifest.json`
  - Stable asset ID to file path manifest
- `res://docs/audio_asset_rules.md`
  - Asset source mapping, tone rules, and playback guidelines
- `res://tools/prepare_free_sfx_assets.py`
  - Rebuilds the current CC0/free-SFX asset set

## Public API

Use only these calls from gameplay/UI code:

```gdscript
Audio.play("coin")
Audio.play_ui("ui_click")
Audio.play_sfx("catch_common")
Audio.start_ambience()
Audio.stop_ambience()
Audio.set_master_volume(value)
Audio.set_sfx_volume(value)
Audio.set_ambience_volume(value)
Audio.set_muted(enabled)
```

Do not create ad hoc `AudioStreamPlayer` nodes in gameplay panels or fish/economy logic.

## Current Event Hooks

`main.gd` already calls audio in these places:

- Game start: `Audio.start_ambience()`
- Wait cycle cast: `cast`, then delayed `bobber_splash`
- Bite state: `bite`
- Catch result: `catch_common` or `catch_rare`
- Button skin helper: `ui_click`
- Invalid purchases: `ui_error`
- Sell one / sell all: `coin`
- Rod, bait, and bag upgrades: `upgrade`
- Settings panel: mute, master volume, SFX volume, ambience volume

## Settings Persistence

Audio settings are saved separately from the game save:

```text
user://audio_settings.json
```

Stored keys:

```json
{
  "master": 0.8,
  "sfx": 0.85,
  "ambience": 0.42,
  "muted": false
}
```

## Tone Direction

The game is meant to feel healing and soft. Keep sounds low-pressure:

- Prefer water, cloth, wood, and soft coin Foley.
- Avoid bright arcade UI pings and reward fanfare.
- Keep ambience significantly quieter than SFX.
- Add cooldowns for any new high-frequency sound.

## Verification

After changing audio files or manifest paths, run:

```powershell
godot --headless --editor --path . --quit
godot --headless --path . --quit
godot --headless --path . -s tools\validate_game.gd
```

The first command imports new assets and creates `.import` files.
