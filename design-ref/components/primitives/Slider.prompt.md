`Slider` — labeled range control with a live value readout (Settings: 主音量 / 音效 / 环境音 / 不透明度).

```jsx
<Slider label="主音量" value={vol} onChange={setVol} />
<Slider label="不透明度" value={op} min={40} max={100} onChange={setOp} />
```

- Label left, gold value right; thin dark track, cream thumb ringed in bronze.
- Provide `format` for non-percentage readouts.
