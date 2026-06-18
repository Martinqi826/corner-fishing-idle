`Panel` — the floating dark-glass pop-up that holds every menu (鱼篓 / 设置 / 离线小结).

```jsx
<Panel title="鱼篓" subtitle="2026-06-14" onClose={close}>
  <TabBar tabs={["背包","图鉴","订单"]} active={0} onChange={setTab} />
  {/* tab body … */}
</Panel>
```

- Translucent #1F211F glass, 16px radius, hairline warm border, soft drop shadow, subtle backdrop blur.
- Header: serif title left, optional subtitle + close × right. Header reads as the drag handle.
- Body is a 10px-gap vertical stack. Default width 520px — the canonical widget panel.
