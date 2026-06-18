`Badge` — small rarity / status / variant marker. Carries the game's colour semantics.

```jsx
<Badge tone="tier-4" variant="text">传说</Badge>
<Badge tone="positive" variant="text">✦集齐</Badge>
<Badge tone="merchant" variant="pill">收鱼郎 ×1.5</Badge>
<Badge tone="tier-2" legible>稀有</Badge>   {/* on parchment */}
```

- **tone**: `tier-0…5` (普通→神话), `variant-1…3` (斑斓/鎏金/七彩), or status (`positive`, `merchant`, `rust`, `gold`).
- **variant**: `text` (default — coloured glyph, codex marks), `pill` (filled), `outline` (hollow).
- Set `legible` when a coloured badge sits on warm paper (adds a dark text-outline, matching the in-engine `badge_legible`).
