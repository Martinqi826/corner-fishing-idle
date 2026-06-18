# Claude Handoff: Per-Spot Scenic Time Variants

## Goal

Turn the current global tint-only day/night system into a per-spot scenic identity system:

- `river_bend`: dawn is the signature view, "晨雾日出".
- `still_lake`: dusk is the signature view, "湖面夕照".
- `coast_pier`: night is the signature view, "夜潮灯火".

Do not make ordinary fish or progression hard time-locked. Time should remain a soft atmosphere and weighting layer.

## Art Assets Awaiting Review

These are source/color-pass mockups, not final runtime assets:

```text
assets/art/source/scenic_variants/spot_river_bend_dawn_colorpass_v1.png
assets/art/source/scenic_variants/spot_still_lake_dusk_colorpass_v1.png
assets/art/source/scenic_variants/spot_coast_pier_night_colorpass_v1.png
assets/art/source/scenic_variants/scenic_time_colorpass_contact_sheet.png
```

Only after approval, copy or repaint them into runtime names:

```text
assets/art/background/spot_river_bend_dawn.png
assets/art/background/spot_still_lake_dusk.png
assets/art/background/spot_coast_pier_night.png
```

Keep the existing base files as fallback:

```text
assets/art/background/spot_river_bend.png
assets/art/background/spot_still_lake.png
assets/art/background/spot_coast_pier.png
```

## Implementation Request

1. Extend `spot_data.gd`.

Add a `best_view` field to each spot:

```gdscript
"best_view": {
	"phase": "dawn",
	"name": "晨雾日出",
	"asset_phase": "dawn"
}
```

Suggested values:

```text
river_bend  -> phase dawn,  name 晨雾日出, asset_phase dawn
still_lake  -> phase dusk,  name 湖面夕照, asset_phase dusk
coast_pier  -> phase night, name 夜潮灯火, asset_phase night
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

2. Extend `scene_painter.gd`.

Keep backward compatibility. `set_spot(bg_key)` must still work when no time-variant image exists.

Recommended behavior:

```text
current spot = bg_key
current phase = day/dawn/dusk/night
try assets/art/background/spot_<bg_key>_<phase>.png
if missing, try assets/art/background/spot_<bg_key>.png
if missing, fall back to current base image
```

Implementation shape:

- Store `_spot_key`.
- Store `_phase_id`, default `"day"`.
- Add `_reload_spot_background()`.
- Let `set_spot(bg_key)` update `_spot_key` then reload.
- Let `set_phase_tint(c, phase_id := "")` update tint and, when phase changes, reload.

Do not require all variants to exist. Missing variants must not throw or blank the scene.

3. Update `main.gd`.

In `_ready`, apply the visual spot first, then apply the current phase through the same code path:

```gdscript
_apply_spot_visuals()
day_phase = Weather.current_phase()
_apply_phase()
```

In `_apply_phase`, pass the phase id if the painter method supports the new signature:

```gdscript
painter.set_phase_tint(Weather.tint(day_phase), day_phase)
```

If using a compatibility wrapper, keep old tests passing.

In `_update_spot_chip`, surface the signature view when active:

```gdscript
var scenic := SpotData.scenic_name(current_spot, day_phase)
if scenic != "":
	txt += " · " + scenic
```

4. Validation.

Update `tools/validate_game.gd` to cover:

- `SpotData.scenic_name("river_bend", "dawn")` returns non-empty.
- Non-signature phases return empty.
- `ScenePainter.set_spot("river_bend")` still loads the base image.
- `ScenePainter.set_phase_tint(Weather.tint("dawn"), "dawn")` does not break if the variant file is missing.
- If approved runtime variant files exist, `uses_clean_bg()` remains true.

5. Do not do in this pass.

- Do not bind ordinary fish exclusively to exact time windows.
- Do not add real-world-only waiting requirements.
- Do not overwrite existing base backgrounds until the user approves the source/color-pass mockups.
- Do not rename current spot ids or break old saves.

## Notes

The color-pass mockups are useful for judging direction, but final art should ideally be hand-painted or image-generated as clean 520x400 spot backgrounds with the same feathered composition as the existing assets. The code should be ready before final art lands, so approved assets can be dropped into `assets/art/background/` without further plumbing.
