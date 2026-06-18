`DexCard` — a fish-encyclopedia (图鉴) cell. Composes `FishIcon`. **Legibility-first**: rarity is read from a tier **rail + frame ring**, so the name stays high-contrast dark ink on parchment (the old tier-coloured, outlined name was the unreadable part).

```jsx
<DexCard src="assets/fish/gudgeon.png" name="棒花鱼" tier={0}
         known count={1} maxWeight={0.04} variants={[]} />
<DexCard src="assets/fish/koi.png" name="锦鲤" tier={4} known
         count={12} maxWeight={6.1} collected giant variants={[2]} />
<DexCard src="assets/fish/oarfish.png" tier={5} name="皇带鱼" known={false} />
```

- Known → parchment card, left **tier rail**, dark-ink name, a record line (`×count · 最大 …kg`), a **/10 collection meter** (becomes `✦ 集齐` at 10), and marks for `巨` / `完★` / rare-variant dots.
- Unknown → dim grayscale silhouette + "未发现". Lay out 4 across; cards fill their grid column.
