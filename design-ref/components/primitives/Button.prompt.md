`Button` — the bronze/glass/ghost action button used across every panel.

```jsx
<Button variant="primary" size="md" onClick={sell}>卖 110</Button>
<Button variant="secondary">全部卖出</Button>
<Button variant="ghost" size="sm">锁</Button>
<Button variant="primary" icon="assets/ui/icon_coin.png">交付</Button>
```

- **variant**: `primary` (warm bronze, dark ink — sell / deliver / upgrade / go), `secondary` (gray glass, cream text — neutral actions), `ghost` (invisible until hover — the favourite-lock toggle).
- **size**: `sm` 24px · `md` 32px · `lg` 38px.
- Hover lightens the face; press darkens it. No shrink/bounce — the widget stays calm.
- Pass `icon` for a leading glyph (coin, sell). Always keep the price ON the sell button (`卖 110`) per the in-game pattern.
