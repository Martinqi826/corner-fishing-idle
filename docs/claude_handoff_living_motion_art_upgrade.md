# Claude Handoff: Living Motion Art Upgrade

Date: 2026-06-18

## Goal

Upgrade the living subjects in Corner Fishing Idle so the fisher, pet cat, and wildlife events feel calmer, more painterly, and less Q/chibi. Keep the current Godot architecture: `scene_painter.gd` already supports separate sprites, frame arrays, small transform-based motion, wildlife events, water shimmer, mist, snow, ripple, and lantern glow.

Do not redesign the game UI. Do not replace the background scene. This task is an art-resource and animation-polish pass.

## Current Problem

- The cat reads too much like a cute sticker or mobile-game mascot.
- Some living subjects have stronger cartoon proportions than the winter scene.
- Motion is functional but feels low quality because key poses are too few and the sprite style does not fully match the environment.

## Art Direction

Use the existing `docs/art_direction.md` as the source of truth:

- Mood: quiet, cozy, cold winter morning.
- Style: painterly 2D illustration with light realism.
- Avoid: pixel art, hard cartoon outlines, glossy mobile-game effects, chibi, anime, big shiny eyes, saturated colors.
- Living subjects should be readable at small size, but integrated into the snowy riverbank through muted color, soft edges, cool shadow, and subtle contact blending.

Specific style changes:

- Fisher: keep small seated silhouette, natural proportions, olive/khaki coat, less sprite-like outline.
- Cat: smaller eyes, less round head, more natural cat posture, muted ginger/brown, not oversized beside the fisher.
- Bird/wildlife: small environmental events, not collectible stickers. Bird should have a wing loop, not a static glide only.

## New Source Sheets To Produce

The user approved the new direction. Produce or slice these source sheets into runtime PNGs.

### Fisher Sheet

Source prompt:

```text
Create a painterly 2D sprite source sheet for a small seated winter fisher character, matching a calm light-realism snowy river scene. This sheet will be sliced into game sprites.

Subject: one seated fisher facing left, compact readable silhouette, natural proportions, olive/khaki winter coat, muted scarf, mittens, small boots, simple cap, holding fishing rod. Less cute, not chibi, not mascot.

Required poses: idle seated pose, idle-breathing alternate, cold shiver pose, doze/yawn pose, rod pull frame 1, rod pull frame 2, rare-catch cheer pose. Keep body scale and anchor consistent across all poses, feet/bottom aligned on one baseline.

Style: premium painterly 2D game sprite art with light realism, soft brushed edges, subtle texture, no hard black outline, no vector flatness.

Composition: seven separate full-body sprites in a clean horizontal contact sheet on a perfectly flat solid #00ff00 chroma-key background for later background removal. Large padding around each sprite. No shadows on background, no floor plane.

Lighting: cool winter ambient light with faint warm lantern rim light from lower right.

Constraints: consistent character identity, consistent scale, bottom-center anchor, readable at 45-65 px tall in game. No labels, no text, no watermark. Background must be a single uniform #00ff00 and the subject must not contain #00ff00.

Avoid: chibi, anime, big shiny eyes, thick outline, sticker style, glossy mobile game, exaggerated bounce, saturated colors, black background, gradient background.
```

Runtime filenames:

```text
assets/art/character/fisher_idle.png
assets/art/character/fisher_idle_breath.png
assets/art/character/fisher_shiver.png
assets/art/character/fisher_doze.png
assets/art/character/fisher_pull_01.png
assets/art/character/fisher_pull_02.png
assets/art/character/fisher_cheer.png
```

### Cat Sheet

Source prompt:

```text
Create a painterly 2D sprite source sheet for a small ginger tabby cat companion, matching a calm light-realism snowy fishing scene. This sheet will replace the current overly cute/Q pet style.

Subject: one small ginger tabby cat, natural cat proportions, small eyes, less round toy-like head, muted orange-brown fur, subtle winter cool shadow, integrated painterly brush texture.

Required poses: sitting idle, blink, paw reach, steal fish low crouch, sleeping curl, tail flick frame 1, tail flick frame 2. Keep scale and identity consistent across all poses, paws/bottom aligned on one baseline where appropriate.

Style: premium painterly 2D game sprite art with light realism, soft brushed edges, subtle fur texture, no hard black outline, no sticker look.

Composition: seven separate sprites in a clean horizontal contact sheet on a perfectly flat solid #00ff00 chroma-key background for later background removal. Large padding around each sprite. No cast shadow on background, no floor plane.

Lighting: cool winter ambient light, very subtle warm lantern rim light.

Constraints: readable at 26-40 px tall in game, not oversized beside fisher, less Q than current cat; smaller eyes, less spherical head, natural sitting/crouching posture. No labels, no text, no watermark. Background must be a single uniform #00ff00 and the cat must not contain #00ff00.

Avoid: chibi, mascot, plush toy, anime, big shiny eyes, saturated orange, thick outline, sticker, glossy mobile-game polish, cute waving pose with huge head, gradient background.
```

Runtime filenames:

```text
assets/art/pets/cat_idle.png
assets/art/pets/cat_blink.png
assets/art/pets/cat_paw.png
assets/art/pets/cat_steal.png
assets/art/pets/cat_sleep.png
assets/art/pets/cat_tail_01.png
assets/art/pets/cat_tail_02.png
assets/art/pets/cat_shadow_soft.png
```

### Wildlife Sheet

Source prompt:

```text
Create a painterly 2D wildlife event sprite source sheet matching a calm winter river fishing scene. These tiny sprites will appear rarely and should integrate with the environment, not look like stickers.

Subjects and required frames: small winter bird wing cycle frame 1, bird wing cycle frame 2, bird wing cycle frame 3, bird glide frame; tiny rabbit idle, rabbit alert; tiny fox peek, fox retreat; small fish jump frame 1, fish jump frame 2. Keep each animal small, realistic/stylized light realism, muted and cohesive.

Style: premium painterly 2D game sprite art with light realism, soft brush texture, no hard black outlines, no vector flatness, no cartoon sticker.

Composition: ten separate sprites in a clean horizontal contact sheet on a perfectly flat solid #00ff00 chroma-key background for later background removal. Large padding around each sprite. No shadows on background, no floor plane.

Lighting: cool winter ambient light, subtle snow-scene color grading.

Constraints: readable at very small in-game scale; bird should work as a 4-frame wing loop; rabbit/fox should feel tucked into the snowy bank; fish jump should be subtle. No labels, no text, no watermark. Background must be a single uniform #00ff00 and subjects must not contain #00ff00.

Avoid: cute mascot, plush toy, sticker, thick outline, saturated colors, anime, glossy mobile game, oversized wildlife, gradient background.
```

Runtime filenames:

```text
assets/art/wildlife/bird_fly_01.png
assets/art/wildlife/bird_fly_02.png
assets/art/wildlife/bird_fly_03.png
assets/art/wildlife/bird_glide_01.png
assets/art/wildlife/rabbit_idle_01.png
assets/art/wildlife/rabbit_alert_01.png
assets/art/wildlife/fox_peek_01.png
assets/art/wildlife/fox_retreat_01.png
assets/art/wildlife/fish_jump_01.png
assets/art/wildlife/fish_jump_02.png
```

## Chroma-Key Extraction

If the source sheets are generated on `#00ff00`, remove the background into alpha PNGs. Preserve antialiasing and avoid green fringes.

Recommended local helper if available:

```powershell
python "$env:USERPROFILE\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py" `
  --input <source-sheet-or-crop.png> `
  --out <runtime-output.png> `
  --auto-key border `
  --soft-matte `
  --transparent-threshold 12 `
  --opaque-threshold 220 `
  --despill
```

If edges keep a green fringe, retry once with `--edge-contract 1`.

## Code Integration

Work mostly in `scene_painter.gd`.

### Fisher

Current code loads:

```gdscript
_fisher = _tex("res://assets/art/character/fisher_idle.png")
_fisher_pull = _frames("res://assets/art/character/fisher_pull_%02d.png", 2)
```

Add optional textures:

```gdscript
var _fisher_mood_tex := {}
```

Load:

```gdscript
for k in ["idle_breath", "shiver", "doze", "cheer"]:
    var tx := _tex("res://assets/art/character/fisher_%s.png" % k)
    if tx != null:
        _fisher_mood_tex[k] = tx
```

In `_draw_fisher()`, choose a texture by mood before applying transform:

- `cheer` -> `fisher_cheer.png` if present.
- `shiver` -> `fisher_shiver.png` if present.
- `doze` or `yawn` -> `fisher_doze.png` if present.
- idle breathing can alternate softly between `fisher_idle.png` and `fisher_idle_breath.png`, or only use `fisher_idle_breath.png` at the breath peak.

Keep current transform motion, but reduce the biggest jumps:

- Cheer vertical hop: max 6 px instead of 12 px.
- Cheer scale pulse: max 1.04 instead of 1.08.
- Shiver x offset: max 0.8 px instead of 1.4 px.

### Cat

Current code already supports:

```gdscript
idle, blink, paw, steal, sleep
```

Add tail-flick texture support without changing save data:

```gdscript
"tail_01": "res://assets/art/pets/cat_tail_01.png",
"tail_02": "res://assets/art/pets/cat_tail_02.png",
```

Add a `_pet_tail_t` timer. When idle and not sleeping/blinking/action, occasionally use `tail_01`/`tail_02` for 0.8-1.2 seconds every 6-12 seconds.

Recommended pet scale after new art:

```gdscript
const PET_SPRITE_SCALE := 0.30
```

If the new sprites are cropped tighter than the old ones, tune between `0.30` and `0.35`, but keep the cat visibly smaller than current.

### Bird/Wildlife

Current code stores one texture per kind:

```gdscript
var _wild_tex: Dictionary = {}
```

Change this to allow either single textures or arrays:

```gdscript
var _wild_tex := {
    "bird": _frames("res://assets/art/wildlife/bird_fly_%02d.png", 3),
}
```

Also load `bird_glide_01.png` as fallback if the frame array is empty.

In `_draw_wildlife()`, if `_wild_kind == "bird"` and frames exist:

```gdscript
var frames: Array = _wild_tex["bird"]
var idx := int(_wild_t * 8.0) % frames.size()
tex = frames[idx]
```

Recommended bird tuning:

- Scale: `0.16-0.24`, not `0.22-0.35`.
- Duration: `6-10s`.
- Alpha tint: `Color(0.84, 0.86, 0.88, 0.72 * fade)`.
- Keep bird behind UI and visually lower contrast.

### Motion Tuning

Keep `focus_mode` behavior: quiet mode should stop low-frequency wildlife events.

Recommended final movement values:

```text
Fisher breathing: 0.8-1.5 px visual movement, 3.2-4.8s cycle.
Cat breathing: 0.3-0.6 px movement, 4-6s cycle.
Cat tail flick: rare idle event, 0.8-1.2s.
Bird wing flap: 7-9 fps while crossing, but tiny and low alpha.
Wildlife event interval: after first preview, 60-150s.
Bobber idle: 1-2 px vertical, unchanged.
Ripple: unchanged, but reduce opacity if it competes with small wildlife.
```

## Acceptance Checklist

- At 1040x720 framed mode, cat no longer reads as a saturated sticker.
- At 520x400 immersive/corner art scale, fisher, cat, and bird remain readable but do not dominate the scene.
- Existing tests in `tools/validate_game.gd` still pass.
- `tools/dev_screenshot.gd` produces updated screenshots without missing textures.
- No large code refactor, no UI redesign, no save-schema change.
- Missing optional new frames should gracefully fall back to existing sprites.

## One-Shot Claude Prompt

```text
Please implement the living-motion art upgrade in `E:\godotgame1\fish-idle`.

Read these files first:
- `docs/art_direction.md`
- `docs/dynamic_art_plan.md`
- `docs/art_asset_audit.md`
- `docs/claude_handoff_living_motion_art_upgrade.md`
- `scene_painter.gd`

Goal:
Make the fisher, cat pet, and wildlife events feel more painterly, calmer, and less Q/chibi while preserving the current Godot architecture.

Do:
1. Add support in `scene_painter.gd` for optional new fisher mood sprites:
   `fisher_idle_breath.png`, `fisher_shiver.png`, `fisher_doze.png`, `fisher_cheer.png`.
   Keep fallbacks to current `fisher_idle.png` and `fisher_pull_%02d.png`.
2. Add support for optional cat tail frames:
   `cat_tail_01.png`, `cat_tail_02.png`.
   Trigger rare idle tail flicks without save-data changes.
3. Add support for multi-frame bird flight:
   `bird_fly_01.png`, `bird_fly_02.png`, `bird_fly_03.png`, with fallback to current `bird_fly_01.png`.
4. Tune motion down so it feels like quiet desktop ornament animation:
   smaller cheer hop, smaller shiver jitter, lower bird scale/alpha, rarer wildlife after the first event.
5. Keep all existing art paths backward-compatible. Missing optional files must not crash or break rendering.
6. Run `godot --headless --script tools/validate_game.gd` if available, and run `tools/dev_screenshot.gd` to generate screenshots for manual review.

Do not:
- Redesign UI.
- Replace the background scene.
- Change save schema.
- Remove existing fallback procedural drawing.
- Make the cat larger or cuter.

After implementing, summarize changed files, fallback behavior, and screenshot/test results.
```

