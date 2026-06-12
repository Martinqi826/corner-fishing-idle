# Corner Fishing Idle - Art Direction

## Goal

The game should feel like a calm desktop ornament growing out of the lower-right corner of the screen: a small winter fishing scene that blends into the user's wallpaper, stays readable at a glance, and never feels like a normal rectangular game window.

The visual reference supplied by the product owner is not a loose style moodboard. It is the expected production-quality bar: polished painterly detail, finished environment art, refined atmosphere, readable small character and UI, and desktop-wallpaper-level integration.

## Visual Target

- Mood: quiet, cozy, cold winter morning, soft and unintrusive.
- Style: painterly 2D illustration with light realism. Avoid pixel art, hard cartoon outlines, and glossy mobile-game effects.
- Quality bar: final assets should match premium illustrated desktop-widget art. Do not ship vector-like placeholders, rough procedural drawings, or simplified mock assets as production art.
- Composition: most visual weight sits in the lower-right corner. The upper and left areas should remain mostly transparent or softly faded.
- Edge treatment: the scene must dissolve into transparency through fog, mist, snow haze, or soft alpha feathering. No hard rectangular edges.
- Desktop fit: the scene should work over arbitrary wallpapers. Keep contrast controlled and avoid large opaque blocks.

## Scene Elements

Primary elements:

- Snow mountain in the far background.
- Pine forest silhouettes and sparse winter vegetation.
- A narrow river or frozen-blue water surface.
- Snowy rocks and riverbank in the foreground.
- A seated fisher character facing left or slightly left-front.
- Fishing rod, fishing line, and bobber.
- A small lantern, tackle box, bucket, or backpack near the fisher.
- Three small round UI buttons near the bottom-right edge.

Optional seasonal details:

- Thin drifting mist above the water.
- Very small snow particles.
- Subtle warm glow from the lantern.
- Small ripples around the bobber.

## Canvas And Placement

Current Godot window target:

- Window size: 520 x 400.
- Main illustrated scene area: roughly the lower-right 260 x 180 px.
- Interactive area should stay near the visible scene and UI buttons.
- Top and left margins should remain transparent or near-transparent.

Recommended master image:

- `corner_scene_winter_base.png`
- Size: 520 x 400 px.
- Format: PNG with alpha.
- Main art anchored to bottom-right.
- Transparent/feathered fade toward top-left.
- Current final source reference: `assets/art/source/corner_scene_winter_final_source.png`.
- Current Godot-ready final image: `assets/art/background/corner_scene_winter_final_520x400.png`.

## Layering Strategy

Use separate assets instead of baking everything into one image when animation or interaction is expected.

Suggested layers:

- `background_mountains.png`: static distant mountains and sky haze.
- `background_forest.png`: pine forest and far bank.
- `water_base.png`: base water surface.
- `water_highlight_overlay.png`: animated shimmer/ripple overlay.
- `foreground_bank.png`: rocks, snow, grass, foreground details.
- `fisher_idle.png`: seated fisher idle pose.
- `fisher_pull_01.png`, `fisher_pull_02.png`: simple pull animation frames.
- `rod.png`: rod if it needs rotation or bending.
- `bobber_idle.png`: idle bobber.
- `bobber_bite.png`: bite state bobber.
- `lantern.png`: prop with optional glow layer.
- `ui_button_fish.png`, `ui_button_rod.png`, `ui_button_coin.png`: round icon buttons.

## Palette

Use a restrained winter palette with one warm accent.

Suggested colors:

- Snow haze: `#D8D2C4`, `#C9C2B5`, `#EEE8DC`
- Distant mountain blue-gray: `#9AA8AE`, `#B7C1C5`
- Pine dark green-gray: `#3F4D45`, `#58675E`
- Water muted teal-blue: `#476F78`, `#6E9298`, `#A7B8B7`
- Rock neutral gray: `#6E7068`, `#969486`
- Character coat olive/khaki: `#5F6652`, `#777B62`
- Warm lantern/UI accent: `#D6A85D`, `#F0C978`
- UI dark glass: `#333638`, `#4B4E50`

Avoid:

- Saturated neon colors.
- Large flat pure black shadows.
- Overly blue/purple fantasy lighting.
- Heavy beige-only monotone.

## Asset Style Rules

- Keep silhouettes readable at small size.
- Use soft detail density: enough texture to feel painterly, but not noisy.
- Use semi-transparent mist to blend the left/top scene edges.
- Avoid hard white cutouts around transparent PNGs.
- Avoid UI labels unless necessary; icons should communicate function.
- Round UI buttons should feel like small desktop widgets, not mobile game buttons.
- Keep the fisher as a small readable silhouette, not a detailed portrait.

## Animation Notes

Recommended subtle loops:

- Water shimmer: 3-6 second loop, low opacity.
- Bobber idle: slow vertical movement, 2-4 px range.
- Bobber bite: quick dip plus ripple.
- Fisher idle: tiny breathing/coat movement if separate frames exist.
- Lantern glow: slow opacity pulse.

Animation should remain calm. This is an idle desktop companion, not an attention-grabbing arcade scene.

## Initial Asset Batch

Priority 1:

- `corner_scene_winter_base.png`
- `water_highlight_overlay.png`
- `fisher_idle.png`
- `rod.png`
- `bobber_idle.png`
- `bobber_bite.png`
- `ui_button_fish.png`
- `ui_button_rod.png`
- `ui_button_coin.png`

Priority 2:

- `foreground_bank.png`
- `lantern.png`
- `fisher_pull_01.png`
- `fisher_pull_02.png`
- `fish_common_01.png`
- `fish_common_02.png`
- `fish_rare_01.png`

## Directory Proposal

```text
assets/art/background/
assets/art/character/
assets/art/props/
assets/art/fish/
assets/art/ui/
assets/art/source/
```

Source files or generation references should go in `assets/art/source/` when available. Runtime PNG files should stay in their specific category folders.

## Implementation Notes For Godot

- Use PNG assets with alpha.
- Use nearest-neighbor only if a future style shift goes pixel-art. For the current painterly style, use normal filtering.
- Keep large background assets premultiplied/clean-alpha safe to prevent dark fringes.
- Preserve bottom-right anchoring when resizing the window.
- Mouse passthrough should exclude transparent empty areas and include only the visible scene/buttons.
