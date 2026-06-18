// 角落垂钓 — UI layer: asset loading, HUD, panels, catch popup, toasts.
(function () {
  const D = window.GAMEDATA, Sc = window.Scene, Gm = window.Game, G = Gm.G;
  const $ = (id) => document.getElementById(id);

  // ---------- asset manifest ----------
  const ASSET = {}; // key -> Image
  const BASE = "../assets/";
  function manifest() {
    const m = {};
    // scenes keyed by spot id
    m["river_bend"] = "scenes/spot_river_bend.png";
    m["still_lake"] = "scenes/spot_still_lake.png";
    m["coast_pier"] = "scenes/spot_coast_pier.png";
    m["water_highlight_overlay"] = "scenes/water_highlight_overlay.png";
    // character + props
    for (const k of ["fisher_idle", "fisher_pull_01", "fisher_pull_02"]) m[k] = "character/" + k + ".png";
    for (const k of ["bobber_idle", "bobber_bite"]) m[k] = "props/" + k + ".png";
    // ui icons
    for (const k of ["icon_coin", "icon_capacity", "icon_dex", "icon_weight", "icon_sell"]) m[k] = "ui/" + k + ".png";
    for (const k of ["fish_basket"]) m[k] = "equipment/" + k + ".png";
    for (const k of ["event_fish_run", "event_crate", "event_tide", "event_fog", "event_release"]) m[k] = "ui/" + k + ".png";
    // fish: generics + every dedicated art
    for (let t = 0; t <= 5; t++) m["generic_tier" + t] = "fish/generic_tier" + t + ".png";
    for (const id in D.FISH) if (D.HAS_ART[id]) m[id] = "fish/" + id + ".png";
    return m;
  }
  function loadAll(cb) {
    const m = manifest(); const keys = Object.keys(m); let done = 0;
    if (!keys.length) return cb();
    for (const k of keys) {
      const img = new Image();
      img.onload = img.onerror = () => { if (++done === keys.length) cb(); };
      img.src = BASE + m[k];
      ASSET[k] = img;
    }
  }
  const A = (k) => ASSET[k];

  // ---------- formatting ----------
  function coinStr(n) { return n >= 10000 ? (n / 1000).toFixed(n >= 100000 ? 0 : 1) + "k" : n.toLocaleString(); }
  function wStr(w) { return w >= 1 ? w.toFixed(2) + "kg" : Math.round(w * 1000) + "g"; }
  function tierColor(t) { return D.TIER_COLORS[t]; }
  function tierName(t) { return D.TIER_NAMES[t]; }

  // ---------- HUD ----------
  function renderHud() {
    const cap = Gm.bagCap(), n = G.inventory.length;
    $("hud").innerHTML =
      `<div class="chip coin"><img src="${BASE}ui/icon_coin.png" alt="">${coinStr(G.coins)}</div>` +
      `<div class="chip ${n >= cap ? "warn" : ""}"><img src="${BASE}equipment/fish_basket.png" alt="">${n}/${cap}</div>` +
      `<div class="chip"><img src="${BASE}ui/icon_dex.png" alt="">${Gm.speciesCount()}/${Object.keys(D.FISH).length}</div>`;
  }
  function renderTopRight() {
    const ph = Gm.phase(); const ev = Gm.getEvent(); const mc = Gm.getMerchant();
    let html = `<div class="spot-name">${D.SPOTS[G.currentSpot].name}</div>`;
    html += `<div class="phase">${ph.name}</div>`;
    if (ev) html += `<div class="flag event"><img src="${BASE}ui/${ev.icon}.png" onerror="this.style.display='none'" alt="">${ev.name}</div>`;
    if (mc.active) html += `<div class="flag merchant">🐟 鱼贩 ×1.5</div>`;
    $("topright").innerHTML = html;
    // sky tint by phase
    $("skyTint").style.background = ph.sky;
  }

  // ---------- action button ----------
  function renderAction(st) {
    const b = $("action"); b.className = "action";
    if (Gm.bagFull() && st !== "bite") { b.textContent = "鱼篓满了 · 去兑换"; b.classList.add("full"); return; }
    if (st === "bite") { b.textContent = "起钩！"; b.classList.add("bite"); }
    else if (st === "wait") { b.textContent = "· 等待咬钩 ·"; b.classList.add("wait"); }
    else { b.textContent = G.autoCast ? "自动垂钓中" : "起竿"; if (G.autoCast) b.classList.add("wait"); }
  }

  // ---------- catch popup ----------
  let popTimer = null;
  function showCatch(list) {
    const c = list[list.length - 1];
    Sc.playCatch(c, () => {});
    const pop = $("catchPop");
    const extra = list.length > 1 ? `<div class="catch-meta">双钩！同时上 ${list.length} 条</div>` : "";
    const metaBits = [];
    if (c.q > 0) metaBits.push(D.QUALITY_NAMES[c.q] + "★".repeat(c.q));
    if (c.var > 0) metaBits.push(`<span style="color:${c.varColor}">${D.VARIANT_NAMES[c.var]}</span>`);
    metaBits.push(wStr(c.w));
    pop.innerHTML =
      `<div class="catch-card" style="border-color:${c.tierColor}">` +
      `<div class="pill" style="background:${c.tierColor};color:#1a1a1a">${tierName(c.tier)}</div>` +
      `<img src="${BASE}fish/${c.art}.png" alt="">` +
      `<div class="catch-name">${c.name}</div>` +
      `<div class="catch-meta">${metaBits.join(" · ")}</div>` +
      `<div class="catch-val">+${c.v} 金币</div>${extra}</div>`;
    pop.classList.add("show");
    clearTimeout(popTimer);
    popTimer = setTimeout(() => pop.classList.remove("show"), 1700);
  }

  // ---------- toasts ----------
  function showToast(msg, color) {
    const t = document.createElement("div");
    t.className = "toast"; t.style.color = color; t.textContent = msg;
    $("toasts").appendChild(t);
    setTimeout(() => { t.style.opacity = "0"; t.style.transition = "opacity .4s"; setTimeout(() => t.remove(), 400); }, 2200);
    while ($("toasts").children.length > 3) $("toasts").firstChild.remove();
  }

  // ---------- nav ----------
  // Quiet hairline glyphs (currentColor) — painterly world deserves no emoji.
  const SVG = {
    basket: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8q4-4.6 8 0"/><path d="M4.2 8h11.6l-1.5 8H5.7z"/><path d="M8.2 8l-.6 8M11.8 8l.6 8"/></svg>`,
    equip: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M5 15.6L14.6 5"/><circle cx="6.4" cy="13.9" r="1.15"/><path d="M14.6 5l.4 4.1"/><path d="M15 9.1q1.5.5.2 2"/></svg>`,
    dex: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M10 6v9.4"/><path d="M10 6C8.3 4.9 5.9 4.9 4.1 5.7V15c1.8-.8 4.2-.8 5.9.4"/><path d="M10 6c1.7-1.1 4.1-1.1 5.9-.3V15c-1.8-.8-4.2-.8-5.9.4"/></svg>`,
    orders: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><rect x="4.8" y="4.4" width="10.4" height="11.4" rx="2"/><path d="M7.6 8.4h4.8"/><path d="M7.6 11.6l1.4 1.4 3-3.2"/></svg>`,
    spots: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M10 16.5s4.8-4.7 4.8-8.4a4.8 4.8 0 1 0-9.6 0c0 3.7 4.8 8.4 4.8 8.4z"/><circle cx="10" cy="8.1" r="1.7"/></svg>`,
  };
  const NAV = [
    { id: "basket", label: "鱼篓" },
    { id: "equip", label: "装备" },
    { id: "dex", label: "图鉴" },
    { id: "orders", label: "任务" },
    { id: "spots", label: "钓点" },
  ];
  function renderNav() {
    const orderReady = (() => { const o = G.dailyOrder; return o && !o.done && Gm.orderMatchIndices().length >= o.need; })();
    $("nav").innerHTML = NAV.map(n => {
      let badge = "";
      if (n.id === "basket" && Gm.bagFull()) badge = `<span class="badge">满</span>`;
      if (n.id === "orders" && orderReady) badge = `<span class="badge">!</span>`;
      const active = curPanel === n.id ? " active" : "";
      return `<button class="navbtn${active}" data-panel="${n.id}"><span class="ico">${SVG[n.id]}</span><span class="lbl">${n.label}</span>${badge}</button>`;
    }).join("");
    $("nav").querySelectorAll("button").forEach(b => b.onclick = () => openPanel(b.dataset.panel));
  }

  // ---------- sheet / panels ----------
  let curPanel = null;
  function openPanel(id) {
    curPanel = id;
    $("sheet").classList.add("open");
    renderPanel();
    renderNav();
  }
  function closePanel() { curPanel = null; $("sheet").classList.remove("open"); renderNav(); }
  function renderPanel() {
    if (!curPanel) return;
    const map = { basket: renderBasket, equip: renderEquip, dex: renderDex, orders: renderOrders, spots: renderSpots };
    (map[curPanel] || (() => {}))();
  }

  // --- basket ---
  let basketSort = "new"; // new | value | tier
  function renderBasket() {
    $("sheetTitle").textContent = "鱼篓";
    $("sheetSub").textContent = `${G.inventory.length}/${Gm.bagCap()}`;
    const body = $("sheetBody");
    let inv = G.inventory.map((c, i) => ({ c, i }));
    if (basketSort === "value") inv.sort((a, b) => b.c.v - a.c.v);
    else if (basketSort === "tier") inv.sort((a, b) => b.c.tier - a.c.tier || b.c.v - a.c.v);
    else inv.reverse();
    const sellableTotal = G.inventory.filter(c => !c.lock).reduce((s, c) => s + c.v, 0);
    let html = `<div class="seg">
      ${["new", "value", "tier"].map(s => `<div class="tab ${basketSort === s ? "on" : ""}" data-sort="${s}">${{ new: "最新", value: "价值", tier: "品阶" }[s]}</div>`).join("")}
      <div style="flex:1"></div>
      <button class="btn" id="sellAll" ${sellableTotal ? "" : "disabled"}>全部兑换 +${coinStr(sellableTotal)}</button>
    </div>`;
    if (!G.inventory.length) html += `<div class="empty">鱼篓还是空的，<br>等浮漂动一动吧。</div>`;
    else {
      html += `<div class="bgrid">` + inv.map(({ c, i }) =>
        `<div class="fishcell" data-uid="${c.uid}" style="border-color:${c.var > 0 ? c.varColor : c.tierColor}">
          ${c.lock ? '<span class="lock">🔒</span>' : ''}
          <img src="${BASE}fish/${c.art}.png" alt="">
          <div class="fn" style="color:${c.var > 0 ? c.varColor : 'var(--text-on-glass)'}">${c.name}</div>
          <div class="fv">${coinStr(c.v)}</div>
        </div>`).join("") + `</div>`;
    }
    body.innerHTML = html;
    body.querySelectorAll(".tab").forEach(t => t.onclick = () => { basketSort = t.dataset.sort; renderBasket(); });
    const sa = $("sellAll"); if (sa) sa.onclick = () => Gm.sellAll();
    body.querySelectorAll(".fishcell").forEach(el => el.onclick = () => openFishMenu(el.dataset.uid));
  }
  function openFishMenu(uid) {
    const c = G.inventory.find(x => x.uid === uid); if (!c) return;
    // quick action: lock toggle on shift, else sell with confirm-less (it's a game)
    const action = window.confirm(`「${c.name}」 ${wStr(c.w)} · 价值 ${c.v}\n\n确定 = 兑换为金币\n取消 = ${c.lock ? "取消珍藏" : "珍藏（不被全部兑换）"}`);
    if (action) Gm.sellOne(uid); else Gm.toggleLock(uid);
  }

  // --- equip ---
  function renderEquip() {
    $("sheetTitle").textContent = "装备";
    $("sheetSub").textContent = "金币永久升级";
    const body = $("sheetBody");
    let html = "";
    // rod
    const rc = Gm.rodCost();
    html += `<div class="row">
      <img class="thumb" src="${BASE}equipment/rod_carbon.png" alt="">
      <div class="grow"><div class="nm">鱼竿 Lv.${G.rodLevel}</div>
      <div class="sub">决定稀有度 · 越高级越易上高阶鱼，咬钩更快</div></div>
      <button class="btn" data-act="rod" ${G.coins < rc ? "disabled" : ""}>升级<br>${coinStr(rc)}</button>
    </div>`;
    // bag
    const bc = Gm.bagCost();
    html += `<div class="row">
      <img class="thumb" src="${BASE}equipment/fish_basket.png" alt="">
      <div class="grow"><div class="nm">鱼篓 ${Gm.bagCap()} 格</div>
      <div class="sub">能装下的鱼越多，离开越久也不浪费</div></div>
      ${bc == null ? '<span class="pill" style="background:var(--glass-row);color:var(--text-muted-glass)">已满级</span>'
        : `<button class="btn" data-act="bag" ${G.coins < bc ? "disabled" : ""}>扩容<br>${coinStr(bc)}</button>`}
    </div>`;
    // bait
    html += `<div style="font-size:12px;color:var(--text-muted-glass);margin:14px 0 7px;font-weight:600">鱼饵 · 决定星级品质（卖价倍率）</div>`;
    D.BAITS.forEach((b, i) => {
      const owned = i <= G.baitLevel, eq = i === G.baitLevel;
      html += `<div class="row" style="${eq ? 'border-color:var(--gold)' : ''}">
        <img class="thumb" src="${BASE}equipment/bait_jar.png" alt="">
        <div class="grow"><div class="nm">${b.name} ${eq ? '<span class="pill" style="background:var(--gold);color:#2a2a1a">使用中</span>' : ''}</div>
        <div class="sub">${b.desc} · 上品率 ${(b.probs[1] * 100).toFixed(0)}%</div></div>
        ${eq ? '' : owned ? `<button class="btn sec" data-bait="${i}">换上</button>`
          : `<button class="btn" data-bait="${i}" ${G.coins < b.cost ? "disabled" : ""}>${coinStr(b.cost)}</button>`}
      </div>`;
    });
    // hook
    html += `<div style="font-size:12px;color:var(--text-muted-glass);margin:14px 0 7px;font-weight:600">鱼钩 · 决定双钩几率（一次两条）</div>`;
    D.HOOKS.forEach((h, i) => {
      const owned = i <= G.hookLevel, eq = i === G.hookLevel;
      html += `<div class="row" style="${eq ? 'border-color:var(--gold)' : ''}">
        <img class="thumb" src="${BASE}equipment/hook_basic.png" alt="">
        <div class="grow"><div class="nm">${h.name} ${eq ? '<span class="pill" style="background:var(--gold);color:#2a2a1a">使用中</span>' : ''}</div>
        <div class="sub">${h.desc} · 双钩 ${(h.double * 100).toFixed(0)}%</div></div>
        ${eq ? '' : owned ? `<button class="btn sec" data-hook="${i}">换上</button>`
          : `<button class="btn" data-hook="${i}" ${G.coins < h.cost ? "disabled" : ""}>${coinStr(h.cost)}</button>`}
      </div>`;
    });
    body.innerHTML = html;
    body.querySelectorAll("[data-act=rod]").forEach(b => b.onclick = () => Gm.upgradeRod());
    body.querySelectorAll("[data-act=bag]").forEach(b => b.onclick = () => Gm.upgradeBag());
    body.querySelectorAll("[data-bait]").forEach(b => b.onclick = () => Gm.buyBait(+b.dataset.bait));
    body.querySelectorAll("[data-hook]").forEach(b => b.onclick = () => Gm.buyHook(+b.dataset.hook));
  }

  // --- dex ---
  let dexTier = -1;
  function renderDex() {
    $("sheetTitle").textContent = "图鉴";
    $("sheetSub").textContent = `${Gm.speciesCount()}/${Object.keys(D.FISH).length} 种 · ${Gm.variantCount()} 变体`;
    const body = $("sheetBody");
    let ids = Object.keys(D.FISH).sort((a, b) => D.tierOf(a) - D.tierOf(b) || (a < b ? -1 : 1));
    if (dexTier >= 0) ids = ids.filter(id => D.tierOf(id) === dexTier);
    let html = `<div class="seg">
      <div class="tab ${dexTier === -1 ? "on" : ""}" data-t="-1">全部</div>
      ${[0, 1, 2, 3, 4, 5].map(t => `<div class="tab ${dexTier === t ? "on" : ""}" data-t="${t}" style="${dexTier === t ? `background:${tierColor(t)};color:#1a1a1a` : ''}">${tierName(t)}</div>`).join("")}
    </div><div class="dexgrid">`;
    for (const id of ids) {
      const d = G.dex[id], seen = !!d;
      const t = D.tierOf(id);
      const vdots = seen ? d.variants.map((v, vi) => `<span class="vdot" style="${v ? `background:${D.VARIANT_COLORS[vi] === '#ffffff' ? tierColor(t) : D.VARIANT_COLORS[vi]}` : ''}"></span>`).join("") : "";
      html += `<div class="dexcell ${seen ? "" : "locked"}" style="border-color:${seen ? tierColor(t) : 'var(--glass-row-border)'}" title="${seen ? D.displayName(id) : '未发现'}">
        <img src="${BASE}fish/${D.artFor(id)}.png" alt="">
        <div class="dn">${seen ? D.displayName(id) : "？？？"}</div>
        <div class="vdots">${vdots}</div>
      </div>`;
    }
    html += `</div>`;
    body.innerHTML = html;
    body.querySelectorAll(".tab").forEach(t => t.onclick = () => { dexTier = +t.dataset.t; renderDex(); });
  }

  // --- orders + achievements + stats ---
  function renderOrders() {
    $("sheetTitle").textContent = "任务";
    $("sheetSub").textContent = "";
    const body = $("sheetBody");
    const o = G.dailyOrder;
    const idxs = Gm.orderMatchIndices();
    const ready = o && !o.done && idxs.length >= o.need;
    const reward = o ? Gm.orderReward(idxs) : 0;
    let html = `<div style="font-size:12px;color:var(--text-muted-glass);margin-bottom:7px;font-weight:600">每日订单 · 原价 ×2.5</div>`;
    if (o) {
      html += `<div class="row" style="${ready ? 'border-color:var(--gold)' : ''}">
        <img class="thumb" src="${BASE}fish/${D.artFor(o.fish)}.png" alt="">
        <div class="grow"><div class="nm">${Gm.orderTitle()}</div>
        <div class="sub">进度 ${Math.min(idxs.length, o.need)}/${o.need}${o.done ? " · 已完成" : ready ? ` · 可交付 +${coinStr(reward)}` : ""}</div></div>
        ${o.done ? '<span class="pill" style="background:var(--positive);color:#0e1a0e">完成</span>'
          : `<button class="btn" id="doOrder" ${ready ? "" : "disabled"}>交付</button>`}
      </div>`;
    }
    // stats
    html += `<div style="font-size:12px;color:var(--text-muted-glass);margin:16px 0 8px;font-weight:600">统计</div>`;
    html += `<div class="stat-grid">
      <div class="stat"><div class="v">${coinStr(G.lifetimeCatches)}</div><div class="k">累计渔获</div></div>
      <div class="stat"><div class="v">${coinStr(G.lifetimeCoins)}</div><div class="k">累计收入</div></div>
      <div class="stat"><div class="v">${G.biggest ? wStr(G.biggest.w) : "—"}</div><div class="k">最大个体 ${G.biggest ? "· " + G.biggest.name : ""}</div></div>
      <div class="stat"><div class="v">${coinStr(G.bestValue)}</div><div class="k">最值钱的一条</div></div>
    </div>`;
    // achievements
    const got = Gm.ACH.filter(a => G.achievements[a.id]).length;
    html += `<div style="font-size:12px;color:var(--text-muted-glass);margin:6px 0 8px;font-weight:600">成就 ${got}/${Gm.ACH.length}</div>`;
    for (const a of Gm.ACH) {
      const has = !!G.achievements[a.id];
      html += `<div class="ach ${has ? "got" : ""}">
        <div class="medal">🏅</div>
        <div class="grow"><div class="nm" style="${has ? '' : 'color:var(--text-faint-glass)'}">${a.name}</div>
        <div class="sub">${a.desc}</div></div>
        ${has ? '<span class="pill" style="background:var(--gold);color:#2a2a1a">达成</span>' : ''}
      </div>`;
    }
    html += `<div style="text-align:center;margin-top:18px"><button class="btn sec" id="resetBtn">重置存档</button></div>`;
    body.innerHTML = html;
    const dO = $("doOrder"); if (dO) dO.onclick = () => Gm.completeOrder();
    $("resetBtn").onclick = () => { if (confirm("确定清空所有进度，从头开始？")) Gm.reset(); };
  }

  // --- spots ---
  function renderSpots() {
    $("sheetTitle").textContent = "钓点";
    $("sheetSub").textContent = "";
    const body = $("sheetBody");
    let html = "";
    for (const id of D.SPOT_ORDER) {
      const s = D.SPOTS[id]; const unlocked = Gm.spotUnlocked(id); const active = id === G.currentSpot;
      html += `<div class="spotcard ${active ? "active" : ""} ${unlocked ? "" : "locked"}" data-spot="${id}">
        <img class="sc-img" src="${BASE}scenes/${s.bg}.png" alt="">
        ${unlocked ? "" : `<div class="lockbadge">🔒 ${Gm.unlockText(id)}</div>`}
        <div class="sc-body">
          <div class="sc-name">${s.name} ${active ? '<span class="pill" style="background:var(--gold);color:#2a2a1a">当前</span>' : ''}</div>
          <div class="sc-desc">${s.desc}</div>
        </div>
      </div>`;
    }
    body.innerHTML = html;
    body.querySelectorAll(".spotcard").forEach(el => el.onclick = () => {
      const id = el.dataset.spot;
      if (Gm.switchSpot(id)) { Sc.setSpot(id, D.SPOTS[id].bite); closePanel(); }
    });
  }

  // ---------- wire up ----------
  function refreshAll() {
    renderHud(); renderTopRight(); renderNav(); renderAction(Gm.getState());
    if (curPanel) renderPanel();
  }

  function boot() {
    Sc.init($("scene"), ASSET);
    Sc.setSpot(G.currentSpot, D.SPOTS[G.currentSpot].bite);

    Gm.on("update", refreshAll);
    Gm.on("event", () => { renderTopRight(); renderNav(); });
    Gm.on("toast", showToast);
    Gm.on("catch", showCatch);
    Gm.on("state", (st) => { Sc.setState(st === "wait" ? "wait" : st === "bite" ? "bite" : "wait"); renderAction(st); });

    $("action").onclick = () => Gm.cast();
    $("sheetClose").onclick = closePanel;
    $("autoToggle").onclick = () => { Gm.autoCast = !Gm.autoCast; $("autoSwitch").classList.toggle("on", Gm.autoCast); renderAction(Gm.getState()); };
    document.addEventListener("keydown", (e) => { if (e.code === "Space") { e.preventDefault(); Gm.cast(); } if (e.code === "Escape") closePanel(); });

    $("autoSwitch").classList.toggle("on", G.autoCast);
    $("loading").style.display = "none";

    Gm.start();
    refreshAll();
    // periodic light refresh for phase/timers
    setInterval(() => { renderTopRight(); }, 1500);
  }

  loadAll(boot);
})();
