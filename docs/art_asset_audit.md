# Art Asset Audit

## Current Production-Ready Assets

- `assets/art/background/corner_scene_winter_base.png`
  - Godot-ready 520 x 400 transparent main scene.
  - Matches the required polished desktop corner quality.
- `assets/art/source/corner_scene_winter_final_source.png`
  - High-resolution source image for future crops, repainting, and layered animation planning.
- `assets/art/ui/ui_button_fish.png`
- `assets/art/ui/ui_button_rod.png`
- `assets/art/ui/ui_button_coin.png`
  - Cropped from the final source image, visually consistent with the main scene.
- `assets/art/fish/fish_common_01.png`
- `assets/art/fish/fish_common_02.png`
- `assets/art/fish/fish_rare_01.png`
  - Replaced with painterly production icons.
- `assets/art/props/bobber_idle.png`
- `assets/art/props/bobber_bite.png`
- `assets/art/props/lantern.png`
- `assets/art/props/rod.png`
  - Replaced with painterly transparent props.
- `assets/art/character/fisher_idle.png`
- `assets/art/character/fisher_pull_01.png`
- `assets/art/character/fisher_pull_02.png`
  - Replaced with consistent seated fisher animation frames.

## Source And Working Files

- `assets/art/source/fish_icons_source_v1.png`
- `assets/art/source/props_sprites_source_v1.png`
- `assets/art/source/props_sprites_source_v1_alpha.png`
- `assets/art/source/fisher_sprites_source_v1.png`
- `assets/art/source/fisher_sprites_source_v1_alpha.png`
- `assets/art/character/source/`
- `assets/art/fish/source/`
- `assets/art/props/source/`

These should be kept as source material for future refinements.

## Archived Placeholder Assets

- `assets/art/source/archive/corner_scene_winter_placeholder_v0.png`

This was an early procedural placeholder and should not be used for production.

## Remaining Optimization Opportunities

1. Main scene layering:
   - Split the final scene into background mountains, forest, water, foreground bank, fisher, and UI layers.
   - This will allow water shimmer, bobber movement, lantern glow, and UI hover without repainting the whole scene.

2. Character integration:
   - Current fisher frames are production usable, but slightly more character-sprite-like than the main scene.
   - A future pass can repaint them to reduce outline contrast and match the main source image even more closely.

3. Water animation assets:
   - `water_highlight_overlay.png` is still an old lightweight placeholder.
   - Replace with 3-5 painterly shimmer frames extracted or generated from the final river surface.

4. Interaction states:
   - Add hover/pressed variants for all three UI buttons.
   - Add bite-alert ripple frame and catch-success sparkle frame.

5. Fish collection expansion:
   - Current fish set has three icons.
   - Add at least 8-12 fish icons before building a satisfying collection loop.
