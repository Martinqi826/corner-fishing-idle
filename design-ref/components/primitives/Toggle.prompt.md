`Toggle` — pill on/off switch (bronze when on) for Settings rows.

```jsx
<Toggle label="静音" checked={mute} onChange={setMute} />
<Toggle label="专注模式（少打扰）" checked={focus} onChange={setFocus} disabled />
```

- Track turns bronze + knob slides right when on; otherwise dark inset.
- Pair with a label on the left; the whole row is clickable.
