# UI Kit — 角落垂钓 Corner Fishing (game widget)

A high-fidelity, interactive recreation of the desktop fishing companion. It is **not** a storybook — `index.html` boots the widget exactly as a player meets it: a painterly winter scene anchored in the screen corner, a flat HUD floating over it, and three round widget buttons that open the tabbed panel.

## Files
- `index.html` — entry; loads the design-system bundle + `data.js` + `app.jsx`.
- `data.js` — fake game state (`window.CF_DATA`): a sample basket, a 24-entry codex slice, the three fishing spots.
- `app.jsx` — the whole widget. Composes design-system components (`Panel`, `TabBar`, `Card`, `Button`, `RoundButton`, `Toggle`, `Slider`, `ProgressBar`, `FishRow`, `DexCard`, `SpotCard`, `HudChip`, `FishIcon`) read from `window.CornerFishingDesignSystem_301be0`.

## What's interactive
- **Round buttons / HUD chips** open the panel to a specific tab (rod→设置, basket→背包, coin→图鉴; chips deep-link to 钓点 / 订单).
- **背包** — sort (最新/价值/品阶/重量), lock a catch (ghost 锁 toggle), sell one (`卖 N`) or 全部卖出; coins update live.
- **图鉴 / 订单 / 钓点 / 设置** — the real panel layouts, populated from sample data.

## Notes
- The desktop wallpaper behind the widget is a neutral stand-in — in production the window is per-pixel transparent and the scene feathers into the user's real wallpaper.
- Everything is cosmetic: no save system, economy balance, or RNG — just the look and flow.
