---
name: corner-fishing-design
description: Use this skill to generate well-branded interfaces and assets for 角落垂钓 (Corner Fishing) — a calm, idle, desktop-ornament fishing game — for production or throwaway prototypes/mocks. Contains essential design guidelines, colours, type, fonts, painterly assets, and UI-kit components for prototyping the game's dark-glass / warm-paper panel chrome and winter scene.
user-invocable: true
---

Read the `readme.md` file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, promo art), copy assets out of `assets/` and create static HTML files for the user to view, using the tokens in `styles.css` and the patterns in `guidelines/`. If working on production code, copy assets and read the rules here to become an expert in designing with this brand; the components live under `components/` (load `_ds_bundle.js`, read from `window.CornerFishingDesignSystem_301be0`) and the `ui_kits/corner_fishing/` recreation shows how they compose.

Key brand rules to honour:
- Two surfaces — dark translucent glass panels + warm parchment cards inside them; one warm accent (gold→bronze), restrained cold-winter palette otherwise.
- Rarity is read from fish-name COLOUR (普通 gray → 神话 red); rare variants add a ◆ gem + glow.
- Iconography is painterly raster PNG (never hand-drawn SVG or emoji substitutes); fall back to a `generic_tier{n}` silhouette if a fish's art is missing.
- Copy is quiet, warm, literary, Simplified Chinese; labels short, prices on buttons; emoji only functional.
- Motion is calm and slow; scenes feather into transparency, never a hard rectangle.

If the user invokes this skill without other guidance, ask them what they want to build or design, ask a few focused questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.
