# Claude Handoff: River Bend Day/Night Case

## Goal

Use the default spot `river_bend` as the first day/night scenic case. The intended result is not a hard cut and not a simple fullscreen tint. It should be:

```text
hand-authored key images + slow crossfade + existing procedural overlays
```

Keep the current game playable if any image is missing.

## Source Assets For Approval

These files are source mockups, not runtime assets yet:

```text
assets/art/source/scenic_variants/river_bend_cycle/spot_river_bend_dawn_key_v1.png
assets/art/source/scenic_variants/river_bend_cycle/spot_river_bend_day_reference_v1.png
assets/art/source/scenic_variants/river_bend_cycle/spot_river_bend_dusk_key_v1.png
assets/art/source/scenic_variants/river_bend_cycle/spot_river_bend_night_key_v1.png
assets/art/source/scenic_variants/river_bend_cycle/river_bend_cycle_contact_sheet.png
assets/art/source/scenic_variants/river_bend_cycle/river_bend_cycle_preview.html
```

The current best direction for `river_bend` is:

```text
dawn: signature view, morning mist and pale sunrise
day: clean neutral base
dusk: restrained rose-gold reflection
night: quiet blue moonlit river, very small star detail
```

After user approval, copy the approved images into runtime paths:

```text
assets/art/background/spot_river_bend_dawn.png
assets/art/background/spot_river_bend_day.png
assets/art/background/spot_river_bend_dusk.png
assets/art/background/spot_river_bend_night.png
```

Do not overwrite `assets/art/background/spot_river_bend.png`; keep it as fallback.

## Data Change

In `spot_data.gd`, add `best_view` only for `river_bend` first:

```gdscript
"best_view": {
	"phase": "dawn",
	"name": "晨雾日出",
	"asset_phase": "dawn"
}
```

Add safe helpers:

```gdscript
static func best_view(id: String) -> Dictionary:
	return get_spot(id).get("best_view", {})

static func scenic_name(id: String, phase: String) -> String:
	var bv := best_view(id)
	if not bv.is_empty() and str(bv.get("phase", "")) == phase:
		return str(bv.get("name", ""))
	return ""
```

## ScenePainter Change

Extend `scene_painter.gd` so it can render the current spot's time variant, with fallback.

Recommended loading order:

```text
assets/art/background/spot_<bg_key>_<phase>.png
assets/art/background/spot_<bg_key>.png
current _base fallback
```

For this case:

```text
spot_river_bend_dawn.png
spot_river_bend_day.png
spot_river_bend_dusk.png
spot_river_bend_night.png
spot_river_bend.png
```

Add a slow crossfade rather than hard image replacement:

```gdscript
var _spot_key := ""
var _phase_id := "day"
var _spot_base: Texture2D = null
var _spot_next: Texture2D = null
var _spot_fade_t := 1.0
const SPOT_FADE_DUR := 90.0
```

Behavior:

- `set_spot(bg_key)` changes `_spot_key` and loads the correct background for the current phase.
- `set_phase_tint(c, phase_id := "")` keeps current tint behavior and, when `phase_id` changes, starts a background crossfade.
- During `_draw_composite()`, draw old background first, then new background with alpha `smoothstep(0, 1, _spot_fade_t)`.
- Keep all current overlays above the background: fisher, pet, lantern, fishing line, mist, water shimmer, snow, phase tint, wildlife, ripples, bobber, glow.
- If the target variant is missing, crossfade to `spot_river_bend.png` instead.

Do not blank the scene when a phase image is absent.

## Main Change

In `main.gd`, route phase changes through the new painter signature:

```gdscript
func _apply_phase() -> void:
	if painter.has_method("set_phase_tint"):
		painter.set_phase_tint(Weather.tint(day_phase), day_phase)
	_update_hud()
```

In `_ready`, after `day_phase = Weather.current_phase()`, call `_apply_phase()` instead of directly calling `set_phase_tint`.

In `_update_spot_chip`, surface the signature view:

```gdscript
var scenic := SpotData.scenic_name(current_spot, day_phase)
if scenic != "":
	txt += " · " + scenic
```

## Timing

For this first trial, keep `Weather.current_phase()` as-is if you want minimal risk.

If user approves the feel, the next pass should decouple scenic time from strict real-world hours:

```text
game cycle option: 24 minutes per in-game day
real-time option: current behavior
preview option: fast 24-second loop for screenshots/testing
```

Do not add hard time locks for normal fish in this pass.

## Validation

Add or update validation for:

- `SpotData.scenic_name("river_bend", "dawn") == "晨雾日出"`.
- `SpotData.scenic_name("river_bend", "day") == ""`.
- `ScenePainter.set_spot("river_bend")` still works with only `spot_river_bend.png`.
- `ScenePainter.set_phase_tint(Weather.tint("dawn"), "dawn")` does not error if `spot_river_bend_dawn.png` is absent.
- If runtime variants are present, phase switching keeps `uses_clean_bg()` true.

## Do Not Do Yet

- Do not apply this to lake/coast until river bend is approved.
- Do not move source mockups into runtime background paths without user approval.
- Do not overwrite base backgrounds.
- Do not time-lock ordinary fish.
- Do not change save format for this visual-only test.
