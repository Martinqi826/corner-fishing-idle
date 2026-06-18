`HudChip` — a flat text line that floats directly on the scene (no card behind it). The only persistent on-screen readout.

```jsx
<HudChip tone="default" size={16} icon="assets/ui/icon_coin.png">金币 5384　鱼篓 10/20</HudChip>
<HudChip tone="default" onClick={openSpot}>新手河湾 · 黄昏</HudChip>
<HudChip tone="gold" onClick={openOrder}>订单  ≥3.0kg  2/2</HudChip>
```

- Always text-shadowed so it reads over any wallpaper. No background plate — keep the scene breathing.
- `tone` carries live state: `gold` (merchant / order-ready), `warn` (basket full), `positive` (order done), `water` (ambient).
- Pass `onClick` to make it a tappable shortcut into the matching panel/tab.
