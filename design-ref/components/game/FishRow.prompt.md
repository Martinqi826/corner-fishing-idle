`FishRow` — the rich, full-width basket entry. Composes `FishIcon`.

```jsx
<FishRow src="assets/fish/koi.png" fallbackSrc="assets/fish/generic_tier4.png"
  name="锦鲤" tier={4} variant={2} quality={2} weight={3.10}
  value={1820} coinIcon="assets/ui/icon_coin.png" locked
  onSell={sell} onToggleLock={toggle} />
```

- **Layout:** tier-framed icon + a 3px tier/variant **rail** · tier-coloured name (◆ gem for variants) · tag row (variant pill `鎏金 ×5`, 大物 pill, ★ quality, weight) · favourite **lock icon** · **coin-pill price**.
- **Rarity is doubly encoded** — name colour *and* the rail/frame — so it survives weak colour vision.
- **Emphasis:** tier ≥4 or any variant tints the whole row + glows the icon (override with `emphasis`).
- **Price = action:** the coin pill *is* the sell button (`coinIcon` optional). Locked → reads 锁定, disabled. Lay these out **single-column** at widget width for breathing room.
