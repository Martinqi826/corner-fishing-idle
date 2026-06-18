`Card` — the three surface containers used inside a `Panel`.

```jsx
<Card surface="paper">每日订单内容…</Card>
<Card surface="row" interactive>背包里的一条鱼…</Card>
<Card surface="row" locked>未解锁的钓点…</Card>
```

- **paper** — warm parchment (#E8E0C7) for codex cards, orders, stats rows; ink text.
- **row** — dark translucent inset for bag entries / lists; hover lightens.
- **glass** — faint translucent block for sub-sections.
- `locked` dims + desaturates (locked spots, unowned dex entries).
