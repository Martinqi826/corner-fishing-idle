`SummaryStrip` — the overview row at the top of the bag's 背包 tab.

```jsx
<SummaryStrip used={8} capacity={20} value={885} coinIcon="assets/ui/icon_coin.png" />
```

- Left: a labelled **capacity meter** (turns warm-gold when full); right: the **sellable total** in big serif numerals beside a coin glyph.
- Replaces the old crowded action row — it puts the two decision-driving numbers (how full, how much it's worth) up front instead of hiding value in a tooltip.
