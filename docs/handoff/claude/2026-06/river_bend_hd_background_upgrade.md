# Claude Handoff: River Bend HD Background Upgrade

Status: proposal with candidate assets
Owner: Codex
Created: 2026-06-19
Expires: after river_bend HD background integration is approved

## Problem

The current default spot `river_bend` background looks coarse in framed mode. The runtime art is `520x400`, while framed mode scales the `ScenePainter` by `2.0`, so background grain and watercolor speckle are enlarged on a `1040x720` window.

Relevant code:

- `main.gd`: `ART := Vector2(520, 400)`, `FRAMED_SCENE_SCALE := 2.0`
- `scene_painter.gd`: `W := 520.0`, `H := 400.0`
- Current background drawing uses `draw_texture(bg, Vector2.ZERO)`.

Do not solve this with sharpening. The goal is cleaner source art and an optional 2x background path.

## Candidate Assets From Codex

No code has been changed. Candidate files are under:

```text
assets/art/source/scenic_variants/river_bend_hd_clean_v1/
```

Preview:

```text
assets/art/source/scenic_variants/river_bend_hd_clean_v1/river_bend_hd_clean_compare_520.png
assets/art/source/scenic_variants/river_bend_hd_clean_v1/river_bend_hd_clean_2x_contact_sheet.png
assets/art/source/scenic_variants/river_bend_hd_clean_v1/preview.html
```

Source/current copies:

```text
assets/art/source/scenic_variants/river_bend_hd_clean_v1/source_current_520/
```

Cleaned drop-in 520 candidates:

```text
assets/art/source/scenic_variants/river_bend_hd_clean_v1/runtime_520_candidates_named_for_dropin/
```

2x candidates for engineering validation:

```text
assets/art/source/scenic_variants/river_bend_hd_clean_v1/clean_2x_1040x800/
```

3x mother-file candidates for future repaint/upscale work:

```text
assets/art/source/scenic_variants/river_bend_hd_clean_v1/clean_3x_1560x1200/
```

These are local clean/upscale candidates, not a final from-scratch repaint. Use them to validate the 2x engineering path and compare the grain issue. If visual quality is still not good enough, use the prompts below to generate true new masters.

## Recommended Engineering Path

Add optional HD background lookup without breaking existing 520 assets.

Suggested asset folder:

```text
assets/art/background_hd/
```

Suggested filenames:

```text
assets/art/background_hd/spot_river_bend_dawn.png
assets/art/background_hd/spot_river_bend_day.png
assets/art/background_hd/spot_river_bend_dusk.png
assets/art/background_hd/spot_river_bend_night.png
assets/art/background_hd/spot_river_bend.png
```

Recommended contents for first test:

- Copy the four files from `clean_2x_1040x800/`.
- Use the day file as `spot_river_bend.png` fallback.

Change `scene_painter.gd` so background resolution and art-coordinate size are decoupled. Do not draw HD textures at natural size.

Add a helper like:

```gdscript
func _draw_bg(tex: Texture2D, alpha := 1.0) -> void:
	if tex == null:
		return
	draw_texture_rect(tex, Rect2(Vector2.ZERO, Vector2(W, H)), false, Color(1, 1, 1, alpha))
```

Then replace current background drawing:

```gdscript
draw_texture(_spot_prev, Vector2.ZERO)
draw_texture(bg, Vector2.ZERO, Color(1, 1, 1, _spot_fade))
draw_texture(bg, Vector2.ZERO)
```

with:

```gdscript
_draw_bg(_spot_prev)
_draw_bg(bg, _spot_fade)
_draw_bg(bg)
```

This keeps all existing anchors in 520x400 art coordinates, while allowing a 1040x800 texture to map cleanly into the same art rectangle.

## Optional HD Lookup

Update `_resolve_spot_tex(bg_key, phase)` to prefer HD files first, then fall back to existing runtime files:

```gdscript
func _resolve_spot_tex(bg_key: String, phase: String) -> Texture2D:
	if bg_key == "":
		return null
	if phase != "":
		var hd := _tex("res://assets/art/background_hd/spot_%s_%s.png" % [bg_key, phase])
		if hd != null:
			return hd
		var tx := _tex("res://assets/art/background/spot_%s_%s.png" % [bg_key, phase])
		if tx != null:
			return tx
	var hd_base := _tex("res://assets/art/background_hd/spot_%s.png" % bg_key)
	if hd_base != null:
		return hd_base
	return _tex("res://assets/art/background/spot_%s.png" % bg_key)
```

Do not remove the existing `assets/art/background/` files.

## Import Settings

After adding PNGs, run:

```powershell
godot --headless --editor --path . --quit
```

Check generated `.import` files. For these large painterly backgrounds, avoid lossy import compression. Current import files use `compress/mode=0`; keep that behavior.

## Validation

Run:

```powershell
godot --headless -s tools/validate_game.gd
```

Then manually capture screenshots:

1. Framed mode, `river_bend`, `night`.
2. Framed mode, `river_bend`, `day`.
3. Immersive mode if still supported.

Check:

- Background covers the same visible area as before.
- Fisher, cat, lantern, bobber, line, ripples, and HUD anchors remain aligned.
- Day/night crossfade still works.
- 520 fallback still works if `assets/art/background_hd/` is temporarily renamed.
- Grain is visibly reduced at `1040x720` display size.

## True Repaint Prompt Base

Use this if the candidate assets are still not good enough and a real high-resolution repaint is needed.

```text
Use case: stylized-concept
Asset type: high-resolution 2D game background for a cozy idle fishing game
Primary request: Create a clean high-resolution winter river bend background for the default fishing spot "新手河湾".
Scene/backdrop: quiet snowy mountain river bend, river flowing from center distance toward lower foreground, pine forest and snowy banks on the right, distant mountain peak, soft empty haze toward upper-left and left side.
Subject: environment only. No fisher, no cat, no lantern, no bobber, no fishing line, no UI, no text.
Style/medium: premium 2D painterly game background, soft watercolor/gouache mood with clean high-fidelity brushwork. Not photorealistic, not anime, not pixel art, not sticker style.
Composition/framing: 4:3 landscape. Must work when cropped or downsampled to 520x400 art coordinates and displayed around 2x size. Keep the lower-right bank/rock area usable for character overlays. Keep the left side softly feathered or low-detail so it blends into the desktop/window.
Materials/textures: clean snow, smooth river reflections, pine silhouettes, distant mountain rock, soft mist. Fine painterly detail, but no rough paper grain.
Constraints: no UI, no labels, no people, no animals, no fishing gear, no watermark, no text. Avoid hard black outlines and saturated fantasy colors.
Avoid: coarse grain, noisy watercolor bloom, mottled AI texture, visible paper fibers, compression artifacts, over-sharpened micro-detail, muddy blur, dramatic fantasy lighting.
Output target: generate at least 1560x1200 source; downsample/crop to 1040x800 for HD runtime and 520x400 for legacy fallback.
```

## Phase Variants

Append one of these phase blocks to the base prompt.

### dawn

```text
Phase: dawn.
Lighting/mood: pale sunrise, faint peach light behind mist, quiet cold morning.
Color palette: soft peach, pale gold, blue-gray snow, low saturation.
Scenic identity: this is river_bend's best scenic time, "晨雾日出"; it should feel special but still calm.
```

### day

```text
Phase: day.
Lighting/mood: overcast winter daylight, clear but gentle visibility, no harsh sun.
Color palette: clean snow white, muted blue water, gray pine and mountain tones.
Scenic identity: neutral readable default daytime background.
```

### dusk

```text
Phase: dusk.
Lighting/mood: soft late dusk afterglow, pink-violet haze over the snow and mountain, quiet transition into evening.
Color palette: muted mauve, blue-gray, soft rose highlights, no saturated purple.
Scenic identity: gentle evening variant, not dramatic fantasy.
```

### night

```text
Phase: night.
Lighting/mood: cold blue moonlit winter night, soft mist over the river, very low contrast but readable forms.
Color palette: muted blue-gray, charcoal pine, snow highlights, subtle cool glow.
Scenic identity: calm night fishing atmosphere; do not add bright stars, aurora, or high-contrast fantasy lighting.
```

## Do Not Change

- Do not redesign UI.
- Do not change fishing gameplay.
- Do not move character/pet/lantern anchors unless screenshot validation proves a background alignment issue.
- Do not replace all other fishing spots yet.
- Do not delete existing 520 backgrounds; keep fallback stable.
