# 角落垂钓 Corner Fishing — Design System

A design system for **角落垂钓 (Corner Fishing)** — a calm, idle, *desktop-ornament* fishing game. It lives pinned in the lower-right corner of the screen, blends into the user's wallpaper through per-pixel transparency and edge feathering, and quietly catches fish for you while you work. Think "a small still pond in the corner of your desk," in the niche of *Rusty's Retirement*.

This system captures the game's two coexisting UI worlds — the **painterly winter scene** and the **dark-glass / warm-paper panel chrome** — as tokens, components, foundation cards, and an interactive UI-kit recreation, so future UI work stays on-brand and can be raised in quality without drifting.

## Sources
- **Codebase:** `fish-idle/` — Godot 4.6 (GDScript), 2D, GL Compatibility renderer. Read-only mount.
  - UI build code: `ui_panels.gd` (all panels/tabs/cards), `main.gd` (HUD, scene, theme, tier colours), `fish_data.gd` (tiers, qualities, variants, palettes), `spot_data.gd`, `event_data.gd`, `weather.gd`.
  - Art: `assets/art/**` (backgrounds, character, props, equipment, 60+ painterly fish icons, UI buttons, badges, event icons).
  - Direction docs: `docs/art_direction.md` (the canonical palette + style bar), `docs/project_overview.html` (white-paper), `docs/img/*` (engine screenshots of every panel — `panel_bag`, `panel_dex`, `panel_spot`, `panel_order`, `panel_settings`, `scene_*`, etc.).
- All colour/type/spacing values here are lifted **1:1 from the Godot source**, not guessed.

> Game is in Simplified Chinese. All copy, examples, and labels in this system are zh-CN to match.

---

## CONTENT FUNDAMENTALS — how copy is written

The voice is **quiet, warm, and literary** — a companion murmuring beside you, never a game barking for attention. It matches the "unintrusive desktop ornament" premise.

- **Tone:** cosy, observational, faintly poetic. Spot descriptions read like prose, not stat blocks: *"最初的那方静水，缓流绕过雪岸。从白条到国宝鲟，什么都可能上钩。"* / *"海风咸涩，浪拍木桩，小灯在栈桥尽头摇。"*
- **Person:** mostly **impersonal / imperative** — the game gently instructs ("点右下角鱼篓", "等浮漂动一动", "锁定的目标鱼会留在鱼篓里"). It rarely says "你"; it never says "我". Empty states are soft, not nagging: *"鱼篓还是空的，等浮漂动一动。"*
- **Casing & script:** Simplified Chinese throughout. Numbers are Arabic (`金币 5384`, `×2.5`, `9.95kg`). Latin appears only in units (`kg`) and tags.
- **Brevity:** UI labels are 2 characters where possible (`背包 图鉴 订单 成就 统计 钓点 鱼缸 装备 设置`); buttons are verbs (`卖出`, `交付`, `前往`, `扩容`, `领取`). The **price lives on the button** — `卖 504`, not a separate price + a generic "Sell".
- **Punctuation flourish:** full-width interpunct `·` and spaced `　` separate clauses in dense lines (`新手河湾 · 黄昏`, `收集 6/106　·　变体 0/318　·　渔获 6`).
- **Emoji:** used **sparingly and functionally**, never decoratively — `📍` marks the current spot, `🔒` marks locked, `🐟`/`🎣` head a couple of section labels, `✓`/`○` for achievement done/not. Rarity/quality use typographic marks instead: `★` stars, `◆` variant gem, `✦集齐`.
- **Vibe in one line:** *understated companionship.* Reward the player with a soft pop-up (`满篓兑 +N`, `成就达成：名贵之鱼（+150 金币）`) and let them return to their work.

---

## VISUAL FOUNDATIONS

**Two surfaces, one warm accent.** Everything is built from a restrained cold-winter palette with a single lantern-warm accent (gold→bronze). There are no second accent hues.

- **Colour vibe:** muted, cool, painterly — snow haze, blue-gray mountains, pine green-gray, muted teal water, neutral rock. Imagery is **warm-cool balanced, low-saturation, soft** (watercolour realism). The one warmth is the lantern/gold UI. Explicitly avoided: saturated neon, large flat pure-black, blue/purple fantasy lighting.
- **Rarity colour system (the core signal):** fish grade is read from the **name's colour**, not a label — 普通 gray → 优良 green → 稀有 blue → 史诗 purple → 传说 orange → 神话 red. Orthogonal **rare variants** (斑斓 cyan / 鎏金 gold / 七彩 violet) add a ◆ gem + an icon glow. See `guidelines/colors-tiers.html`, `colors-variants.html`.
- **Type:** in-engine it's Microsoft YaHei (system sans) at compact sizes (10–20px). Here: **Noto Sans SC** for everything functional + **Noto Serif SC** as a display voice for panel titles, spot names, and hero numerals (echoes the painterly scroll mood). Numerals are tabular. ⚠ See *Font substitution* below.
- **Two surfaces:**
  - **Dark glass** — the floating panel chrome: `rgba(31,33,31,.94)`, 16px radius, **hairline warm border** (never heavy black), soft drop shadow, slight backdrop blur. Holds dark inset rows for lists.
  - **Warm paper** — parchment cards (`#E8E0C7`) that float *inside* the glass for codex, orders, stats; ink-coloured text, 12px radius.
- **Backgrounds:** the world is **full-bleed painterly illustration** anchored bottom-right; the rest of the window is transparent. No gradients-as-decoration, no patterns/textures behind UI. Panels sit on translucent glass over the scene/wallpaper.
- **Edge treatment:** scenes **never end in a hard rectangle** — they dissolve toward the top-left via a radial alpha feather (`--feather-mask`, mirroring the engine's `feather_mask.gdshader`). See `guidelines/feather-edge.html`.
- **Corners:** 16 panel · 12 card · 9 row · 8 button · 999 pill. Soft, friendly, consistent.
- **Borders & shadows:** 1px warm hairline borders everywhere; elevation via soft, low-opacity drop shadows (`--shadow-panel`, `--shadow-card`) — no hard or coloured shadows. Cards = subtle shadow + hairline; no heavy outlines.
- **Transparency & blur:** the whole widget is translucent over the desktop; the panel uses a light backdrop blur. Opacity is even user-adjustable (设置 → 不透明度).
- **Animation:** **calm and slow** — this is an idle companion. Water shimmer (3–6s loop, low opacity), bobber bob (2–4px, slow), lantern glow pulse, bite dip + ripple. Easing is gentle (`--ease-calm`), durations 120ms (feedback) / 220ms (state) / 600ms (ambient). **No bounce, no aggressive arcade motion, no infinite attention-grabbing loops on UI.**
- **Hover / press conventions:**
  - hover → **lighten** the surface ~6% (buttons, rows, tabs); ghost controls (the 锁 toggle) are invisible until hover, then take a dark-row tint.
  - press → **darken** the surface. Buttons do **not** shrink; round widget buttons do a tiny `scale(0.96)`.
  - focus → no ring (this is chrome-less desktop furniture); a faint gold outline only on keyboard focus.
- **Layout rules:** the scene is **fixed bottom-right**; the three round buttons sit at the very corner; HUD chips stack flat above them with text-shadow (no plate). Panels open centred in the larger transparent window and are draggable by their header. Panel width is canonically **520px**.

---

## ICONOGRAPHY

The brand's iconography is **painterly raster (PNG), not vector or icon-font** — it matches the watercolour world rather than a flat UI set.

- **Fish icons:** 60+ hand-illustrated **64×64 PNGs** with soft drop shadows, on transparency (`assets/fish/*.png`). A curated cross-tier set is copied in (`whitebait`→`oarfish`), plus **generic tier silhouettes** `generic_tier0…5.png` used as graceful fallbacks when a species' art is missing (the engine never crashes on a missing icon — neither should we; `FishIcon` takes `fallbackSrc`).
- **Equipment & props:** painterly PNGs — `rod_wood`/`rod_carbon`, `hook_basic`, `bait_jar`, `tackle_box`, `fish_basket`, `coin_pouch`, `line_spool` (`assets/equipment/`); `lantern`, `bobber_idle`/`bobber_bite`, `rod` (`assets/props/`).
- **Round HUD buttons:** dark "desktop-widget" metal/glass discs with a painted glyph — `ui_button_rod`, `ui_button_fish`, `ui_button_coin` (`assets/ui/`). They read as small physical objects, *not* mobile-game buttons.
- **Small UI glyphs:** `icon_coin`, `icon_weight`, `icon_capacity`, `icon_sell`, `icon_dex` (`assets/ui/`) for ledger/meta lines. Event icons: `event_fish_run`, `event_fog`, `event_tide`, `event_crate`, `event_release`.
- **Typographic & emoji marks:** rarity/quality/collection use glyphs not icons — `★` (quality), `◆` (rare variant), `✦集齐`, `巨`, `完★`, `●` (variant-seen dots). Functional emoji only: `📍 🔒 🐟 🎣 ✓ ○`.
- **Rule:** never hand-draw SVG fish/props or substitute emoji for the painterly icons. Copy real art in; fall back to a tier silhouette if absent.

⚠ **Font substitution:** the game uses Windows system fonts (Microsoft YaHei UI / SimHei). For web delivery this system substitutes **Noto Sans SC** (≈ YaHei) and adds **Noto Serif SC** for display. If you have the original/licensed CJK font files (or prefer Source Han Sans/Serif), drop them in and add `@font-face` rules — keep the token names.

---

## Index / manifest

**Root**
- `styles.css` — the single entry consumers link (only `@import`s).
- `tokens/` — `fonts.css`, `colors.css`, `typography.css`, `spacing.css`, `effects.css`.
- `assets/` — `scenes/` (3 spots + winter base + water overlay), `character/`, `props/`, `equipment/`, `ui/` (round buttons, glyphs, events), `fish/` (curated set + generic fallbacks).
- `SKILL.md` — Agent-Skills wrapper for use in Claude Code.

**Components** (`window.CornerFishingDesignSystem_301be0.*`)
- `components/primitives/` — `Button`, `RoundButton`, `Toggle`, `Slider`, `ProgressBar`, `Badge`.
- `components/surfaces/` — `Panel`, `Card`, `TabBar`.
- `components/game/` — `FishIcon`, `FishRow` (rich row), `DexCard`, `SpotCard`, `HudChip`, `HudLedger`, `SummaryStrip`.
- Each has a `.d.ts` contract + `.prompt.md` usage note; each directory has one `@dsCard` demo HTML.

**Foundation cards** (`guidelines/*.html`) — Colors (tiers, variants, scene, accents, surfaces), Type (display, scale, numerals), Spacing (scale, radii, elevation, feather), Brand (wordmark, scene, fish, equipment).

**UI kit** (`ui_kits/corner_fishing/`) — interactive game-widget recreation. See its `README.md`.

---

## Using this system
- **Throwaway artifacts** (mocks, slides, promo): link `styles.css`, copy assets out, build static HTML using the tokens + foundation patterns.
- **Production / prototypes:** load `_ds_bundle.js`, read components from `window.CornerFishingDesignSystem_301be0`, and follow the component `.prompt.md` notes. The UI kit is the reference for composition.
- Run `check_design_system` after edits to validate.
