# Dynamic Art Plan

## Principle

The scene should remain calm and painterly. Motion should be noticed over time, not demand attention in a single frame. All effects are transparent overlays on top of `assets/art/background/corner_scene_winter_base.png`.

## Asset Groups

### Water Shimmer

Files:

```text
assets/art/effects/water/water_shimmer_01.png
assets/art/effects/water/water_shimmer_02.png
assets/art/effects/water/water_shimmer_03.png
assets/art/effects/water/water_shimmer_04.png
assets/art/effects/water/water_shimmer_05.png
assets/art/effects/water/water_shimmer_06.png
```

Usage:

- Draw at `(0, 0)` over the main scene.
- Play as a 6-frame loop.
- Recommended duration: `4.8s` to `7.2s` per loop.
- Recommended opacity: `0.35` to `0.65`.
- Use additive/lighten blending only if it stays subtle. Normal alpha blending is safer.

### Mist Drift

Files:

```text
assets/art/effects/mist/mist_drift_01.png
assets/art/effects/mist/mist_drift_02.png
assets/art/effects/mist/mist_drift_03.png
```

Usage:

- Draw at `(0, 0)` over background but under UI and character overlays.
- Slowly move each layer by `8-18 px` horizontally over `18-35s`, then loop.
- Recommended opacity: `0.25` to `0.55`.
- Use different speed per layer to avoid a mechanical loop.

### Snow Drift

Files:

```text
assets/art/effects/snow/snow_drift_01.png
assets/art/effects/snow/snow_drift_02.png
assets/art/effects/snow/snow_drift_03.png
```

Usage:

- Draw at `(0, 0)` over the scene.
- Move gently down-right by `12-28 px` over `12-22s`.
- Recommended opacity: `0.18` to `0.38`.
- Snow should be sparse. Disable or reduce opacity if it competes with desktop readability.

### Bobber Ripple

Files:

```text
assets/art/effects/ripple/bobber_ripple_01.png
assets/art/effects/ripple/bobber_ripple_02.png
assets/art/effects/ripple/bobber_ripple_03.png
assets/art/effects/ripple/bobber_ripple_04.png
```

Usage:

- Center around the bobber.
- Play only on idle bobber pulses or fish bite events.
- Recommended duration: `0.7s` to `1.2s`.
- Recommended opacity: `0.5` to `0.9`.

### Lantern Glow

Files:

```text
assets/art/effects/light/lantern_glow_01.png
assets/art/effects/light/lantern_glow_02.png
assets/art/effects/light/lantern_glow_03.png
assets/art/effects/light/lantern_glow_04.png
```

Usage:

- Place centered near the lantern.
- Recommended approximate position for 520 x 400 window: `(438, 274)`.
- Play as a slow ping-pong pulse.
- Recommended duration: `3.5s` to `5.5s`.
- Recommended opacity: `0.45` to `0.8`.

### Wildlife Events

Files:

```text
assets/art/wildlife/bird_fly_01.png
assets/art/wildlife/rabbit_idle_01.png
assets/art/wildlife/fox_peek_01.png
assets/art/wildlife/fish_jump_01.png
```

Usage:

- These are occasional event sprites, not permanent decoration.
- Trigger no more than once every `45-120s`.
- Keep them small.

Recommended placements:

- Bird: far sky/mountain area, scale `0.22-0.35`, glide left or right for `5-9s`.
- Rabbit: snowy bank edge, scale `0.18-0.28`, appear for `4-8s`, then fade.
- Fox: far right grass/rocks, scale `0.18-0.28`, peek for `3-6s`, then fade.
- Fish jump: river near bobber, scale `0.22-0.35`, quick arc over `0.7-1.1s` plus ripple.

## Layer Order

Recommended draw order:

1. Main scene background.
2. Mist drift.
3. Water shimmer.
4. Snow drift.
5. Wildlife event sprites.
6. Bobber ripple / bite effects.
7. Lantern glow, using low opacity so it does not cover UI.
8. UI hover/pressed states.

## Motion Rules

- Avoid constant large movement.
- Avoid particles over the whole desktop.
- Keep loops slow and slightly irregular.
- Use random delay offsets so all effects do not restart together.
- Prefer opacity, tiny position shifts, and occasional events over large animation.

## Preview Images

```text
docs/img/dynamic_asset_contact_sheet.png
docs/img/dynamic_scene_preview.png
```

These previews are for checking assets and layer feel. The final in-game opacity should be tuned lower than the preview if desktop readability suffers.
