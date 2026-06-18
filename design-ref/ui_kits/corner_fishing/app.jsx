/* 角落垂钓 — interactive widget recreation. Composes the design-system
   components from window.CornerFishingDesignSystem_301be0 (read inside App
   so it stays safe regardless of script-eval order). */

function App() {
  const NS = window.CornerFishingDesignSystem_301be0 || {};
  const { Panel, TabBar, Card, Button, RoundButton, Toggle, Slider, ProgressBar,
          FishRow, DexCard, SpotCard, HudChip, Badge, FishIcon } = NS;
  const D = window.CF_DATA;
  const COIN = "../../assets/ui/icon_coin.png";

  // Resilient to bundle lag: use the real DS components, but never hard-crash
  // to black if a freshly-added one hasn't landed in the served bundle yet.
  const HudLedger = NS.HudLedger || (({ coins, used, capacity }) => (
    <div style={{ display: "inline-flex", alignItems: "center", gap: 8, padding: "7px 12px",
      borderRadius: 12, background: "rgba(26,27,23,.62)", border: "1px solid rgba(224,214,189,.28)",
      backdropFilter: "blur(6px)", color: "#f7e9c8", fontFamily: "var(--font-display)", fontWeight: 900 }}>
      <img src={COIN} width="18" height="18" alt="" />
      <span style={{ fontSize: 18, fontVariantNumeric: "tabular-nums" }}>{Number(coins).toLocaleString()}</span>
      <span style={{ width: 1, height: 22, background: "rgba(224,214,189,.3)" }} />
      <span style={{ fontFamily: "var(--font-sans)", fontWeight: 400, fontSize: 11, color: "#d8d2c4" }}>鱼篓 {used}/{capacity}</span>
    </div>
  ));
  const SummaryStrip = NS.SummaryStrip || (({ used, capacity, value }) => (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 14,
      background: "rgba(0,0,0,.22)", border: "1px solid var(--glass-row-border)", borderRadius: 12,
      padding: "11px 14px", fontFamily: "var(--font-sans)" }}>
      <span style={{ fontSize: 12, color: "var(--text-muted-glass)" }}>鱼篓容量 {used}/{capacity}</span>
      <span style={{ fontFamily: "var(--font-display)", fontWeight: 900, fontSize: 22, color: "var(--gold-bright)" }}>
        {Number(value).toLocaleString()}<span style={{ fontFamily: "var(--font-sans)", fontWeight: 400, fontSize: 11, color: "var(--text-muted-glass)", marginLeft: 6 }}>可卖</span>
      </span>
    </div>
  ));

  const [open, setOpen] = React.useState(null);      // null | "bag"
  const [tab, setTab] = React.useState(0);
  const [inv, setInv] = React.useState(D.inventory);
  const [coins, setCoins] = React.useState(5384);
  const [sort, setSort] = React.useState(0);
  const [mute, setMute] = React.useState(false);
  const [vol, setVol] = React.useState(72);
  const [sfx, setSfx] = React.useState(80);
  const [amb, setAmb] = React.useState(40);
  const [focus, setFocus] = React.useState(false);
  const [opacity, setOpacity] = React.useState(100);

  const cap = 20;
  const SORTS = ["最新", "价值", "品阶", "重量"];

  function sellOne(i) {
    const f = inv[i];
    if (f.locked) return;
    setCoins((c) => c + f.value);
    setInv((arr) => arr.filter((_, j) => j !== i));
  }
  function toggleLock(i) {
    setInv((arr) => arr.map((f, j) => (j === i ? { ...f, locked: !f.locked } : f)));
  }
  function sellAll() {
    const gain = inv.filter((f) => !f.locked).reduce((s, f) => s + f.value, 0);
    setCoins((c) => c + gain);
    setInv((arr) => arr.filter((f) => f.locked));
  }

  const sorted = React.useMemo(() => {
    const a = inv.map((f, i) => ({ f, i }));
    if (sort === 1) a.sort((x, y) => y.f.value - x.f.value);
    else if (sort === 2) a.sort((x, y) => y.f.tier - x.f.tier);
    else if (sort === 3) a.sort((x, y) => y.f.weight - x.f.weight);
    return a;
  }, [inv, sort]);

  const unlockedCount = inv.filter((f) => !f.locked).length;
  const totalValue = inv.filter((f) => !f.locked).reduce((s, f) => s + f.value, 0);

  // ---- tab bodies ----
  function BagTab() {
    return (
      <div style={S.col}>
        <SummaryStrip used={inv.length} capacity={cap} value={totalValue} coinIcon={COIN} />
        <div style={S.sortRow}>
          <div style={S.seg}>
            {SORTS.map((s, m) => (
              <button key={m} onClick={() => setSort(m)}
                style={{ ...S.segBtn, ...(m === sort ? S.segBtnOn : {}) }}>{s}</button>
            ))}
          </div>
          <span style={{ flex: 1 }} />
          <button style={S.filterBtn}>订单鱼</button>
        </div>
        <div style={S.scroll}>
          <div style={S.bagList}>
            {sorted.map(({ f, i }) => (
              <FishRow key={f.id + i} src={f.src} fallbackSrc={D.fb(f.tier)} name={f.name}
                tier={f.tier} variant={f.variant} quality={f.quality} weight={f.weight}
                sizeTag={f.sizeTag} locked={f.locked} value={f.value} coinIcon={COIN}
                onSell={() => sellOne(i)} onToggleLock={() => toggleLock(i)} />
            ))}
          </div>
        </div>
        <div style={S.footBar}>
          <Button variant="secondary" size="sm">卖杂鱼</Button>
          <span style={{ flex: 1 }} />
          <Button variant="secondary" size="sm">扩容</Button>
          <Button variant="primary" size="sm" disabled={unlockedCount === 0} onClick={sellAll}>
            全部卖出{totalValue > 0 ? ` · +${totalValue}` : ""}
          </Button>
        </div>
      </div>
    );
  }

  function DexTab() {
    const got = D.dex.filter((d) => d.known).length;
    return (
      <div style={S.col}>
        <div style={S.statLine}>收集 {got}/106　·　变体 3/318　·　渔获 152</div>
        <div style={S.scroll}>
          <div style={S.dexGrid}>
            {D.dex.map((d) => (
              <DexCard key={d.id} src={d.src} fallbackSrc={D.fb(d.tier)} name={d.name} tier={d.tier}
                known={d.known} count={d.count} maxWeight={d.maxWeight} collected={d.collected}
                giant={d.giant} perfect={d.perfect} variants={d.variants || []} />
            ))}
          </div>
        </div>
      </div>
    );
  }

  function OrderTab() {
    return (
      <div style={S.col}>
        <div style={S.statLine}>每日订单 · 2026-06-16</div>
        <Card surface="paper" pad={false}>
          <div style={{ display: "flex", gap: 12, padding: 12, alignItems: "center" }}>
            <FishIcon src={D.fb(2)} size={64} tier={2} frame />
            <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 4 }}>
              <div style={{ fontFamily: "var(--font-display)", fontWeight: 700, fontSize: 17, color: "var(--ink)" }}>收 3 条 优良及以上</div>
              <div style={{ fontSize: 12, color: "var(--ink-soft)", lineHeight: 1.5 }}>指定品阶订单 · 交付未上锁的符合渔获，按鱼价 ×2.5 结算</div>
              <div style={{ fontSize: 12, color: "var(--bronze)", fontWeight: 500 }}>可交付 2/3</div>
            </div>
            <Button variant="secondary" disabled>交付</Button>
          </div>
        </Card>
        <div style={{ fontSize: 12, color: "var(--text-muted-glass)" }}>锁定的目标鱼会留在鱼篓里，不会被订单交付。</div>
        <div style={{ height: 1, background: "var(--glass-row-border)", margin: "4px 0" }} />
        <div style={S.statLine}>本周挑战</div>
        <Card surface="paper">
          <div style={{ fontSize: 14, fontWeight: 500, color: "var(--ink)", marginBottom: 8 }}>本周累计钓到 160 条鱼</div>
          <ProgressBar value={80} max={160} surface="paper"
            caption={<><span>80 / 160</span><span>奖励 4500 金币</span></>} />
        </Card>
      </div>
    );
  }

  function SpotTab() {
    return (
      <div style={S.col}>
        <div style={S.statLine}>钓点 · 已解锁 2/3</div>
        <div style={S.scroll}>
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            {D.spots.map((s) => (
              <SpotCard key={s.id} name={s.name} desc={s.desc} got={s.got} total={s.total}
                unlocked={s.unlocked} current={s.current} event={s.event} unlockText={s.unlockText} />
            ))}
          </div>
        </div>
      </div>
    );
  }

  function SettingsTab() {
    return (
      <div style={{ ...S.col, gap: 14 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8, fontSize: 13, color: "var(--text-muted-glass)" }}>
          <span style={{ color: "var(--gold)" }}>🔒</span> 自动卖鱼
          <Badge tone="gold" variant="outline">高级功能 · 敬请期待</Badge>
        </div>
        <div style={{ height: 1, background: "var(--glass-row-border)" }} />
        <Toggle label="静音" checked={mute} onChange={setMute} style={{ justifyContent: "space-between", width: "100%" }} />
        <Slider label="主音量" value={vol} onChange={setVol} disabled={mute} />
        <Slider label="音效" value={sfx} onChange={setSfx} disabled={mute} />
        <Slider label="环境音" value={amb} onChange={setAmb} disabled={mute} />
        <Toggle label="专注模式（少打扰）" checked={focus} onChange={setFocus} style={{ justifyContent: "space-between", width: "100%" }} />
        <Slider label="不透明度" value={opacity} min={40} max={100} onChange={setOpacity} />
        <div style={{ display: "flex", flexDirection: "column", gap: 8, marginTop: 4 }}>
          <Button variant="secondary">回到右下角</Button>
          <Button variant="secondary">退出游戏</Button>
        </div>
      </div>
    );
  }

  const TABS = ["背包", "图鉴", "订单", "钓点", "设置"];
  const BODIES = [BagTab, DexTab, OrderTab, SpotTab, SettingsTab];
  const Body = BODIES[tab];

  return (
    <div style={S.desktop}>
      <div style={S.hint}>桌面挂件 · 点 <b>金币栏</b> 打开面板</div>

      {/* ---- corner scene ---- */}
      <div style={S.scene}>
        <img src="../../assets/scenes/spot_river_bend.png" alt="" style={S.sceneImg} />
        <img src="../../assets/character/fisher_idle.png" alt="" style={S.fisher} />
        <img src="../../assets/props/bobber_idle.png" alt="" style={S.bobber} />
        <div style={S.hud}>
          <div onClick={() => { setOpen("bag"); setTab(0); }} style={{ cursor: "pointer" }}>
            <HudLedger coins={coins} used={inv.length} capacity={cap} coinIcon="../../assets/ui/icon_coin.png" />
          </div>
          <HudChip onClick={() => { setOpen("bag"); setTab(3); }} tone="default" size={13}>新手河湾 · 黄昏</HudChip>
          <HudChip tone="gold" onClick={() => { setOpen("bag"); setTab(2); }}>
            <span style={{ fontWeight: 700 }}>订单 2/3</span>　还差 1 条
          </HudChip>
        </div>
      </div>

      {/* ---- panel ---- */}
      {open === "bag" && (
        <div style={S.overlay} onClick={(e) => { if (e.target === e.currentTarget) setOpen(null); }}>
          <Panel title="鱼篓" subtitle="2026-06-16" onClose={() => setOpen(null)} width={520}
            style={{ maxHeight: "86vh" }} bodyStyle={{ overflow: "hidden" }}>
            <TabBar variant="underline" tabs={TABS.slice(0, 4)} active={tab < 4 ? tab : -1}
              onChange={setTab} overflow={tab === 4 ? "设置 ✓" : "更多 ▾"} onOverflow={() => setTab(4)} />
            <div style={S.navRule} />
            <Body />
          </Panel>
        </div>
      )}
    </div>
  );
}

const S = {
  desktop: {
    position: "fixed", inset: 0, overflow: "hidden",
    background: "linear-gradient(160deg,#8893a0 0%,#9aa4ab 38%,#b4b3a6 72%,#ccc6b6 100%)",
    fontFamily: "var(--font-sans)",
  },
  hint: {
    position: "absolute", top: 18, left: 20, fontSize: 12, color: "rgba(40,44,48,.6)",
    background: "rgba(255,255,255,.34)", padding: "6px 12px", borderRadius: 999,
  },
  scene: { position: "absolute", right: 0, bottom: 0, width: 520, height: 420 },
  sceneImg: {
    position: "absolute", inset: 0, width: "100%", height: "100%", objectFit: "cover",
    objectPosition: "right bottom",
    WebkitMaskImage: "var(--feather-mask)", maskImage: "var(--feather-mask)",
  },
  fisher: { position: "absolute", right: 56, bottom: 70, width: 96, height: "auto", filter: "drop-shadow(0 2px 3px rgba(0,0,0,.3))" },
  bobber: { position: "absolute", right: 150, bottom: 74, width: 14, animation: "cf-bobber-bob 3s var(--ease-soft) infinite" },
  hud: { position: "absolute", right: 18, bottom: 150, display: "flex", flexDirection: "column", alignItems: "flex-end", gap: 7 },
  overlay: {
    position: "fixed", inset: 0, background: "rgba(20,22,20,.34)",
    display: "grid", placeItems: "center", zIndex: 100, backdropFilter: "blur(1px)",
  },
  col: { display: "flex", flexDirection: "column", gap: 10, minHeight: 0 },
  navRule: { height: 1, background: "var(--glass-row-border)", margin: "1px 0 0" },
  sortRow: { display: "flex", gap: 8, alignItems: "center" },
  seg: { display: "inline-flex", background: "rgba(0,0,0,.24)", borderRadius: 999, padding: 3, gap: 2 },
  segBtn: {
    height: 24, padding: "0 12px", borderRadius: 999, border: "none",
    background: "transparent", color: "var(--text-muted-glass)", fontSize: 12, cursor: "pointer",
    fontFamily: "var(--font-sans)",
  },
  segBtnOn: { background: "var(--bronze)", color: "var(--ink-on-gold)", fontWeight: 700 },
  filterBtn: {
    fontSize: 12, color: "var(--text-muted-glass)", cursor: "pointer",
    border: "1px solid var(--glass-row-border)", borderRadius: 999, padding: "4px 11px",
    background: "transparent", fontFamily: "var(--font-sans)",
  },
  scroll: { overflowY: "auto", overflowX: "hidden", maxHeight: "46vh", paddingRight: 6 },
  bagList: { display: "flex", flexDirection: "column", gap: 6 },
  footBar: { display: "flex", alignItems: "center", gap: 8, paddingTop: 8,
    borderTop: "1px solid var(--glass-row-border)" },
  dexGrid: { display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: 8, justifyItems: "center" },
  statLine: { fontSize: 13, color: "var(--text-muted-glass)" },
};

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
