`RoundButton` — the round painterly widget buttons that live in the screen corner (rod, fish-basket, coin / shop).

```jsx
<RoundButton icon="assets/ui/ui_button_fish.png" title="鱼篓" badge={6} onClick={openBag} />
<RoundButton icon="assets/ui/ui_button_rod.png" title="装备" />
<RoundButton icon="assets/ui/ui_button_coin.png" title="商店" />
```

- Renders a 40px PNG face with a soft drop shadow; hover lifts 1px + brightens, press shrinks slightly.
- `badge` adds a small rust count bubble (basket fullness, unread). Keep these three as the only persistent on-scene chrome.
