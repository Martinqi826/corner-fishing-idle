`ProgressBar` — bronze→gold fill bar for the weekly challenge and collection meters.

```jsx
<ProgressBar value={80} max={160} caption={<><span>80 / 160</span><span>奖励 4500 金币</span></>} />
<ProgressBar value={6} max={106} surface="paper" showPercent={false} />
```

- Use `surface="paper"` inside parchment cards so the track stays legible.
- The caption row is a flex space-between — left progress, right reward.
