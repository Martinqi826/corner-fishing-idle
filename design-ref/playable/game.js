// 角落垂钓 — game logic (state machine, economy, orders, dex, save). Numbers 1:1 with Godot source.
window.Game = (function () {
  const D = window.GAMEDATA;
  const SAVE_KEY = "corner_fishing_play_v1";

  const DAILY_ORDER_MULT = 2.5;
  const MERCHANT_MULT = 1.5;
  const OVERFLOW_SELL_RATE = 0.5;

  // ---- state ----
  const G = {
    coins: 0, rodLevel: 1, bagLevel: 1, baitLevel: 0, hookLevel: 0,
    inventory: [], dex: {}, /* id -> {count, variants:[bool*4], bestQ, bestW, bestV} */
    lifetimeCatches: 0, lifetimeCoins: 0, biggest: null, bestValue: 0,
    currentSpot: "river_bend", unlockedSpots: ["river_bend"],
    dailyOrder: null, achievements: {}, petSteals: 0,
    autoCast: true,
  };

  // runtime (not saved)
  let state = "idle";       // idle | wait | bite
  let stateT = 0;
  let merchant = { active: false, t: 0 };
  let event = null;         // {key,name,icon,t,wait,value,luck}
  let eventT = 0;
  let dayT = 0;             // day-night cycle seconds
  const DAY_LEN = 180;
  const cb = { catch: [], state: [], toast: [], update: [], event: [] };

  function on(ev, fn) { cb[ev].push(fn); }
  function emit(ev, ...a) { for (const fn of cb[ev]) fn(...a); }
  function toast(msg, color) { emit("toast", msg, color || "#ECE8E0"); }

  // ---- day phase ----
  const PHASES = [
    { key: "dawn", name: "黎明", wait: 0.9, sky: "rgba(255,214,160,0.10)" },
    { key: "day", name: "白昼", wait: 1.0, sky: "rgba(255,255,255,0)" },
    { key: "dusk", name: "黄昏", wait: 0.85, sky: "rgba(255,150,90,0.12)" },
    { key: "night", name: "夜晚", wait: 1.05, sky: "rgba(30,40,80,0.26)" },
  ];
  function phase() { return PHASES[Math.floor((dayT / DAY_LEN) * 4) % 4]; }

  // ---- events ----
  const EVENTS = [
    { key: "fish_run", name: "鱼汛", icon: "event_fish_run", dur: 45, wait: 0.6, value: 1, luck: 1, msg: "鱼汛来了——咬钩频频，运气大涨" },
    { key: "lucky_current", name: "幸运暗流", icon: "event_crate", dur: 50, wait: 1, value: 1.4, luck: 0, msg: "一股幸运暗流——这阵子鱼格外值钱" },
    { key: "tide_in", name: "涨潮", icon: "event_tide", dur: 40, wait: 0.7, value: 1, luck: 0, msg: "潮水涌上来，鱼群活跃" },
    { key: "morning_fog", name: "晨雾", icon: "event_fog", dur: 40, wait: 1.15, value: 1.25, luck: 0, msg: "晨雾弥漫，少有人扰，大鱼更舍得现身" },
  ];

  // ---- helpers ----
  function bagCap() { return D.BAG_CAPS[Math.min(G.bagLevel - 1, D.BAG_CAPS.length - 1)]; }
  function bagFull() { return G.inventory.length >= bagCap(); }
  function bagCost() { return G.bagLevel - 1 < D.BAG_COSTS.length ? D.BAG_COSTS[G.bagLevel - 1] : null; }
  function rodCost() { return D.rodCost(G.rodLevel); }
  function spotPool() { return D.poolFor(G.currentSpot); }
  function speciesCount() { return Object.keys(G.dex).length; }
  function variantCount() { let n = 0; for (const id in G.dex) for (let v = 0; v < 4; v++) if (G.dex[id].variants && G.dex[id].variants[v]) n++; return n; }

  function valueMult() {
    let m = D.SPOTS[G.currentSpot].value_mult;
    m *= phase().wait === 0.85 ? 1 : 1; // (phase doesn't change value)
    if (event) m *= event.value;
    if (merchant.active) m *= MERCHANT_MULT;
    return m;
  }

  // ---- fishing loop ----
  function beginWait() {
    if (bagFull()) { state = "idle"; emit("state", "idle"); return; }
    state = "wait"; emit("state", "wait");
    let w = (3.5 + Math.random() * 3.5) * Math.max(0.4, 1 - (G.rodLevel - 1) * 0.06);
    w *= D.SPOTS[G.currentSpot].wait_mult;
    w *= phase().wait;
    if (event) w *= event.wait;
    stateT = w;
  }
  function beginBite() {
    state = "bite"; emit("state", "bite");
    stateT = 1.0;
  }
  function reel() {
    if (state !== "bite") return;
    const luck = D.SPOTS[G.currentSpot].luck_bonus + (event ? event.luck : 0);
    const n = 1 + (Math.random() < D.HOOKS[G.hookLevel].double ? 1 : 0);
    const caught = [];
    for (let i = 0; i < n; i++) {
      if (bagFull()) break;
      const c = rollOne(luck);
      G.inventory.push(c);
      caught.push(c);
      recordDex(c);
      G.lifetimeCatches++;
    }
    state = "idle"; emit("state", "idle");
    if (caught.length) emit("catch", caught);
    checkAchievements();
    emit("update");
    save();
    // continue idle loop
    if (G.autoCast) setTimeout(() => { if (state === "idle") beginWait(); }, 650);
  }
  function rollOne(luck) {
    const c = D.rollCatch(G.rodLevel, G.baitLevel, luck, spotPool());
    const vm = valueMult();
    if (vm !== 1) c.v = Math.max(1, Math.round(c.v * vm));
    c.tier = D.tierOf(c.id);
    c.art = D.artFor(c.id);
    c.tierColor = D.TIER_COLORS[c.tier];
    c.varColor = D.VARIANT_COLORS[c.var];
    c.name = D.fullName(c);
    c.uid = Math.random().toString(36).slice(2);
    if (c.v > G.bestValue) G.bestValue = c.v;
    if (!G.biggest || c.w > G.biggest.w) G.biggest = { id: c.id, w: c.w, name: D.displayName(c.id) };
    return c;
  }
  function recordDex(c) {
    if (!G.dex[c.id]) G.dex[c.id] = { count: 0, variants: [false, false, false, false], bestQ: 0, bestW: 0, bestV: 0 };
    const d = G.dex[c.id];
    d.count++; d.variants[c.var] = true;
    d.bestQ = Math.max(d.bestQ, c.q); d.bestW = Math.max(d.bestW, c.w); d.bestV = Math.max(d.bestV, c.v);
  }

  // manual: start fishing if idle
  function cast() {
    if (state === "idle") { if (bagFull()) { toast("鱼篓满了，先去鱼篓兑换吧", "#FFC773"); return; } beginWait(); }
    else if (state === "bite") reel();
  }

  // ---- selling ----
  function sellOne(uid) {
    const i = G.inventory.findIndex(c => c.uid === uid);
    if (i < 0) return;
    const c = G.inventory[i];
    if (c.lock) { toast("这条被你珍藏了", "#C7BDA8"); return; }
    G.inventory.splice(i, 1);
    G.coins += c.v; G.lifetimeCoins += c.v;
    toast(`卖出「${c.name}」 +${c.v}`, "#FAD166");
    checkAchievements(); emit("update"); save();
  }
  function sellAll(keepLocked) {
    let total = 0, n = 0;
    G.inventory = G.inventory.filter(c => {
      if (c.lock) return true;
      total += c.v; n++; return false;
    });
    if (!n) { toast("没有可兑换的鱼", "#C7BDA8"); return; }
    G.coins += total; G.lifetimeCoins += total;
    toast(`满篓兑换 ${n} 条 +${total}`, "#FAD166");
    checkAchievements(); emit("update"); save();
    if (G.autoCast && state === "idle") beginWait();
  }
  function toggleLock(uid) {
    const c = G.inventory.find(x => x.uid === uid); if (!c) return;
    c.lock = !c.lock; emit("update"); save();
  }

  // ---- upgrades ----
  function upgradeRod() {
    const cost = rodCost();
    if (G.coins < cost) { toast("金币不够", "#FF8C7A"); return; }
    G.coins -= cost; G.rodLevel++; toast(`鱼竿升到 Lv.${G.rodLevel}！`, "#8CD9F2");
    checkAchievements(); emit("update"); save();
  }
  function upgradeBag() {
    const cost = bagCost();
    if (cost == null) { toast("鱼篓已满级", "#C7BDA8"); return; }
    if (G.coins < cost) { toast("金币不够", "#FF8C7A"); return; }
    G.coins -= cost; G.bagLevel++; toast(`鱼篓扩到 ${bagCap()} 格！`, "#8CD9F2");
    checkAchievements(); emit("update"); save();
  }
  function buyBait(idx) {
    if (idx <= G.baitLevel) { setBait(idx); return; }
    const cost = D.BAITS[idx].cost;
    if (G.coins < cost) { toast("金币不够", "#FF8C7A"); return; }
    G.coins -= cost; G.baitLevel = idx; toast(`换上「${D.BAITS[idx].name}」`, "#8CD9F2");
    checkAchievements(); emit("update"); save();
  }
  function setBait(idx) { if (idx <= G.baitLevel) { G.baitLevel = idx; emit("update"); save(); } }
  function buyHook(idx) {
    if (idx <= G.hookLevel) { G.hookLevel = idx; emit("update"); save(); return; }
    const cost = D.HOOKS[idx].cost;
    if (G.coins < cost) { toast("金币不够", "#FF8C7A"); return; }
    G.coins -= cost; G.hookLevel = idx; toast(`换上「${D.HOOKS[idx].name}」`, "#8CD9F2");
    checkAchievements(); emit("update"); save();
  }

  // ---- spots ----
  function spotUnlocked(id) {
    const s = D.SPOTS[id]; if (!s.unlock) return true;
    if (s.unlock.kind === "catches") return G.lifetimeCatches >= s.unlock.n;
    if (s.unlock.kind === "coins") return G.lifetimeCoins >= s.unlock.n;
    if (s.unlock.kind === "species") return speciesCount() >= s.unlock.n;
    return false;
  }
  function unlockText(id) {
    const s = D.SPOTS[id]; if (!s.unlock) return "";
    const k = s.unlock;
    if (k.kind === "catches") return `累计钓到 ${k.n} 条鱼解锁（当前 ${G.lifetimeCatches}）`;
    if (k.kind === "coins") return `累计赚 ${k.n} 金币解锁`;
    if (k.kind === "species") return `图鉴收集 ${k.n} 种解锁`;
    return "";
  }
  function switchSpot(id) {
    if (!spotUnlocked(id)) { toast(unlockText(id), "#FFC773"); return false; }
    G.currentSpot = id; state = "idle";
    if (!G.unlockedSpots.includes(id)) G.unlockedSpots.push(id);
    emit("update"); save();
    if (G.autoCast) beginWait();
    return true;
  }

  // ---- daily order ----
  function todayKey() { const d = new Date(); return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`; }
  function ensureOrder() {
    const today = todayKey();
    if (G.dailyOrder && G.dailyOrder.date === today && D.FISH[G.dailyOrder.fish]) return;
    G.dailyOrder = makeOrder(today);
    save();
  }
  function makeOrder(date) {
    const maxTier = Math.max(1, Math.min(3, 1 + Math.floor((G.rodLevel - 1) / 3)));
    let ids = [];
    for (const sid of G.unlockedSpots) for (const f of D.poolFor(sid)) if (!ids.includes(f)) ids.push(f);
    const cands = ids.filter(id => D.tierOf(id) <= maxTier);
    const pool = cands.length ? cands : ids;
    const kinds = ["species", "species", "species", "tier", "weight"];
    if (G.baitLevel >= 2) kinds.push("perfect");
    const kind = kinds[Math.floor(Math.random() * kinds.length)];
    const fish = pool[Math.floor(Math.random() * pool.length)];
    const o = { date, kind, fish, done: false, need: 1, tier: 1, minw: 1.0 };
    if (kind === "tier") { o.tier = 1 + Math.floor(Math.random() * maxTier); o.need = Math.max(1, Math.min(3, 4 - o.tier)); }
    else if (kind === "weight") { o.minw = [1, 2, 3][Math.floor(Math.random() * 3)]; o.need = 1 + Math.floor(Math.random() * 2); }
    else if (kind === "perfect") { o.need = 1; }
    else { const t = D.tierOf(fish); o.need = t === 0 ? 3 + Math.floor(Math.random() * 3) : t === 1 ? 2 + Math.floor(Math.random() * 2) : t === 2 ? 1 + Math.floor(Math.random() * 2) : 1; }
    return o;
  }
  function orderMatches(c) {
    const o = G.dailyOrder; if (!o) return false;
    if (o.kind === "tier") return D.tierOf(c.id) >= o.tier;
    if (o.kind === "weight") return c.w >= o.minw;
    if (o.kind === "perfect") return c.q >= 3;
    return c.id === o.fish;
  }
  function orderTitle() {
    const o = G.dailyOrder; if (!o) return "";
    if (o.kind === "tier") return `收 ${o.need} 条 ${D.TIER_NAMES[o.tier]}及以上`;
    if (o.kind === "weight") return `收 ${o.need} 条 ≥${o.minw.toFixed(1)}kg 的鱼`;
    if (o.kind === "perfect") return `收 ${o.need} 条 完美★★★ 渔获`;
    return `收 ${o.need} 条 ${D.displayName(o.fish)}`;
  }
  function orderMatchIndices() {
    return G.inventory.map((c, i) => ({ c, i })).filter(x => orderMatches(x.c) && !x.c.lock)
      .sort((a, b) => b.c.v - a.c.v).map(x => x.i);
  }
  function orderReward(idxs) {
    const o = G.dailyOrder; let total = 0;
    for (let k = 0; k < Math.min(o.need, idxs.length); k++) total += G.inventory[idxs[k]].v;
    let mult = DAILY_ORDER_MULT; if (merchant.active) mult *= MERCHANT_MULT;
    return Math.ceil(total * mult);
  }
  function completeOrder() {
    ensureOrder(); const o = G.dailyOrder;
    if (o.done) { toast("今日订单已完成", "#C7BDA8"); return; }
    const idxs = orderMatchIndices();
    if (idxs.length < o.need) { toast("目标鱼还不够", "#FF8C7A"); return; }
    const reward = orderReward(idxs);
    const chosen = idxs.slice(0, o.need).sort((a, b) => b - a);
    for (const i of chosen) G.inventory.splice(i, 1);
    G.coins += reward; G.lifetimeCoins += reward; o.done = true;
    toast(`订单完成：+${reward} 金币${merchant.active ? "（鱼贩×1.5）" : ""}`, "#FAD166");
    checkAchievements(); emit("update"); save();
  }

  // ---- achievements ----
  const ACH = [
    { id: "first", name: "第一竿", desc: "钓到第一条鱼", test: () => G.lifetimeCatches >= 1 },
    { id: "c50", name: "小有渔获", desc: "累计钓到 50 条", test: () => G.lifetimeCatches >= 50 },
    { id: "c300", name: "钓界常客", desc: "累计钓到 300 条", test: () => G.lifetimeCatches >= 300 },
    { id: "rich", name: "万贯家财", desc: "累计赚 10000 金币", test: () => G.lifetimeCoins >= 10000 },
    { id: "rod5", name: "趁手好竿", desc: "鱼竿升到 Lv.5", test: () => G.rodLevel >= 5 },
    { id: "dex20", name: "见多识广", desc: "图鉴收集 20 种", test: () => speciesCount() >= 20 },
    { id: "dex50", name: "鱼谱过半", desc: "图鉴收集 50 种", test: () => speciesCount() >= 50 },
    { id: "epic", name: "史诗时刻", desc: "钓到史诗及以上的鱼", test: () => Object.keys(G.dex).some(id => D.tierOf(id) >= 3) },
    { id: "mythic", name: "国宝现身", desc: "钓到神话级的鱼", test: () => Object.keys(G.dex).some(id => D.tierOf(id) >= 5) },
    { id: "gild", name: "鎏金一瞬", desc: "钓到鎏金或七彩变体", test: () => variantCount() > 0 && Object.values(G.dex).some(d => d.variants[2] || d.variants[3]) },
    { id: "perfect", name: "完美主义", desc: "钓到完美★★★ 渔获", test: () => Object.values(G.dex).some(d => d.bestQ >= 3) },
    { id: "allspots", name: "走遍水岸", desc: "解锁全部钓点", test: () => D.SPOT_ORDER.every(spotUnlocked) },
  ];
  function checkAchievements() {
    for (const a of ACH) {
      if (!G.achievements[a.id] && a.test()) {
        G.achievements[a.id] = true;
        toast(`🏅 成就达成：${a.name}`, "#FAD166");
        emit("event");
      }
    }
  }

  // ---- tick (driven by setInterval — survives background throttling) ----
  let last = performance.now();
  function tick() {
    const now = performance.now();
    const dt = Math.min(0.25, (now - last) / 1000); last = now;
    dayT = (dayT + dt) % DAY_LEN;
    // fishing state
    if (state === "wait") { stateT -= dt; if (stateT <= 0) beginBite(); }
    else if (state === "bite") { stateT -= dt; if (stateT <= 0) reel(); }
    // merchant
    merchant.t -= dt;
    if (merchant.t <= 0) {
      merchant.active = !merchant.active;
      merchant.t = merchant.active ? 60 + Math.random() * 30 : 240 + Math.random() * 240;
      if (merchant.active) { toast("🐟 流动鱼贩来了！卖价 ×1.5", "#FAD166"); }
      emit("update");
    }
    // events
    if (event) { eventT -= dt; if (eventT <= 0) { event = null; emit("event"); emit("update"); } }
    else {
      eventT -= dt;
      if (eventT <= 0) {
        const pool = EVENTS.filter(e => e.key !== "tide_in" || G.currentSpot === "coast_pier");
        const e = pool[Math.floor(Math.random() * pool.length)];
        event = e; eventT = e.dur;
        toast("✦ " + e.msg, "#8CD9F2"); emit("event"); emit("update");
      }
    }
  }

  // ---- save / load ----
  function save() {
    if (!G._loaded) return;
    try { localStorage.setItem(SAVE_KEY, JSON.stringify({
      coins: G.coins, rodLevel: G.rodLevel, bagLevel: G.bagLevel, baitLevel: G.baitLevel, hookLevel: G.hookLevel,
      inventory: G.inventory, dex: G.dex, lifetimeCatches: G.lifetimeCatches, lifetimeCoins: G.lifetimeCoins,
      biggest: G.biggest, bestValue: G.bestValue, currentSpot: G.currentSpot, unlockedSpots: G.unlockedSpots,
      dailyOrder: G.dailyOrder, achievements: G.achievements, autoCast: G.autoCast,
    })); } catch (e) {}
  }
  function load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (raw) Object.assign(G, JSON.parse(raw));
    } catch (e) {}
    G._loaded = true;
    // sanity
    if (!G.unlockedSpots.includes("river_bend")) G.unlockedSpots.push("river_bend");
    for (const c of G.inventory) { if (!c.uid) c.uid = Math.random().toString(36).slice(2); if (!c.art) c.art = D.artFor(c.id); if (c.tier == null) c.tier = D.tierOf(c.id); c.tierColor = D.TIER_COLORS[c.tier]; c.varColor = D.VARIANT_COLORS[c.var]; if (!c.name) c.name = D.fullName(c); }
    ensureOrder();
  }
  function reset() {
    localStorage.removeItem(SAVE_KEY);
    location.reload();
  }

  function start() {
    load();
    merchant.t = 120 + Math.random() * 120;
    eventT = 60 + Math.random() * 60;
    last = performance.now();
    setInterval(tick, 1000 / 30);
    if (G.autoCast) beginWait();
    emit("update");
  }

  return {
    G, on, start, cast, reel, sellOne, sellAll, toggleLock,
    upgradeRod, upgradeBag, buyBait, setBait, buyHook,
    switchSpot, spotUnlocked, unlockText, completeOrder, reset,
    // getters
    bagCap, bagFull, bagCost, rodCost, spotPool, speciesCount, variantCount,
    orderTitle, orderMatches, orderMatchIndices, orderReward,
    phase, getEvent: () => event, getMerchant: () => merchant, getState: () => state,
    ACH,
    get autoCast() { return G.autoCast; }, set autoCast(v) { G.autoCast = v; save(); if (v && state === "idle") beginWait(); },
  };
})();
