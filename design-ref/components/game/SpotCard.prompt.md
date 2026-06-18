`SpotCard` — a fishing-location card in the 钓点 tab. Composes `Button`.

```jsx
<SpotCard name="新手河湾" desc="最初的那方静水…" got={6} total={44} unlocked current event="风平浪静" />
<SpotCard name="静水湖泊" desc="水草丰茂的冬日湖湾…" got={5} total={43} unlocked onGo={go} />
<SpotCard name="海岸码头" desc="海风咸涩…" unlocked={false} unlockText="累计渔获 120 条解锁" />
```

- Three states: **current** (parchment, 📍, disabled 当前), **unlocked** (parchment, bronze 前往), **locked** (dim row, 未解锁 + 🔒 requirement).
- Spot name uses the serif display voice. Footer shows species collection + the live event when current.
