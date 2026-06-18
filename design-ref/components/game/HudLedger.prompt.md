`HudLedger` — the frosted-glass capsule that carries coins + basket status on the scene.

```jsx
<HudLedger coins={5384} used={8} capacity={20} coinIcon="assets/ui/icon_coin.png" />
```

- Coins in serif numerals beside a coin glyph · a divider · basket count with a **capacity micro-bar** (turns warm-gold when full).
- Pair it with low-key `HudChip`s for spot/time and order. Light backdrop blur keeps it readable over any wallpaper while still feeling translucent — never a heavy opaque plate.
