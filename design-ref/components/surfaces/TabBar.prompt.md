`TabBar` — the pill tab row that switches sections inside the bag panel.

```jsx
{/* dense list nav — fills pills, wraps */}
<TabBar tabs={["背包","图鉴","订单","成就","统计","钓点","鱼缸"]} active={tab} onChange={setTab} />

{/* light primary nav — gold underline + a right-aligned overflow */}
<TabBar variant="underline" tabs={["背包","图鉴","订单","钓点"]}
        active={tab} onChange={setTab} overflow="更多 ▾" onOverflow={openMore} />
```

- **pill** (default): active = bronze/dark-ink, inactive = gray glass; wraps when it overflows.
- **underline**: lighter chrome for a 4–5 item primary nav — active gets a gold underline, the rest are ghost text; `overflow` adds a right-aligned "更多" to fold secondary destinations. Prefer this over 8–9 wrapping pills.
- Keep labels to 2 chars where possible — this is a small surface.
