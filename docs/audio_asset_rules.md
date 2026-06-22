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
| `amb_stream_loop` | `res://assets/audio/ambience/amb_stream_loop.wav` | Stream/riffle ambience layer | Yes |
| `amb_birds_day` | `res://assets/audio/ambience/amb_birds_day.wav` | Daytime woodland birdsong layer | Yes |
| `amb_wind_loop` | `res://assets/audio/ambience/amb_wind_loop.wav` | Open-air wind layer | Yes |
| `amb_night_insects` | `res://assets/audio/ambience/amb_night_insects.wav` | Night cricket layer | Yes |
| `amb_waves_loop` | `res://assets/audio/ambience/amb_waves_loop.wav` | Ocean swell layer | Yes |
| `amb_gulls_day` | `res://assets/audio/ambience/amb_gulls_day.wav` | Coastal gull layer | Yes |
| `amb_cave_drip` | `res://assets/audio/ambience/amb_cave_drip.wav` | Cave water-drip echo layer | Yes |

The machine-readable manifest is `res://assets/audio/audio_manifest.json`.

## Ambience Bed (layered, biome × time-of-day)

`AudioManager` mixes a **layered ambience bed** instead of one flat water loop. Multiple looping streams play
simultaneously and crossfade (≈2.5 s) whenever the fishing spot or day-phase changes, driven by a recipe of
`biome × phase`. `main.gd` calls `Audio.set_ambience_scene(spot_key, day_phase)` on start, on phase change
(`_apply_phase`), and on spot change (`_apply_spot_visuals`).

**Graceful degradation:** a layer that has no asset in the manifest simply gets no player and is skipped in
every recipe — so the bed silently falls back to whatever layers do exist. All eight layers ship today; if a
layer's wav is ever removed the bed still varies by time-of-day via a global gain (night quietest, golden
hours softer, daytime fullest), so behaviour never regresses, and a layer lights back up the moment its wav
returns.

| Layer ID | Role | Loop | Status |
| --- | --- | --- | --- |
| `ambience_water_loop` | Generic still-water base (most freshwater spots) | Yes | **Present** |
| `amb_stream_loop` | Faster stream/riffle (mountain_stream, river_bend) | Yes | **Present** |
| `amb_birds_day` | Daytime woodland birdsong (freshwater/forest, day + golden) | Yes | **Present** |
| `amb_wind_loop` | Open-air wind (lake, polar) | Yes | **Present** |
| `amb_night_insects` | Night crickets (warm freshwater/lake nights; not polar/sea) | Yes | **Present** |
| `amb_waves_loop` | Ocean swell (sea base: coast_pier, estuary, deep_sea, coral_reef) | Yes | **Present** |
| `amb_gulls_day` | Gulls (coast, daytime) | Yes | **Present** |
| `amb_cave_drip` | Cave water-drip echo (cavern_pool base) | Yes | **Present** |

Spot→biome mapping and the per-biome recipe live in `audio_manager.gd` (`SPOT_BIOME`, `_ambience_recipe`).
Keep all layers quiet (same 10-16 dB below SFX guidance) — they are a bed, not a focal sound. Each new layer
should be a seamless loop ≥15 s, gentle, with no obvious repeat spike. To enable one, drop the wav under
`res://assets/audio/ambience/` and add a manifest entry with `"loop": true`, e.g.:

```json
"amb_birds_day": {
  "path": "res://assets/audio/ambience/amb_birds_day.wav",
  "duration_seconds": 20.0,
  "loop": true,
  "description": "Quiet daytime woodland birdsong bed. Source: <CC0 pack>."
}
```

**How the seven natural layers were made.** The local SFX packs hold no nature field recordings, so these
layers are built from **real CC0 / public-domain recordings** sourced from Wikimedia Commons (Freesound CC0
mirror) and OpenGameArt CC0 (exact origins in the source table below). Two committed scripts make the pipeline
reproducible:

1. `tools/fetch_ambience_sources.py` — downloads the raw CC0 recordings into
   `E:\ai-audio\free-sfx\ambience_sources\` (outside the repo, like the other free-SFX sources).
2. `tools/prepare_ambience_assets.py` — converts each to mono 44.1 kHz, gently softens it (high-pass ~45 Hz to
   kill rumble, low-pass ~11 kHz to tame harsh highs), and turns it into a seamless loop ≥15 s. Continuous
   textures (stream/wind/birds/insects/cave) use an **equal-power boundary crossfade** (tail blended back over
   the head); event beds (waves/gulls) **scatter the real crashes/calls into a ring buffer** with wrap-around.
   Either way the loop is click-free, and file peaks are normalized to 0.12–0.18 (below the 0.20–0.32 SFX peaks;
   runtime `ambience_volume × recipe gain` drops them further).

Regenerate (fetch first, then build):

```powershell
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\fetch_ambience_sources.py
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\prepare_ambience_assets.py
```

After regenerating, run `godot --headless --import` so the new wavs are imported before the game can see
them. The script **merges** its seven keys into the manifest; `prepare_free_sfx_assets.py` likewise merges,
so either generator can be rerun without clobbering the other's entries.

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

The SFX + water-base files were prepared from free CC0 source packs, with gentle gain reduction and fades.
The seven biome ambience layers (`amb_*`) are built from real CC0 / public-domain recordings (see "How the
seven natural layers were made" above):

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
| `amb_stream_loop` | Freesound #433589 'jackthemurray' stream-river-water-up-close (via Wikimedia Commons), CC0 |
| `amb_birds_day` | OpenGameArt "Ambient Bird Sounds" by isaiah658, CC0 |
| `amb_wind_loop` | OpenGameArt "wind1", CC0 |
| `amb_night_insects` | OpenGameArt "Crickets ambient noise (loopable)", CC0 |
| `amb_waves_loop` | OpenGameArt "Beach Ocean Waves" by jasinski (alkai beach), CC0 |
| `amb_gulls_day` | OpenGameArt "Solo Seagull Sound Effects" (Seagull Ambient), CC0 |
| `amb_cave_drip` | OpenGameArt "Dripping water loop" (atmosbasement), CC0 |

Regenerate the SFX + water-base set with:

```powershell
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\prepare_free_sfx_assets.py
```

Regenerate the seven biome ambience layers with (fetch sources first, then build):

```powershell
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\fetch_ambience_sources.py
E:\ai-audio\stable-audio-open\.venv\Scripts\python.exe tools\prepare_ambience_assets.py
```

## Licensing Notes

- Kenney Interface Sounds: CC0, attribution optional.
- OpenGameArt 40 water/splash/slime SFX: CC0.
- OpenGameArt 202 More Sound Effects: CC0.
- The seven `amb_*` biome layers are real recordings under CC0 / public domain (origins in the source table above); no attribution required, attribution-friendly.

Keep this file updated if any asset source changes.
