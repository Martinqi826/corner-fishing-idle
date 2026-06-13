# Audio Asset Rules

This project uses a calm, healing audio direction. Sounds should feel soft, natural, and low-pressure. Avoid arcade pings, sharp reward stingers, synthetic beeps, loud fanfare, and busy music.

## Current Asset Set

All runtime audio assets live under `res://assets/audio/`.

| ID | File | Use | Loop |
| --- | --- | --- | --- |
| `ui_click` | `res://assets/audio/ui/ui_click.wav` | Generic button/toggle/tab tap | No |
| `ui_error` | `res://assets/audio/ui/ui_error.wav` | Invalid action, insufficient coins | No |
| `cast` | `res://assets/audio/fishing/cast.wav` | Rod cast / line movement | No |
| `bobber_splash` | `res://assets/audio/fishing/bobber_splash.wav` | Bobber lands in water | No |
| `bite` | `res://assets/audio/fishing/bite.wav` | Fish bite / bobber twitch cue | No |
| `catch_common` | `res://assets/audio/fishing/catch_common.wav` | Common catch | No |
| `catch_rare` | `res://assets/audio/fishing/catch_rare.wav` | Rare or better catch | No |
| `coin` | `res://assets/audio/economy/coin.wav` | Money gained / sell payout | No |
| `upgrade` | `res://assets/audio/economy/upgrade.wav` | Upgrade purchased | No |
| `ambience_water_loop` | `res://assets/audio/ambience/ambience_water_loop.wav` | Background water ambience | Yes |

The machine-readable manifest is `res://assets/audio/audio_manifest.json`.

## Playback Rules

- Route all playback through `AudioManager`; do not scatter `AudioStreamPlayer` nodes across UI/business logic.
- Keep `ambience_water_loop` quiet. Suggested ambience bus volume is lower than SFX by roughly 10-16 dB.
- High-frequency sounds need cooldowns:
  - `ui_click`: 40-60 ms
  - `coin`: 80-120 ms, and batch multiple coin events into one playback
  - `bite`: do not retrigger while the current bite state is active
- Reward sounds should never block or overpower the scene. Use `catch_rare` only for rare or higher rarity.
- Avoid layering `coin`, `upgrade`, and `catch_rare` at full volume in the same frame. Prefer a short stagger or choose the strongest semantic sound.
- Persist user audio settings: master volume, SFX volume, ambience volume, and mute.

## Source Selection

The current files were prepared from free CC0 source packs, with gentle gain reduction and fades:

| Asset ID | Source File |
| --- | --- |
| `ui_click` | `E:\ai-audio\free-sfx\packs\opengameart_kenney_interface_sounds_cc0\Audio\click_001.ogg` |
| `ui_error` | `E:\ai-audio\free-sfx\packs\opengameart_kenney_interface_sounds_cc0\Audio\drop_001.ogg` |
| `cast` | `E:\ai-audio\free-sfx\packs\opengameart_202_more_sounds_cc0\Cloth\Cloth_05.wav` |
| `bobber_splash` | `E:\ai-audio\free-sfx\packs\opengameart_water_splash_slime_cc0\splash_09.ogg` |
| `bite` | `E:\ai-audio\free-sfx\packs\opengameart_water_splash_slime_cc0\bubble_02.ogg` |
| `catch_common` | `E:\ai-audio\free-sfx\packs\opengameart_water_splash_slime_cc0\splash_06.ogg` |
| `catch_rare` | `splash_01.ogg` plus `confirmation_001.ogg`, mixed softly |
| `coin` | `E:\ai-audio\free-sfx\packs\opengameart_202_more_sounds_cc0\Money\Money_07.wav` |
| `upgrade` | `E:\ai-audio\free-sfx\packs\opengameart_kenney_interface_sounds_cc0\Audio\confirmation_001.ogg` |
| `ambience_water_loop` | `E:\ai-audio\free-sfx\packs\opengameart_water_splash_slime_cc0\loop_water_03.ogg` |

Regenerate this asset set with:

```powershell
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\prepare_free_sfx_assets.py
```

## Licensing Notes

- Kenney Interface Sounds: CC0, attribution optional.
- OpenGameArt 40 water/splash/slime SFX: CC0.
- OpenGameArt 202 More Sound Effects: CC0.

Keep this file updated if any asset source changes.
