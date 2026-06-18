/* @ds-bundle: {"format":3,"namespace":"CornerFishingDesignSystem_301be0","components":[{"name":"DexCard","sourcePath":"components/game/DexCard.jsx"},{"name":"FishIcon","sourcePath":"components/game/FishIcon.jsx"},{"name":"FishRow","sourcePath":"components/game/FishRow.jsx"},{"name":"HudChip","sourcePath":"components/game/HudChip.jsx"},{"name":"HudLedger","sourcePath":"components/game/HudLedger.jsx"},{"name":"SpotCard","sourcePath":"components/game/SpotCard.jsx"},{"name":"SummaryStrip","sourcePath":"components/game/SummaryStrip.jsx"},{"name":"Badge","sourcePath":"components/primitives/Badge.jsx"},{"name":"Button","sourcePath":"components/primitives/Button.jsx"},{"name":"ProgressBar","sourcePath":"components/primitives/ProgressBar.jsx"},{"name":"RoundButton","sourcePath":"components/primitives/RoundButton.jsx"},{"name":"Slider","sourcePath":"components/primitives/Slider.jsx"},{"name":"Toggle","sourcePath":"components/primitives/Toggle.jsx"},{"name":"Card","sourcePath":"components/surfaces/Card.jsx"},{"name":"Panel","sourcePath":"components/surfaces/Panel.jsx"},{"name":"TabBar","sourcePath":"components/surfaces/TabBar.jsx"}],"sourceHashes":{"components/game/DexCard.jsx":"fc326da6e0ff","components/game/FishIcon.jsx":"0c0c2640b7a4","components/game/FishRow.jsx":"e4cad958479f","components/game/HudChip.jsx":"40ae69c1860f","components/game/HudLedger.jsx":"6158c960983d","components/game/SpotCard.jsx":"72bcb5451c8a","components/game/SummaryStrip.jsx":"ab3e818fd3bd","components/primitives/Badge.jsx":"b961811513cd","components/primitives/Button.jsx":"fe1fe4e8dc8e","components/primitives/ProgressBar.jsx":"277ffb614f2a","components/primitives/RoundButton.jsx":"a01cc671dbb6","components/primitives/Slider.jsx":"0dd31ab54977","components/primitives/Toggle.jsx":"d198d709c7f1","components/surfaces/Card.jsx":"47cb6a8c6275","components/surfaces/Panel.jsx":"589a762c0241","components/surfaces/TabBar.jsx":"f4e78681027a","playable/data.js":"c293f9899c01","playable/game.js":"427dfc9047b5","playable/scene.js":"38d17befcffc","playable/ui.js":"3b84f392ed1d","ui_kits/corner_fishing/app.jsx":"f985186f4c5a","ui_kits/corner_fishing/data.js":"dd740cdb4379"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.CornerFishingDesignSystem_301be0 = window.CornerFishingDesignSystem_301be0 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/game/FishIcon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-fishicon{position:relative;display:grid;place-items:center;flex:0 0 auto;
  border-radius:8px;box-sizing:border-box;overflow:hidden;}
.cf-fishicon--frame{background:rgba(0,0,0,0.16);border:1px solid var(--cf-tier,transparent);}
.cf-fishicon img{width:84%;height:84%;object-fit:contain;display:block;
  image-rendering:auto;filter:drop-shadow(0 1px 1px rgba(0,0,0,0.25));}
.cf-fishicon--dimmed img{opacity:0.28;filter:grayscale(1) brightness(0.7);}
.cf-fishicon--v1 img{filter:drop-shadow(0 0 7px rgba(140,217,242,0.85));}
.cf-fishicon--v2 img{animation:cf-variant-shimmer var(--dur-slow) var(--ease-soft) infinite;}
.cf-fishicon--v3 img{filter:drop-shadow(0 0 8px rgba(242,140,242,0.85));}
`;
const TIER_VARS = ["var(--tier-0)", "var(--tier-1)", "var(--tier-2)", "var(--tier-3)", "var(--tier-4)", "var(--tier-5)"];

/**
 * A fish (or equipment) icon. Optional tier frame ring + rare-variant glow.
 * Falls back to a generic tier silhouette via `fallbackSrc`.
 */
function FishIcon({
  src,
  fallbackSrc,
  alt = "",
  size = 34,
  tier = 0,
  variant = 0,
  frame = false,
  dimmed = false,
  className = "",
  style,
  ...rest
}) {
  useCfStyles("cf-fishicon-css", CSS);
  const cls = ["cf-fishicon", frame ? "cf-fishicon--frame" : "", dimmed ? "cf-fishicon--dimmed" : "", variant ? `cf-fishicon--v${variant}` : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("span", _extends({
    className: cls,
    style: {
      width: size,
      height: size,
      "--cf-tier": TIER_VARS[tier] || "transparent",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("img", {
    src: src,
    alt: alt,
    onError: fallbackSrc ? e => {
      if (e.currentTarget.src !== fallbackSrc) e.currentTarget.src = fallbackSrc;
    } : undefined
  }));
}
Object.assign(__ds_scope, { FishIcon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/FishIcon.jsx", error: String((e && e.message) || e) }); }

// components/game/DexCard.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

/* Legibility-first codex cell. Rarity is read from a tier RAIL + frame ring,
   so the NAME can stay high-contrast dark ink on parchment (the old
   tier-coloured + outlined name was the unreadable part). */
const CSS = `
.cf-dex{position:relative;width:100%;min-height:108px;box-sizing:border-box;overflow:hidden;
  display:flex;flex-direction:column;align-items:center;gap:3px;padding:8px 8px 9px;
  border-radius:var(--r-card);font-family:var(--font-sans);text-align:center;}
.cf-dex--known{background:var(--surface-card);border:var(--border-card);}
.cf-dex--known::before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--cf-rail);}
.cf-dex--unknown{background:var(--surface-row);border:var(--border-row);justify-content:center;}
.cf-dex__name{font-size:13px;font-weight:700;line-height:1.15;color:var(--ink);
  max-width:100%;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}
.cf-dex__name--unknown{color:var(--text-faint-glass);font-weight:500;}
.cf-dex__rec{display:flex;align-items:center;justify-content:center;gap:6px;
  font-size:11px;line-height:1.2;color:var(--ink-soft);font-variant-numeric:tabular-nums;}
.cf-dex__rec b{color:var(--ink);font-weight:700;}
.cf-dex__milestone{display:flex;align-items:center;gap:5px;width:100%;justify-content:center;margin-top:1px;}
.cf-dex__bar{flex:1;max-width:64px;height:5px;border-radius:999px;background:rgba(120,110,86,.28);overflow:hidden;}
.cf-dex__bar i{display:block;height:100%;border-radius:999px;background:var(--cf-rail);}
.cf-dex__barnum{font-size:10px;color:var(--ink-soft);font-variant-numeric:tabular-nums;}
.cf-dex__done{font-size:11px;font-weight:700;color:#9A6B12;}
.cf-dex__marks{display:flex;gap:5px;align-items:center;justify-content:center;line-height:1;}
.cf-dex__mark{font-size:11px;font-weight:700;}
.cf-dex__dot{font-size:10px;}
`;
const RAIL_VARS = ["var(--tier-0)", "var(--tier-1)", "var(--tier-2)", "var(--tier-3)", "var(--tier-4)", "var(--tier-5)"];
const VARIANT_VARS = [null, "var(--variant-1)", "var(--variant-2)", "var(--variant-3)"];

/**
 * Codex (图鉴) grid cell — legibility-first. Known = parchment with a tier
 * rail/frame, dark-ink name, record + a /10 collection meter; unknown = dim.
 */
function DexCard({
  src,
  fallbackSrc,
  name,
  tier = 0,
  known = false,
  count = 0,
  maxWeight = 0,
  collected = false,
  giant = false,
  perfect = false,
  variants = [],
  style
}) {
  useCfStyles("cf-dex-css", CSS);
  if (!known) {
    return /*#__PURE__*/React.createElement("div", {
      className: "cf-dex cf-dex--unknown",
      style: style
    }, /*#__PURE__*/React.createElement(__ds_scope.FishIcon, {
      src: src,
      fallbackSrc: fallbackSrc,
      tier: tier,
      size: 42,
      dimmed: true
    }), /*#__PURE__*/React.createElement("span", {
      className: "cf-dex__name cf-dex__name--unknown"
    }, "\u672A\u53D1\u73B0"));
  }
  const pct = Math.max(0, Math.min(100, count / 10 * 100));
  const hasMarks = giant || perfect || variants.length > 0;
  return /*#__PURE__*/React.createElement("div", {
    className: "cf-dex cf-dex--known",
    style: {
      "--cf-rail": RAIL_VARS[tier],
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.FishIcon, {
    src: src,
    fallbackSrc: fallbackSrc,
    tier: tier,
    size: 46
  }), /*#__PURE__*/React.createElement("span", {
    className: "cf-dex__name"
  }, name), /*#__PURE__*/React.createElement("span", {
    className: "cf-dex__rec"
  }, /*#__PURE__*/React.createElement("span", null, "\xD7", /*#__PURE__*/React.createElement("b", null, count)), maxWeight > 0 ? /*#__PURE__*/React.createElement("span", null, "\u6700\u5927 ", maxWeight.toFixed(2), "kg") : null), /*#__PURE__*/React.createElement("div", {
    className: "cf-dex__milestone"
  }, collected ? /*#__PURE__*/React.createElement("span", {
    className: "cf-dex__done"
  }, "\u2726 \u96C6\u9F50") : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", {
    className: "cf-dex__bar"
  }, /*#__PURE__*/React.createElement("i", {
    style: {
      width: `${pct}%`
    }
  })), /*#__PURE__*/React.createElement("span", {
    className: "cf-dex__barnum"
  }, count, "/10"))), hasMarks ? /*#__PURE__*/React.createElement("div", {
    className: "cf-dex__marks"
  }, giant ? /*#__PURE__*/React.createElement("span", {
    className: "cf-dex__mark",
    style: {
      color: "var(--tier-4)"
    }
  }, "\u5DE8") : null, perfect ? /*#__PURE__*/React.createElement("span", {
    className: "cf-dex__mark",
    style: {
      color: "var(--tier-3)"
    }
  }, "\u5B8C\u2605") : null, variants.map(v => /*#__PURE__*/React.createElement("span", {
    key: v,
    className: "cf-dex__dot",
    style: {
      color: VARIANT_VARS[v]
    }
  }, "\u25CF"))) : null);
}
Object.assign(__ds_scope, { DexCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/DexCard.jsx", error: String((e && e.message) || e) }); }

// components/game/FishRow.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-fr{position:relative;display:flex;align-items:center;gap:11px;overflow:hidden;
  background:var(--glass-row);border:1px solid var(--glass-row-border);
  border-radius:11px;padding:8px 12px 8px 8px;font-family:var(--font-sans);min-width:0;
  transition:background-color var(--dur-fast) var(--ease-calm);}
.cf-fr::before{content:"";position:absolute;left:0;top:0;bottom:0;width:3px;background:var(--cf-rail);}
.cf-fr--hi{background:linear-gradient(90deg,var(--cf-railsoft),var(--glass-row) 44%);}
.cf-fr__ic{flex:0 0 auto;}
.cf-fr__main{flex:1 1 auto;min-width:0;display:flex;flex-direction:column;gap:3px;}
.cf-fr__nm{display:flex;align-items:center;gap:5px;font-size:15px;font-weight:600;line-height:1.1;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.cf-fr__gem{font-size:12px;}
.cf-fr__tags{display:flex;align-items:center;gap:6px;min-width:0;}
.cf-fr__pill{font-size:10px;font-weight:600;padding:2px 7px;border-radius:999px;line-height:1.3;
  white-space:nowrap;}
.cf-fr__q{font-size:11px;color:var(--variant-2);white-space:nowrap;}
.cf-fr__wt{font-size:12px;color:#9a9384;font-variant-numeric:tabular-nums;white-space:nowrap;}
.cf-fr__right{display:flex;align-items:center;gap:8px;flex:0 0 auto;}
.cf-fr__fav{width:32px;height:32px;border-radius:8px;border:none;background:transparent;cursor:pointer;
  display:grid;place-items:center;color:var(--text-faint-glass);
  transition:background-color var(--dur-fast),color var(--dur-fast);}
.cf-fr__fav:hover{background:var(--glass-row-hover);color:#f5e8cc;}
.cf-fr__fav--on{color:var(--bag-full);}
.cf-fr__coin{display:inline-flex;align-items:center;gap:5px;width:70px;justify-content:center;
  padding:7px 8px;border-radius:9px;border:none;cursor:pointer;font-family:var(--font-sans);
  background:var(--bronze);color:var(--ink-on-gold);font-weight:700;font-size:14px;
  font-variant-numeric:tabular-nums;transition:background-color var(--dur-fast) var(--ease-calm);}
.cf-fr__coin:hover{background:var(--bronze-hover);}
.cf-fr__coin:active{background:var(--bronze-press);}
.cf-fr__coin img{width:15px;height:15px;object-fit:contain;}
.cf-fr__coin--locked{background:rgba(60,62,55,.7);color:#bfb8a8;cursor:default;}
`;
const TIER_VARS = ["var(--tier-0)", "var(--tier-1)", "var(--tier-2)", "var(--tier-3)", "var(--tier-4)", "var(--tier-5)"];
const VARIANT_VARS = [null, "var(--variant-1)", "var(--variant-2)", "var(--variant-3)"];
const VARIANT_NAMES = ["", "斑斓", "鎏金", "七彩"];
const VARIANT_MULTS = [0, 2, 5, 12];
const VARIANT_SOFT = [null, "rgba(140,217,242,.16)", "rgba(255,214,89,.16)", "rgba(242,140,242,.16)"];
const TIER_SOFT = ["rgba(199,199,204,.10)", "rgba(89,199,77,.12)", "rgba(77,158,242,.13)", "rgba(184,107,242,.15)", "rgba(255,140,31,.16)", "rgba(255,97,82,.16)"];
const LOCK = /*#__PURE__*/React.createElement("svg", {
  viewBox: "0 0 24 24",
  width: "15",
  height: "15",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: "2",
  strokeLinecap: "round",
  strokeLinejoin: "round"
}, /*#__PURE__*/React.createElement("rect", {
  x: "5",
  y: "11",
  width: "14",
  height: "9",
  rx: "2"
}), /*#__PURE__*/React.createElement("path", {
  d: "M8 11V8a4 4 0 0 1 8 0v3"
}));

/**
 * Rich basket entry: tier-framed icon + tier rail · tier-coloured name ·
 * variant/size/quality tags · favourite-lock · coin-pill price.
 * Tier ≥4 or any rare variant auto-emphasises (tinted row).
 */
function FishRow({
  src,
  fallbackSrc,
  name,
  tier = 0,
  variant = 0,
  quality = 0,
  weight,
  sizeTag,
  locked = false,
  value,
  coinIcon,
  emphasis,
  onSell,
  onToggleLock,
  style
}) {
  useCfStyles("cf-fishrow-css", CSS);
  const railVar = variant ? VARIANT_VARS[variant] : TIER_VARS[tier];
  const railSoft = variant ? VARIANT_SOFT[variant] : TIER_SOFT[tier];
  const nameColor = variant ? VARIANT_VARS[variant] : TIER_VARS[tier];
  const hi = emphasis != null ? emphasis : tier >= 4 || variant >= 1;
  return /*#__PURE__*/React.createElement("div", {
    className: `cf-fr${hi ? " cf-fr--hi" : ""}`,
    style: {
      "--cf-rail": railVar,
      "--cf-railsoft": railSoft,
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.FishIcon, {
    className: "cf-fr__ic",
    src: src,
    fallbackSrc: fallbackSrc,
    tier: tier,
    variant: variant,
    size: 46,
    frame: true
  }), /*#__PURE__*/React.createElement("div", {
    className: "cf-fr__main"
  }, /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__nm",
    style: {
      color: nameColor
    }
  }, variant ? /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__gem"
  }, "\u25C6") : null, name), /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__tags"
  }, variant ? /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__pill",
    style: {
      background: railSoft,
      color: VARIANT_VARS[variant]
    }
  }, VARIANT_NAMES[variant], " \xD7", VARIANT_MULTS[variant]) : null, sizeTag ? /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__pill",
    style: {
      background: "rgba(255,140,31,.16)",
      color: "var(--tier-4)"
    }
  }, sizeTag === "大" ? "大物" : sizeTag) : null, quality > 0 ? /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__q"
  }, "★".repeat(quality)) : null, weight != null ? /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__wt"
  }, Number(weight).toFixed(2), "kg") : null)), /*#__PURE__*/React.createElement("div", {
    className: "cf-fr__right"
  }, /*#__PURE__*/React.createElement("button", {
    className: `cf-fr__fav${locked ? " cf-fr__fav--on" : ""}`,
    title: locked ? "解除收藏锁" : "上锁收藏（不会被卖出 / 交付）",
    onClick: onToggleLock
  }, LOCK), locked ? /*#__PURE__*/React.createElement("span", {
    className: "cf-fr__coin cf-fr__coin--locked"
  }, "\u9501\u5B9A") : /*#__PURE__*/React.createElement("button", {
    className: "cf-fr__coin",
    onClick: onSell
  }, coinIcon ? /*#__PURE__*/React.createElement("img", {
    src: coinIcon,
    alt: ""
  }) : null, value)));
}
Object.assign(__ds_scope, { FishRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/FishRow.jsx", error: String((e && e.message) || e) }); }

// components/game/HudChip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-chip{display:inline-flex;align-items:center;gap:6px;border:none;background:transparent;
  padding:0;cursor:default;font-family:var(--font-sans);line-height:1.3;
  text-shadow:0 1px 3px rgba(0,0,0,0.6);white-space:nowrap;}
.cf-chip--btn{cursor:pointer;transition:color var(--dur-fast) var(--ease-calm);}
.cf-chip--btn:hover{color:var(--gold-bright);}
.cf-chip__icon{width:1.15em;height:1.15em;object-fit:contain;flex:0 0 auto;
  filter:drop-shadow(0 1px 2px rgba(0,0,0,0.5));}
.cf-chip__val{font-weight:var(--w-bold);font-variant-numeric:tabular-nums;}
`;
const TONES = {
  default: "#ECE8E0",
  muted: "var(--text-muted-glass)",
  gold: "var(--merchant)",
  positive: "var(--positive)",
  warn: "var(--bag-full)",
  water: "var(--water-light)"
};

/**
 * A HUD line that floats over the scene — coin/basket ledger, spot·phase,
 * order progress. Flat, text-shadowed for readability on any wallpaper.
 */
function HudChip({
  children,
  icon,
  tone = "default",
  size = 14,
  onClick,
  style,
  ...rest
}) {
  useCfStyles("cf-chip-css", CSS);
  const color = TONES[tone] || tone;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: `cf-chip${onClick ? " cf-chip--btn" : ""}`,
    onClick: onClick,
    tabIndex: onClick ? 0 : -1,
    style: {
      color,
      fontSize: size,
      ...style
    }
  }, rest), icon ? /*#__PURE__*/React.createElement("img", {
    className: "cf-chip__icon",
    src: icon,
    alt: "",
    "aria-hidden": "true"
  }) : null, children);
}
Object.assign(__ds_scope, { HudChip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/HudChip.jsx", error: String((e && e.message) || e) }); }

// components/game/HudLedger.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-ledger{display:inline-flex;align-items:center;gap:10px;font-family:var(--font-sans);
  padding:7px 12px;border-radius:12px;background:rgba(26,27,23,.62);
  border:1px solid rgba(224,214,189,.28);box-shadow:0 4px 14px rgba(0,0,0,.3);
  backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);}
.cf-ledger__coin{display:flex;align-items:center;gap:6px;}
.cf-ledger__coin img{width:18px;height:18px;object-fit:contain;}
.cf-ledger__v{font-family:var(--font-display);font-weight:900;font-size:18px;line-height:1;
  color:#f7e9c8;font-variant-numeric:tabular-nums;}
.cf-ledger__sep{width:1px;height:22px;background:rgba(224,214,189,.3);}
.cf-ledger__bag{display:flex;flex-direction:column;gap:3px;}
.cf-ledger__t{font-size:11px;line-height:1;color:#d8d2c4;font-variant-numeric:tabular-nums;}
.cf-ledger__t--full{color:var(--bag-full);font-weight:600;}
.cf-ledger__b{width:54px;height:4px;border-radius:999px;background:rgba(255,255,255,.18);overflow:hidden;}
.cf-ledger__b i{display:block;height:100%;border-radius:999px;
  background:linear-gradient(90deg,var(--bronze),var(--gold));}
.cf-ledger__b--full i{background:linear-gradient(90deg,var(--bag-full),var(--gold-bright));}
`;

/**
 * Frosted-glass HUD capsule for the on-scene ledger: coins + basket
 * capacity, readable over any wallpaper without blocking the scene.
 */
function HudLedger({
  coins = 0,
  used = 0,
  capacity = 20,
  coinIcon,
  style
}) {
  useCfStyles("cf-ledger-css", CSS);
  const pct = Math.max(0, Math.min(100, used / capacity * 100));
  const full = used >= capacity;
  return /*#__PURE__*/React.createElement("div", {
    className: "cf-ledger",
    style: style
  }, /*#__PURE__*/React.createElement("div", {
    className: "cf-ledger__coin"
  }, coinIcon ? /*#__PURE__*/React.createElement("img", {
    src: coinIcon,
    alt: ""
  }) : null, /*#__PURE__*/React.createElement("span", {
    className: "cf-ledger__v"
  }, Number(coins).toLocaleString())), /*#__PURE__*/React.createElement("div", {
    className: "cf-ledger__sep"
  }), /*#__PURE__*/React.createElement("div", {
    className: "cf-ledger__bag"
  }, /*#__PURE__*/React.createElement("span", {
    className: `cf-ledger__t${full ? " cf-ledger__t--full" : ""}`
  }, "\u9C7C\u7BD3 ", used, "/", capacity), /*#__PURE__*/React.createElement("span", {
    className: `cf-ledger__b${full ? " cf-ledger__b--full" : ""}`
  }, /*#__PURE__*/React.createElement("i", {
    style: {
      width: `${pct}%`
    }
  }))));
}
Object.assign(__ds_scope, { HudLedger });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/HudLedger.jsx", error: String((e && e.message) || e) }); }

// components/game/SummaryStrip.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-sum{display:flex;align-items:center;gap:14px;font-family:var(--font-sans);
  background:rgba(0,0,0,.22);border:1px solid var(--glass-row-border);
  border-radius:12px;padding:11px 14px;}
.cf-sum__cap{flex:1;display:flex;flex-direction:column;gap:6px;min-width:0;}
.cf-sum__top{display:flex;justify-content:space-between;font-size:12px;color:var(--text-muted-glass);}
.cf-sum__top b{color:#ece8e0;font-weight:600;font-variant-numeric:tabular-nums;}
.cf-sum__bar{height:6px;border-radius:999px;background:rgba(255,255,255,.12);overflow:hidden;}
.cf-sum__bar i{display:block;height:100%;border-radius:999px;
  background:linear-gradient(90deg,var(--bronze),var(--gold));
  transition:width var(--dur-base) var(--ease-calm);}
.cf-sum__bar--full i{background:linear-gradient(90deg,var(--bag-full),var(--gold-bright));}
.cf-sum__val{display:flex;align-items:center;gap:8px;padding-left:14px;
  border-left:1px solid var(--glass-row-border);flex:0 0 auto;}
.cf-sum__val img{width:22px;height:22px;object-fit:contain;}
.cf-sum__v{font-family:var(--font-display);font-weight:900;font-size:26px;line-height:1;
  color:var(--gold-bright);font-variant-numeric:tabular-nums;}
.cf-sum__vlab{font-size:10px;color:var(--text-muted-glass);letter-spacing:.04em;}
`;

/**
 * Bag overview strip: a capacity meter + the headline sellable-value readout.
 * Surfaces the two numbers that drive every basket decision.
 */
function SummaryStrip({
  used = 0,
  capacity = 20,
  value,
  coinIcon,
  capLabel = "鱼篓容量",
  valueLabel = "可卖（未锁）",
  style
}) {
  useCfStyles("cf-summary-css", CSS);
  const pct = Math.max(0, Math.min(100, used / capacity * 100));
  const full = used >= capacity;
  return /*#__PURE__*/React.createElement("div", {
    className: "cf-sum",
    style: style
  }, /*#__PURE__*/React.createElement("div", {
    className: "cf-sum__cap"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cf-sum__top"
  }, /*#__PURE__*/React.createElement("span", null, capLabel), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", null, used), " / ", capacity)), /*#__PURE__*/React.createElement("div", {
    className: `cf-sum__bar${full ? " cf-sum__bar--full" : ""}`
  }, /*#__PURE__*/React.createElement("i", {
    style: {
      width: `${pct}%`
    }
  }))), value != null ? /*#__PURE__*/React.createElement("div", {
    className: "cf-sum__val"
  }, coinIcon ? /*#__PURE__*/React.createElement("img", {
    src: coinIcon,
    alt: ""
  }) : null, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "cf-sum__v"
  }, Number(value).toLocaleString()), /*#__PURE__*/React.createElement("div", {
    className: "cf-sum__vlab"
  }, valueLabel))) : null);
}
Object.assign(__ds_scope, { SummaryStrip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/SummaryStrip.jsx", error: String((e && e.message) || e) }); }

// components/primitives/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-badge{display:inline-flex;align-items:center;gap:3px;font-family:var(--font-sans);
  font-weight:var(--w-medium);font-size:var(--fs-2xs);line-height:1;white-space:nowrap;}
.cf-badge--pill{padding:3px 8px;border-radius:999px;border:1px solid transparent;}
.cf-badge--outline{padding:2px 7px;border-radius:999px;
  border:1px solid currentColor;background:transparent;}
/* text badge sitting on warm paper: warm-ink outline keeps colour legible */
.cf-badge--legible{text-shadow:
  0.6px 0.6px 0 rgba(22,18,12,0.92), -0.6px 0.6px 0 rgba(22,18,12,0.92),
  0.6px -0.6px 0 rgba(22,18,12,0.92), -0.6px -0.6px 0 rgba(22,18,12,0.92);}
`;
const TONES = {
  "tier-0": "var(--tier-0)",
  "tier-1": "var(--tier-1)",
  "tier-2": "var(--tier-2)",
  "tier-3": "var(--tier-3)",
  "tier-4": "var(--tier-4)",
  "tier-5": "var(--tier-5)",
  "variant-1": "var(--variant-1)",
  "variant-2": "var(--variant-2)",
  "variant-3": "var(--variant-3)",
  gold: "var(--gold)",
  positive: "var(--positive)",
  merchant: "var(--merchant)",
  rust: "var(--rust)",
  neutral: "var(--text-muted-glass)"
};

/**
 * Small status / rarity badge. `text` = colored label (codex marks),
 * `pill` = filled pill, `outline` = hollow pill.
 */
function Badge({
  children,
  tone = "neutral",
  variant = "text",
  legible = false,
  style,
  ...rest
}) {
  useCfStyles("cf-badge-css", CSS);
  const color = TONES[tone] || tone;
  let extra = {};
  if (variant === "pill") {
    extra = {
      background: color,
      color: "var(--glass-solid)",
      borderColor: "rgba(255,255,255,0.18)"
    };
  } else if (variant === "outline") {
    extra = {
      color
    };
  } else {
    extra = {
      color
    };
  }
  return /*#__PURE__*/React.createElement("span", _extends({
    className: `cf-badge cf-badge--${variant}${legible ? " cf-badge--legible" : ""}`,
    style: {
      ...extra,
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/primitives/Badge.jsx", error: String((e && e.message) || e) }); }

// components/primitives/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/* Shared once-injected stylesheet for the primitives group.
   Plain DOM injection (not a CSS-in-JS lib) so :hover / :active work
   while components stay self-contained and token-driven. */
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-btn{
  display:inline-flex;align-items:center;justify-content:center;gap:6px;
  font-family:var(--font-sans);font-weight:var(--w-medium);
  border-radius:var(--r-btn);border:1px solid transparent;cursor:pointer;
  white-space:nowrap;user-select:none;line-height:1;
  transition:background-color var(--dur-fast) var(--ease-calm),
             border-color var(--dur-fast) var(--ease-calm),
             color var(--dur-fast) var(--ease-calm), opacity var(--dur-fast);
}
.cf-btn:focus-visible{outline:2px solid var(--gold);outline-offset:2px;}
.cf-btn--sm{height:24px;padding:0 10px;font-size:var(--fs-xs);}
.cf-btn--md{height:var(--btn-h);padding:0 14px;font-size:var(--fs-sm);}
.cf-btn--lg{height:38px;padding:0 22px;font-size:var(--fs-body);}

.cf-btn--primary{background:var(--btn-primary-bg);color:var(--btn-primary-fg);
  border-color:rgba(255,222,140,0.28);font-weight:var(--w-bold);}
.cf-btn--primary:hover{background:var(--btn-primary-bg-hover);}
.cf-btn--primary:active{background:var(--btn-primary-bg-press);}

.cf-btn--secondary{background:var(--btn-secondary-bg);color:var(--btn-secondary-fg);
  border-color:rgba(214,205,174,0.22);}
.cf-btn--secondary:hover{background:var(--btn-secondary-bg-hover);}
.cf-btn--secondary:active{background:rgba(64,64,56,0.95);}

.cf-btn--ghost{background:transparent;color:var(--text-muted-glass);}
.cf-btn--ghost:hover{background:var(--glass-row-hover);color:var(--text-on-glass);}

.cf-btn:disabled{opacity:0.45;cursor:default;pointer-events:none;}
.cf-btn__icon{width:1.05em;height:1.05em;object-fit:contain;display:block;}
`;

/**
 * Bronze / glass / ghost button — the workhorse control of the widget.
 * Primary = warm bronze with dark ink (sell, deliver, upgrade).
 */
function Button({
  children,
  variant = "secondary",
  size = "md",
  icon,
  disabled = false,
  onClick,
  className = "",
  style,
  ...rest
}) {
  useCfStyles("cf-primitives-css", CSS);
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: `cf-btn cf-btn--${variant} cf-btn--${size} ${className}`,
    disabled: disabled,
    onClick: onClick,
    style: style
  }, rest), icon ? /*#__PURE__*/React.createElement("img", {
    className: "cf-btn__icon",
    src: icon,
    alt: "",
    "aria-hidden": "true"
  }) : null, children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/primitives/Button.jsx", error: String((e && e.message) || e) }); }

// components/game/SpotCard.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-spot{box-sizing:border-box;display:flex;flex-direction:column;gap:4px;
  padding:8px 10px;border-radius:var(--r-card);font-family:var(--font-sans);}
.cf-spot--on{background:var(--surface-card);border:var(--border-card);}
.cf-spot--off{background:var(--surface-row);border:var(--border-row);}
.cf-spot__head{display:flex;align-items:center;gap:8px;}
.cf-spot__name{font-family:var(--font-display);font-weight:var(--w-bold);
  font-size:var(--fs-head);flex:1 1 auto;}
.cf-spot__name--on{color:#3D4D66;}
.cf-spot__name--off{color:#B3A992;}
.cf-spot__desc{font-size:var(--fs-xs);line-height:1.5;}
.cf-spot__desc--on{color:var(--ink-soft);}
.cf-spot__desc--off{color:#988F7F;}
.cf-spot__foot{font-size:var(--fs-xs);}
.cf-spot__foot--on{color:#5A7A55;}
.cf-spot__foot--off{color:var(--gold);}
`;

/** A fishing-spot card (钓点). Current / available / locked states. */
function SpotCard({
  name,
  desc,
  got = 0,
  total = 0,
  unlocked = false,
  current = false,
  event,
  unlockText,
  onGo,
  style
}) {
  useCfStyles("cf-spot-css", CSS);
  const tone = unlocked ? "on" : "off";
  return /*#__PURE__*/React.createElement("div", {
    className: `cf-spot cf-spot--${tone}`,
    style: style
  }, /*#__PURE__*/React.createElement("div", {
    className: "cf-spot__head"
  }, /*#__PURE__*/React.createElement("span", {
    className: `cf-spot__name cf-spot__name--${tone}`
  }, current ? "📍 " : "", name), current ? /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "secondary",
    size: "md",
    disabled: true,
    style: {
      minWidth: 70
    }
  }, "\u5F53\u524D") : unlocked ? /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "primary",
    size: "md",
    onClick: onGo,
    style: {
      minWidth: 70
    }
  }, "\u524D\u5F80") : /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "secondary",
    size: "md",
    disabled: true,
    style: {
      minWidth: 70
    }
  }, "\u672A\u89E3\u9501")), /*#__PURE__*/React.createElement("div", {
    className: `cf-spot__desc cf-spot__desc--${tone}`
  }, desc), /*#__PURE__*/React.createElement("div", {
    className: `cf-spot__foot cf-spot__foot--${tone}`
  }, unlocked ? `鱼种收集 ${got}/${total}${current ? `　·　${event || "风平浪静"}` : ""}` : `🔒 ${unlockText}`));
}
Object.assign(__ds_scope, { SpotCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/game/SpotCard.jsx", error: String((e && e.message) || e) }); }

// components/primitives/ProgressBar.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-prog{display:flex;flex-direction:column;gap:5px;font-family:var(--font-sans);width:100%;}
.cf-prog__track{position:relative;width:100%;height:18px;border-radius:999px;
  background:rgba(0,0,0,0.30);border:1px solid var(--glass-row-border);overflow:hidden;}
.cf-prog__track--paper{background:rgba(120,110,86,0.22);border-color:rgba(120,110,86,0.25);}
.cf-prog__fill{height:100%;border-radius:999px;
  background:linear-gradient(90deg,var(--bronze),var(--gold));
  transition:width var(--dur-base) var(--ease-calm);}
.cf-prog__pct{position:absolute;inset:0;display:grid;place-items:center;
  font-size:var(--fs-xs);font-weight:var(--w-medium);color:#F3ECDC;
  text-shadow:0 1px 2px rgba(0,0,0,0.55);font-variant-numeric:tabular-nums;}
.cf-prog__cap{display:flex;justify-content:space-between;font-size:var(--fs-xs);
  color:var(--ink-soft);}
`;

/** Bronze→gold fill bar — weekly challenge, collection progress. */
function ProgressBar({
  value,
  max = 100,
  showPercent = true,
  caption,
  surface = "glass",
  style
}) {
  useCfStyles("cf-progress-css", CSS);
  const pct = Math.max(0, Math.min(100, value / max * 100));
  return /*#__PURE__*/React.createElement("div", {
    className: "cf-prog",
    style: style
  }, /*#__PURE__*/React.createElement("div", {
    className: `cf-prog__track${surface === "paper" ? " cf-prog__track--paper" : ""}`
  }, /*#__PURE__*/React.createElement("div", {
    className: "cf-prog__fill",
    style: {
      width: `${pct}%`
    }
  }), showPercent ? /*#__PURE__*/React.createElement("span", {
    className: "cf-prog__pct"
  }, Math.round(pct), "%") : null), caption ? /*#__PURE__*/React.createElement("div", {
    className: "cf-prog__cap"
  }, caption) : null);
}
Object.assign(__ds_scope, { ProgressBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/primitives/ProgressBar.jsx", error: String((e && e.message) || e) }); }

// components/primitives/RoundButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-round{
  display:grid;place-items:center;padding:0;border:none;background:transparent;
  cursor:pointer;border-radius:50%;line-height:0;
  filter:drop-shadow(var(--shadow-round));
  transition:transform var(--dur-fast) var(--ease-calm),
             filter var(--dur-fast) var(--ease-calm);
}
.cf-round img{width:100%;height:100%;object-fit:contain;display:block;}
.cf-round:hover{transform:translateY(-1px);
  filter:drop-shadow(0 4px 9px rgba(0,0,0,0.42)) brightness(1.06);}
.cf-round:active{transform:translateY(0) scale(0.96);}
.cf-round:focus-visible{outline:2px solid var(--gold);outline-offset:3px;}
.cf-round__badge{
  position:absolute;top:-3px;right:-3px;min-width:16px;height:16px;padding:0 4px;
  display:grid;place-items:center;border-radius:999px;
  background:var(--rust);color:#fff;font-family:var(--font-sans);
  font-weight:var(--w-bold);font-size:10px;line-height:1;
  box-shadow:0 1px 3px rgba(0,0,0,0.4);
}
`;

/**
 * Round desktop-widget button — the three corner controls
 * (rod / fish-basket / coin). Renders a painterly PNG face.
 */
function RoundButton({
  icon,
  size = 40,
  title,
  badge,
  onClick,
  style,
  ...rest
}) {
  useCfStyles("cf-roundbtn-css", CSS);
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: "cf-round",
    title: title,
    "aria-label": title,
    onClick: onClick,
    style: {
      width: size,
      height: size,
      position: badge != null ? "relative" : undefined,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("img", {
    src: icon,
    alt: "",
    "aria-hidden": "true"
  }), badge != null ? /*#__PURE__*/React.createElement("span", {
    className: "cf-round__badge"
  }, badge) : null);
}
Object.assign(__ds_scope, { RoundButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/primitives/RoundButton.jsx", error: String((e && e.message) || e) }); }

// components/primitives/Slider.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-slider{display:flex;flex-direction:column;gap:6px;font-family:var(--font-sans);}
.cf-slider__top{display:flex;justify-content:space-between;align-items:baseline;
  font-size:var(--fs-xs);}
.cf-slider__label{color:var(--text-muted-glass);}
.cf-slider__val{color:var(--gold);font-variant-numeric:tabular-nums;}
.cf-slider input[type=range]{
  -webkit-appearance:none;appearance:none;width:100%;height:6px;border-radius:999px;
  background:rgba(0,0,0,0.34);outline:none;cursor:pointer;margin:6px 0;
}
.cf-slider input[type=range]::-webkit-slider-thumb{
  -webkit-appearance:none;appearance:none;width:16px;height:16px;border-radius:50%;
  background:#F3ECDC;border:1px solid var(--bronze);box-shadow:0 1px 3px rgba(0,0,0,0.45);
  transition:transform var(--dur-fast) var(--ease-calm);
}
.cf-slider input[type=range]::-webkit-slider-thumb:hover{transform:scale(1.12);}
.cf-slider input[type=range]::-moz-range-thumb{
  width:16px;height:16px;border-radius:50%;background:#F3ECDC;
  border:1px solid var(--bronze);box-shadow:0 1px 3px rgba(0,0,0,0.45);
}
.cf-slider--disabled{opacity:0.5;pointer-events:none;}
`;

/** Labeled value slider — volume / opacity controls in Settings. */
function Slider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  onChange,
  format,
  disabled = false,
  style
}) {
  useCfStyles("cf-slider-css", CSS);
  const display = format ? format(value) : `${Math.round(value / (max - min) * 100)}%`;
  return /*#__PURE__*/React.createElement("div", {
    className: `cf-slider${disabled ? " cf-slider--disabled" : ""}`,
    style: style
  }, /*#__PURE__*/React.createElement("div", {
    className: "cf-slider__top"
  }, /*#__PURE__*/React.createElement("span", {
    className: "cf-slider__label"
  }, label), /*#__PURE__*/React.createElement("span", {
    className: "cf-slider__val"
  }, display)), /*#__PURE__*/React.createElement("input", {
    type: "range",
    min: min,
    max: max,
    step: step,
    value: value,
    disabled: disabled,
    onChange: e => onChange && onChange(Number(e.target.value))
  }));
}
Object.assign(__ds_scope, { Slider });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/primitives/Slider.jsx", error: String((e && e.message) || e) }); }

// components/primitives/Toggle.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-toggle{display:inline-flex;align-items:center;gap:10px;cursor:pointer;
  font-family:var(--font-sans);font-size:var(--fs-body);color:var(--text-on-glass);}
.cf-toggle--disabled{opacity:0.5;cursor:default;}
.cf-toggle__track{
  position:relative;width:42px;height:22px;border-radius:999px;flex:0 0 auto;
  background:rgba(0,0,0,0.35);border:1px solid var(--glass-row-border);
  transition:background-color var(--dur-base) var(--ease-calm);
}
.cf-toggle__track--on{background:var(--bronze);border-color:rgba(255,222,140,0.4);}
.cf-toggle__knob{
  position:absolute;top:2px;left:2px;width:16px;height:16px;border-radius:50%;
  background:#F3ECDC;box-shadow:0 1px 2px rgba(0,0,0,0.45);
  transition:transform var(--dur-base) var(--ease-calm);
}
.cf-toggle__track--on .cf-toggle__knob{transform:translateX(20px);}
`;

/** On/off switch — used in Settings (mute, focus-mode). */
function Toggle({
  checked = false,
  onChange,
  label,
  disabled = false,
  style
}) {
  useCfStyles("cf-toggle-css", CSS);
  return /*#__PURE__*/React.createElement("label", {
    className: `cf-toggle${disabled ? " cf-toggle--disabled" : ""}`,
    style: style
  }, label ? /*#__PURE__*/React.createElement("span", null, label) : null, /*#__PURE__*/React.createElement("span", {
    role: "switch",
    "aria-checked": checked,
    tabIndex: disabled ? -1 : 0,
    className: `cf-toggle__track${checked ? " cf-toggle__track--on" : ""}`,
    onClick: () => !disabled && onChange && onChange(!checked),
    onKeyDown: e => {
      if (!disabled && (e.key === "Enter" || e.key === " ")) {
        e.preventDefault();
        onChange && onChange(!checked);
      }
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "cf-toggle__knob"
  })));
}
Object.assign(__ds_scope, { Toggle });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/primitives/Toggle.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-card{box-sizing:border-box;font-family:var(--font-sans);}
.cf-card--paper{background:var(--surface-card);border:var(--border-card);
  border-radius:var(--r-card);color:var(--ink);box-shadow:var(--shadow-card);}
.cf-card--row{background:var(--surface-row);border:var(--border-row);
  border-radius:var(--r-row);color:var(--text-on-glass);}
.cf-card--glass{background:rgba(31,33,31,0.55);border:var(--border-row);
  border-radius:var(--r-card);color:var(--text-on-glass);}
.cf-card--pad{padding:10px 12px;}
.cf-card--interactive{cursor:pointer;
  transition:background-color var(--dur-fast) var(--ease-calm),
             border-color var(--dur-fast) var(--ease-calm),
             transform var(--dur-fast) var(--ease-calm);}
.cf-card--row.cf-card--interactive:hover{background:var(--glass-row-hover);}
.cf-card--paper.cf-card--interactive:hover{border-color:var(--gold);}
.cf-card--locked{opacity:0.5;filter:grayscale(0.35);}
`;

/**
 * Surface container. `paper` = warm parchment (codex / orders),
 * `row` = dark inset row (bag entries), `glass` = translucent block.
 */
function Card({
  children,
  surface = "row",
  pad = true,
  interactive = false,
  locked = false,
  onClick,
  className = "",
  style,
  ...rest
}) {
  useCfStyles("cf-card-css", CSS);
  const cls = ["cf-card", `cf-card--${surface}`, pad ? "cf-card--pad" : "", interactive ? "cf-card--interactive" : "", locked ? "cf-card--locked" : "", className].filter(Boolean).join(" ");
  return /*#__PURE__*/React.createElement("div", _extends({
    className: cls,
    onClick: interactive ? onClick : undefined,
    style: style
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Card.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Panel.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-panel{
  display:flex;flex-direction:column;box-sizing:border-box;
  background:var(--surface-panel);border:var(--border-glass);
  border-radius:var(--r-panel);box-shadow:var(--shadow-panel);
  backdrop-filter:var(--blur-glass);-webkit-backdrop-filter:var(--blur-glass);
  color:var(--text-on-glass);font-family:var(--font-sans);
  padding:var(--panel-pad-y) var(--panel-pad-x);
}
.cf-panel__head{display:flex;align-items:center;gap:8px;height:26px;
  margin-bottom:var(--row-gap);cursor:grab;flex:0 0 auto;}
.cf-panel__title{font-family:var(--font-display);font-weight:var(--w-bold);
  font-size:var(--fs-title);color:var(--text-title);letter-spacing:var(--track-tight);}
.cf-panel__sub{font-size:var(--fs-xs);color:var(--text-muted-glass);
  margin-left:auto;align-self:center;}
.cf-panel__close{margin-left:auto;width:28px;height:26px;border:none;background:transparent;
  color:var(--text-muted-glass);font-size:18px;line-height:1;cursor:pointer;border-radius:6px;
  transition:background-color var(--dur-fast),color var(--dur-fast);}
.cf-panel__close:hover{background:var(--glass-row-hover);color:var(--text-on-glass);}
.cf-panel__sub + .cf-panel__close{margin-left:8px;}
.cf-panel__body{display:flex;flex-direction:column;gap:var(--row-gap);min-height:0;flex:1 1 auto;}
`;

/** Floating dark-glass dialog — the widget's pop-up panel chrome. */
function Panel({
  title,
  subtitle,
  onClose,
  children,
  width = 520,
  style,
  bodyStyle,
  ...rest
}) {
  useCfStyles("cf-panel-css", CSS);
  return /*#__PURE__*/React.createElement("section", _extends({
    className: "cf-panel",
    style: {
      width,
      ...style
    }
  }, rest), (title || onClose) && /*#__PURE__*/React.createElement("header", {
    className: "cf-panel__head"
  }, title ? /*#__PURE__*/React.createElement("span", {
    className: "cf-panel__title"
  }, title) : null, subtitle ? /*#__PURE__*/React.createElement("span", {
    className: "cf-panel__sub"
  }, subtitle) : null, onClose ? /*#__PURE__*/React.createElement("button", {
    className: "cf-panel__close",
    onClick: onClose,
    "aria-label": "\u5173\u95ED",
    title: "\u5173\u95ED"
  }, "\xD7") : null), /*#__PURE__*/React.createElement("div", {
    className: "cf-panel__body",
    style: bodyStyle
  }, children));
}
Object.assign(__ds_scope, { Panel });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Panel.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/TabBar.jsx
try { (() => {
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}
const CSS = `
.cf-tabs{display:flex;flex-wrap:wrap;gap:6px;}
.cf-tabs--underline{flex-wrap:nowrap;align-items:center;gap:6px;}
.cf-tab{height:var(--tab-h);padding:0 12px;border-radius:var(--r-btn);cursor:pointer;
  font-family:var(--font-sans);font-size:var(--fs-sm);line-height:1;border:1px solid transparent;
  background:var(--btn-secondary-bg);color:var(--btn-secondary-fg);
  transition:background-color var(--dur-fast) var(--ease-calm),color var(--dur-fast);}
.cf-tab:hover{background:var(--btn-secondary-bg-hover);}
.cf-tab--active{background:var(--btn-primary-bg);color:var(--btn-primary-fg);
  font-weight:var(--w-bold);border-color:rgba(255,222,140,0.28);}
.cf-tab--active:hover{background:var(--btn-primary-bg-hover);}

/* underline variant — lighter chrome for the primary nav */
.cf-utab{position:relative;height:30px;padding:0 14px;border:none;background:transparent;cursor:pointer;
  font-family:var(--font-sans);font-size:var(--fs-sm);line-height:1;color:var(--text-muted-glass);
  transition:color var(--dur-fast) var(--ease-calm);border-radius:999px;}
.cf-utab:hover{color:var(--text-on-glass);}
.cf-utab--active{color:#F3ECDC;font-weight:var(--w-bold);}
.cf-utab--active::after{content:"";position:absolute;left:14px;right:14px;bottom:-3px;height:2px;
  border-radius:2px;background:linear-gradient(90deg,var(--gold),var(--bronze));}
.cf-utab--more{margin-left:auto;color:var(--text-faint-glass);
  border:1px solid var(--glass-row-border);}
.cf-utab--more:hover{color:var(--text-on-glass);background:var(--glass-row-hover);}
`;

/**
 * Tab bar. `pill` (default) = filled pills (dense list nav).
 * `underline` = lighter primary nav with a gold underline indicator and
 * an optional right-aligned `overflow` item (e.g. "更多 ▾").
 */
function TabBar({
  tabs,
  active = 0,
  onChange,
  variant = "pill",
  overflow,
  onOverflow,
  style
}) {
  useCfStyles("cf-tabs-css", CSS);
  if (variant === "underline") {
    return /*#__PURE__*/React.createElement("div", {
      className: "cf-tabs cf-tabs--underline",
      role: "tablist",
      style: style
    }, tabs.map((t, i) => {
      const label = typeof t === "string" ? t : t.label;
      return /*#__PURE__*/React.createElement("button", {
        key: i,
        role: "tab",
        "aria-selected": i === active,
        className: `cf-utab${i === active ? " cf-utab--active" : ""}`,
        onClick: () => i !== active && onChange && onChange(i)
      }, label);
    }), overflow ? /*#__PURE__*/React.createElement("button", {
      className: "cf-utab cf-utab--more",
      onClick: onOverflow
    }, overflow) : null);
  }
  return /*#__PURE__*/React.createElement("div", {
    className: "cf-tabs",
    role: "tablist",
    style: style
  }, tabs.map((t, i) => {
    const label = typeof t === "string" ? t : t.label;
    return /*#__PURE__*/React.createElement("button", {
      key: i,
      role: "tab",
      "aria-selected": i === active,
      className: `cf-tab${i === active ? " cf-tab--active" : ""}`,
      onClick: () => i !== active && onChange && onChange(i)
    }, label);
  }));
}
Object.assign(__ds_scope, { TabBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/TabBar.jsx", error: String((e && e.message) || e) }); }

// playable/data.js
try { (() => {
// AUTO-DERIVED from source/fish_data.gd — do not hand-edit fish stats.
// 角落垂钓 game data (1:1 with the Godot source).
window.GAMEDATA = function () {
  const TIER_NAMES = ["普通", "优良", "稀有", "史诗", "传说", "神话"];
  const TIER_COLORS = ["#C7C7CC", "#59C74D", "#4D9EF2", "#B86BF2", "#FF8C1F", "#FF6152"];
  const QUALITY_NAMES = ["", "上品", "极品", "完美"];
  const QUALITY_MULTS = [1.0, 1.8, 4.0, 8.0];
  const VARIANT_NAMES = ["", "斑斓", "鎏金", "七彩"];
  const VARIANT_MULTS = [1.0, 2.0, 5.0, 12.0];
  const VARIANT_COLORS = ["#ffffff", "#8CD9F2", "#FFD659", "#F28CF2"];
  const VARIANT_PROBS = [0.0, 0.06, 0.012, 0.002];
  const BASE_WEIGHTS = {
    0: 58.0,
    1: 25.0,
    2: 11.0,
    3: 4.5,
    4: 1.3,
    5: 0.2
  };
  const BAITS = [{
    name: "蚯蚓",
    cost: 0,
    probs: [1.0, 0.08, 0.02, 0.05],
    desc: "河边随手挖的"
  }, {
    name: "红虫",
    cost: 800,
    probs: [1.0, 0.22, 0.10, 0.08],
    desc: "冬钓利器，上品率明显提升"
  }, {
    name: "活虾",
    cost: 5000,
    probs: [1.0, 0.45, 0.18, 0.12],
    desc: "大鱼爱追活食"
  }, {
    name: "秘制饵",
    cost: 24000,
    probs: [1.0, 0.70, 0.35, 0.18],
    desc: "老钓翁的祖传配方"
  }];
  const HOOKS = [{
    name: "基础鱼钩",
    cost: 0,
    double: 0.0,
    desc: "普普通通的单钩"
  }, {
    name: "宽门钩",
    cost: 2000,
    double: 0.10,
    desc: "钩门更宽，偶尔双钩"
  }, {
    name: "倒刺钩",
    cost: 12000,
    double: 0.20,
    desc: "倒刺挂得牢，双钩更常见"
  }, {
    name: "双叉钩",
    cost: 60000,
    double: 0.32,
    desc: "一线两钩，常常成对上鱼"
  }];
  const BAG_CAPS = [20, 25, 30, 35, 40, 45, 50, 55];
  const BAG_COSTS = [100, 250, 600, 1500, 4000, 10000, 25000];
  const SPOTS = {
    river_bend: {
      name: "新手河湾",
      desc: "最初的那方静水，缓流绕过雪岸。从白条到国宝鲟，什么都可能上钩——新手友好的全能钓点。",
      unlock: null,
      habitat_tags: ["river"],
      bg: "spot_river_bend",
      surface: "glass",
      wait_mult: 1.0,
      value_mult: 1.0,
      luck_bonus: 0,
      bite: [300, 322]
    },
    still_lake: {
      name: "静水湖泊",
      desc: "水草丰茂的冬日湖湾，掠食者潜伏在乱石与树根间。鲈、鳜、黑鱼、狗鱼当家，偶有巨鲟与欧鲶。",
      unlock: {
        kind: "catches",
        n: 80
      },
      habitat_tags: ["lake"],
      bg: "spot_still_lake",
      surface: "paper",
      wait_mult: 1.08,
      value_mult: 1.06,
      luck_bonus: 0,
      bite: [262, 346]
    },
    coast_pier: {
      name: "海岸码头",
      desc: "海风咸涩，浪拍木桩，小灯在栈桥尽头摇。海鲈、鲷、带鱼、石斑、马鲛轮番登场，深处藏着金枪与旗鱼。",
      unlock: {
        kind: "catches",
        n: 300
      },
      habitat_tags: ["coast"],
      bg: "spot_coast_pier",
      surface: "paper",
      wait_mult: 0.96,
      value_mult: 1.12,
      luck_bonus: 0,
      bite: [315, 330]
    }
  };
  const SPOT_ORDER = ["river_bend", "still_lake", "coast_pier"];
  const FISH = {
    "whitebait": {
      "name": "白条",
      "tier": 0,
      "wmin": 0.01,
      "wmax": 0.02,
      "vmin": 1,
      "vmax": 3,
      "tags": ["river", "lake"]
    },
    "topmouth": {
      "name": "麦穗鱼",
      "tier": 0,
      "wmin": 0.01,
      "wmax": 0.03,
      "vmin": 1,
      "vmax": 3,
      "tags": ["river", "lake"]
    },
    "loach": {
      "name": "泥鳅",
      "tier": 0,
      "wmin": 0.03,
      "wmax": 0.15,
      "vmin": 2,
      "vmax": 5,
      "tags": ["river", "lake", "night"]
    },
    "crucian": {
      "name": "鲫鱼",
      "tier": 0,
      "wmin": 0.1,
      "wmax": 0.6,
      "vmin": 3,
      "vmax": 9,
      "tags": ["river", "lake"]
    },
    "bighead": {
      "name": "鲢鳙",
      "tier": 0,
      "wmin": 1.5,
      "wmax": 3,
      "vmin": 6,
      "vmax": 14,
      "tags": ["river", "lake"]
    },
    "yellowhead": {
      "name": "黄颡鱼",
      "tier": 0,
      "wmin": 0.1,
      "wmax": 0.3,
      "vmin": 8,
      "vmax": 18,
      "tags": ["river", "lake", "night"]
    },
    "bluegill": {
      "name": "蓝鳃太阳鱼",
      "tier": 0,
      "wmin": 0.05,
      "wmax": 0.4,
      "vmin": 2,
      "vmax": 6,
      "tags": ["lake"]
    },
    "icefish": {
      "name": "银鱼",
      "tier": 0,
      "wmin": 0.005,
      "wmax": 0.02,
      "vmin": 3,
      "vmax": 8,
      "tags": ["lake", "cold"]
    },
    "bitterling": {
      "name": "鳑鲏",
      "tier": 0,
      "wmin": 0.005,
      "wmax": 0.02,
      "vmin": 1,
      "vmax": 3,
      "tags": ["lake"]
    },
    "sardine": {
      "name": "沙丁鱼",
      "tier": 0,
      "wmin": 0.02,
      "wmax": 0.1,
      "vmin": 2,
      "vmax": 5,
      "tags": ["coast"]
    },
    "filefish": {
      "name": "马面鲀",
      "tier": 0,
      "wmin": 0.1,
      "wmax": 0.5,
      "vmin": 4,
      "vmax": 10,
      "tags": ["coast"]
    },
    "goby": {
      "name": "虾虎鱼",
      "tier": 0,
      "wmin": 0.01,
      "wmax": 0.08,
      "vmin": 1,
      "vmax": 4,
      "tags": ["coast"]
    },
    "minnow": {
      "name": "马口鱼",
      "tier": 0,
      "wmin": 0.03,
      "wmax": 0.15,
      "vmin": 3,
      "vmax": 8,
      "tags": ["river", "stream"]
    },
    "zacco": {
      "name": "宽鳍鱲",
      "tier": 0,
      "wmin": 0.02,
      "wmax": 0.1,
      "vmin": 2,
      "vmax": 6,
      "tags": ["river", "stream"]
    },
    "gudgeon": {
      "name": "棒花鱼",
      "tier": 0,
      "wmin": 0.01,
      "wmax": 0.08,
      "vmin": 1,
      "vmax": 4,
      "tags": ["river", "lake"]
    },
    "spined_loach": {
      "name": "中华花鳅",
      "tier": 0,
      "wmin": 0.02,
      "wmax": 0.1,
      "vmin": 2,
      "vmax": 5,
      "tags": ["river", "lake", "night"]
    },
    "ricefish": {
      "name": "青鳉",
      "tier": 0,
      "wmin": 0.002,
      "wmax": 0.01,
      "vmin": 2,
      "vmax": 6,
      "tags": ["lake"]
    },
    "paradisefish": {
      "name": "斗鱼",
      "tier": 0,
      "wmin": 0.01,
      "wmax": 0.05,
      "vmin": 3,
      "vmax": 8,
      "tags": ["lake"]
    },
    "anchovy": {
      "name": "鳀鱼",
      "tier": 0,
      "wmin": 0.005,
      "wmax": 0.02,
      "vmin": 2,
      "vmax": 5,
      "tags": ["coast"]
    },
    "halfbeak": {
      "name": "鱵鱼",
      "tier": 0,
      "wmin": 0.02,
      "wmax": 0.12,
      "vmin": 3,
      "vmax": 8,
      "tags": ["coast"]
    },
    "sandlance": {
      "name": "玉筋鱼",
      "tier": 0,
      "wmin": 0.005,
      "wmax": 0.03,
      "vmin": 2,
      "vmax": 6,
      "tags": ["coast"]
    },
    "dace": {
      "name": "雅罗鱼",
      "tier": 1,
      "wmin": 0.3,
      "wmax": 1,
      "vmin": 14,
      "vmax": 26,
      "tags": ["river", "cold"]
    },
    "carp": {
      "name": "鲤鱼",
      "tier": 1,
      "wmin": 1,
      "wmax": 8,
      "vmin": 16,
      "vmax": 40,
      "tags": ["river", "lake"]
    },
    "grass": {
      "name": "草鱼",
      "tier": 1,
      "wmin": 2,
      "wmax": 12,
      "vmin": 16,
      "vmax": 42,
      "tags": ["river", "lake"]
    },
    "bream": {
      "name": "鳊鱼",
      "tier": 1,
      "wmin": 0.5,
      "wmax": 2,
      "vmin": 18,
      "vmax": 36,
      "tags": ["river", "lake"]
    },
    "blackcarp": {
      "name": "青鱼",
      "tier": 1,
      "wmin": 4,
      "wmax": 15,
      "vmin": 24,
      "vmax": 55,
      "tags": ["river", "lake"]
    },
    "perch": {
      "name": "河鲈",
      "tier": 1,
      "wmin": 0.2,
      "wmax": 1.2,
      "vmin": 18,
      "vmax": 38,
      "tags": ["lake"]
    },
    "catfish": {
      "name": "鲇鱼",
      "tier": 1,
      "wmin": 0.5,
      "wmax": 4,
      "vmin": 16,
      "vmax": 44,
      "tags": ["lake", "night"]
    },
    "swampeel": {
      "name": "黄鳝",
      "tier": 1,
      "wmin": 0.1,
      "wmax": 0.7,
      "vmin": 20,
      "vmax": 45,
      "tags": ["lake", "night"]
    },
    "tilapia": {
      "name": "罗非鱼",
      "tier": 1,
      "wmin": 0.2,
      "wmax": 1.5,
      "vmin": 14,
      "vmax": 30,
      "tags": ["lake"]
    },
    "mackerel": {
      "name": "鲐鱼",
      "tier": 1,
      "wmin": 0.2,
      "wmax": 1,
      "vmin": 14,
      "vmax": 30,
      "tags": ["coast"]
    },
    "small_croaker": {
      "name": "小黄鱼",
      "tier": 1,
      "wmin": 0.1,
      "wmax": 0.4,
      "vmin": 20,
      "vmax": 44,
      "tags": ["coast"]
    },
    "mullet": {
      "name": "鲻鱼",
      "tier": 1,
      "wmin": 0.3,
      "wmax": 2,
      "vmin": 16,
      "vmax": 36,
      "tags": ["coast"]
    },
    "rockfish": {
      "name": "许氏平鲉",
      "tier": 1,
      "wmin": 0.2,
      "wmax": 1.5,
      "vmin": 22,
      "vmax": 48,
      "tags": ["coast"]
    },
    "redeye": {
      "name": "赤眼鳟",
      "tier": 1,
      "wmin": 0.3,
      "wmax": 2,
      "vmin": 16,
      "vmax": 36,
      "tags": ["river", "lake"]
    },
    "wuchang": {
      "name": "武昌鱼",
      "tier": 1,
      "wmin": 0.5,
      "wmax": 2.5,
      "vmin": 18,
      "vmax": 40,
      "tags": ["river", "lake"]
    },
    "spotted_steed": {
      "name": "唇䱻",
      "tier": 1,
      "wmin": 0.3,
      "wmax": 1.5,
      "vmin": 18,
      "vmax": 38,
      "tags": ["river", "stream"]
    },
    "bigscale_loach": {
      "name": "大鳞副泥鳅",
      "tier": 1,
      "wmin": 0.05,
      "wmax": 0.3,
      "vmin": 16,
      "vmax": 34,
      "tags": ["lake", "night"]
    },
    "yellowtail_fish": {
      "name": "黄尾鲴",
      "tier": 1,
      "wmin": 0.2,
      "wmax": 1,
      "vmin": 16,
      "vmax": 32,
      "tags": ["river", "lake"]
    },
    "yellow_drum": {
      "name": "黄姑鱼",
      "tier": 1,
      "wmin": 0.3,
      "wmax": 2,
      "vmin": 20,
      "vmax": 44,
      "tags": ["coast"]
    },
    "greenling": {
      "name": "六线鱼",
      "tier": 1,
      "wmin": 0.2,
      "wmax": 1.5,
      "vmin": 22,
      "vmax": 46,
      "tags": ["coast"]
    },
    "haarder": {
      "name": "梭鱼",
      "tier": 1,
      "wmin": 0.3,
      "wmax": 2.5,
      "vmin": 18,
      "vmax": 40,
      "tags": ["coast"]
    },
    "flathead_fish": {
      "name": "鲬",
      "tier": 1,
      "wmin": 0.3,
      "wmax": 1.5,
      "vmin": 20,
      "vmax": 42,
      "tags": ["coast"]
    },
    "bass": {
      "name": "鲈鱼",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 3,
      "vmin": 55,
      "vmax": 120,
      "tags": ["river", "lake"]
    },
    "fangbream": {
      "name": "三角鲂",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 5,
      "vmin": 60,
      "vmax": 130,
      "tags": ["river", "lake"]
    },
    "barbel": {
      "name": "花䱻",
      "tier": 2,
      "wmin": 0.3,
      "wmax": 1.5,
      "vmin": 70,
      "vmax": 140,
      "tags": ["river", "stream"]
    },
    "culter": {
      "name": "翘嘴鲌",
      "tier": 2,
      "wmin": 1,
      "wmax": 5,
      "vmin": 80,
      "vmax": 170,
      "tags": ["river", "lake"]
    },
    "mandarin": {
      "name": "鳜鱼",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 3,
      "vmin": 90,
      "vmax": 190,
      "tags": ["river", "lake", "night"]
    },
    "largemouth": {
      "name": "大口黑鲈",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 4,
      "vmin": 70,
      "vmax": 160,
      "tags": ["lake"]
    },
    "seabass": {
      "name": "海鲈",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 5,
      "vmin": 70,
      "vmax": 160,
      "tags": ["coast"]
    },
    "blackbream": {
      "name": "黑鲷",
      "tier": 2,
      "wmin": 0.3,
      "wmax": 2.5,
      "vmin": 65,
      "vmax": 150,
      "tags": ["coast"]
    },
    "hairtail": {
      "name": "带鱼",
      "tier": 2,
      "wmin": 0.2,
      "wmax": 1.5,
      "vmin": 60,
      "vmax": 140,
      "tags": ["coast", "deep", "night"]
    },
    "flounder": {
      "name": "牙鲆",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 4,
      "vmin": 80,
      "vmax": 180,
      "tags": ["coast"]
    },
    "conger": {
      "name": "海鳗",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 5,
      "vmin": 60,
      "vmax": 140,
      "tags": ["coast", "night"]
    },
    "pufferfish": {
      "name": "红鳍东方鲀",
      "tier": 2,
      "wmin": 0.3,
      "wmax": 2,
      "vmin": 90,
      "vmax": 190,
      "tags": ["coast"]
    },
    "spinibarbus": {
      "name": "光倒刺鲃",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 3,
      "vmin": 60,
      "vmax": 130,
      "tags": ["river", "stream"]
    },
    "mongolian_redfin": {
      "name": "蒙古鲌",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 3,
      "vmin": 60,
      "vmax": 130,
      "tags": ["river", "lake"]
    },
    "small_snakehead": {
      "name": "月鳢",
      "tier": 2,
      "wmin": 0.3,
      "wmax": 1.5,
      "vmin": 60,
      "vmax": 130,
      "tags": ["lake", "night"]
    },
    "yellowfin_seabream": {
      "name": "黄鳍鲷",
      "tier": 2,
      "wmin": 0.3,
      "wmax": 2,
      "vmin": 65,
      "vmax": 150,
      "tags": ["coast"]
    },
    "crimson_snapper": {
      "name": "红笛鲷",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 3,
      "vmin": 70,
      "vmax": 160,
      "tags": ["coast"]
    },
    "spotted_scat": {
      "name": "金钱鱼",
      "tier": 2,
      "wmin": 0.2,
      "wmax": 1,
      "vmin": 60,
      "vmax": 130,
      "tags": ["coast"]
    },
    "octopus": {
      "name": "章鱼",
      "tier": 2,
      "wmin": 0.5,
      "wmax": 4,
      "vmin": 70,
      "vmax": 160,
      "tags": ["coast", "night"]
    },
    "squid": {
      "name": "鱿鱼",
      "tier": 2,
      "wmin": 0.2,
      "wmax": 2,
      "vmin": 60,
      "vmax": 140,
      "tags": ["coast", "night"]
    },
    "cuttlefish": {
      "name": "墨鱼",
      "tier": 2,
      "wmin": 0.3,
      "wmax": 2.5,
      "vmin": 65,
      "vmax": 150,
      "tags": ["coast"]
    },
    "snakehead": {
      "name": "黑鱼",
      "tier": 3,
      "wmin": 1,
      "wmax": 6,
      "vmin": 200,
      "vmax": 420,
      "tags": ["river", "lake", "night"]
    },
    "trout": {
      "name": "虹鳟",
      "tier": 3,
      "wmin": 0.8,
      "wmax": 4,
      "vmin": 210,
      "vmax": 430,
      "tags": ["river", "stream", "cold"]
    },
    "pike": {
      "name": "白斑狗鱼",
      "tier": 3,
      "wmin": 1,
      "wmax": 8,
      "vmin": 220,
      "vmax": 450,
      "tags": ["river", "lake", "cold"]
    },
    "zander": {
      "name": "梭鲈",
      "tier": 3,
      "wmin": 1,
      "wmax": 14,
      "vmin": 240,
      "vmax": 500,
      "tags": ["river", "lake"]
    },
    "longsnout": {
      "name": "江团",
      "tier": 3,
      "wmin": 1,
      "wmax": 5,
      "vmin": 260,
      "vmax": 520,
      "tags": ["river", "night"]
    },
    "lenok": {
      "name": "细鳞鱼",
      "tier": 3,
      "wmin": 0.5,
      "wmax": 3,
      "vmin": 280,
      "vmax": 560,
      "tags": ["river", "stream", "cold"]
    },
    "yellowcheek": {
      "name": "鳡鱼",
      "tier": 3,
      "wmin": 2,
      "wmax": 30,
      "vmin": 240,
      "vmax": 560,
      "tags": ["lake"]
    },
    "eel": {
      "name": "鳗鲡",
      "tier": 3,
      "wmin": 0.3,
      "wmax": 3,
      "vmin": 220,
      "vmax": 460,
      "tags": ["lake", "night"]
    },
    "seabream": {
      "name": "真鲷",
      "tier": 3,
      "wmin": 0.5,
      "wmax": 4,
      "vmin": 240,
      "vmax": 500,
      "tags": ["coast"]
    },
    "spanish_mackerel": {
      "name": "马鲛鱼",
      "tier": 3,
      "wmin": 1,
      "wmax": 8,
      "vmin": 220,
      "vmax": 470,
      "tags": ["coast"]
    },
    "pomfret": {
      "name": "银鲳",
      "tier": 3,
      "wmin": 0.2,
      "wmax": 1.5,
      "vmin": 230,
      "vmax": 480,
      "tags": ["coast"]
    },
    "grouper": {
      "name": "石斑鱼",
      "tier": 3,
      "wmin": 0.8,
      "wmax": 8,
      "vmin": 260,
      "vmax": 560,
      "tags": ["coast", "deep"]
    },
    "yellowcroaker": {
      "name": "大黄鱼",
      "tier": 3,
      "wmin": 0.3,
      "wmax": 3,
      "vmin": 300,
      "vmax": 580,
      "tags": ["coast"]
    },
    "chinese_sucker": {
      "name": "胭脂鱼",
      "tier": 3,
      "wmin": 1,
      "wmax": 6,
      "vmin": 260,
      "vmax": 540,
      "tags": ["river"]
    },
    "burbot": {
      "name": "江鳕",
      "tier": 3,
      "wmin": 1,
      "wmax": 8,
      "vmin": 240,
      "vmax": 500,
      "tags": ["river", "lake", "cold", "night"]
    },
    "manchurian_trout": {
      "name": "花羔红点鲑",
      "tier": 3,
      "wmin": 0.5,
      "wmax": 3,
      "vmin": 260,
      "vmax": 540,
      "tags": ["river", "stream", "cold"]
    },
    "amur_catfish": {
      "name": "怀头鲇",
      "tier": 3,
      "wmin": 2,
      "wmax": 20,
      "vmin": 240,
      "vmax": 520,
      "tags": ["lake", "deep", "night"]
    },
    "amberjack": {
      "name": "高体鰤",
      "tier": 3,
      "wmin": 2,
      "wmax": 15,
      "vmin": 260,
      "vmax": 560,
      "tags": ["coast", "deep"]
    },
    "cobia": {
      "name": "军曹鱼",
      "tier": 3,
      "wmin": 3,
      "wmax": 20,
      "vmin": 260,
      "vmax": 560,
      "tags": ["coast", "deep"]
    },
    "barramundi": {
      "name": "尖吻鲈",
      "tier": 3,
      "wmin": 1,
      "wmax": 8,
      "vmin": 240,
      "vmax": 500,
      "tags": ["coast"]
    },
    "miiuy_croaker": {
      "name": "鮸鱼",
      "tier": 3,
      "wmin": 1,
      "wmax": 8,
      "vmin": 240,
      "vmax": 500,
      "tags": ["coast"]
    },
    "koi": {
      "name": "锦鲤",
      "tier": 4,
      "wmin": 1,
      "wmax": 8,
      "vmin": 750,
      "vmax": 1600,
      "tags": ["river", "lake"]
    },
    "salmon": {
      "name": "大马哈鱼",
      "tier": 4,
      "wmin": 3,
      "wmax": 14,
      "vmin": 800,
      "vmax": 1700,
      "tags": ["river", "coast", "cold"]
    },
    "sturgeon": {
      "name": "施氏鲟",
      "tier": 4,
      "wmin": 5,
      "wmax": 30,
      "vmin": 900,
      "vmax": 1900,
      "tags": ["river", "lake", "deep"]
    },
    "taimen": {
      "name": "哲罗鲑",
      "tier": 4,
      "wmin": 3,
      "wmax": 50,
      "vmin": 1000,
      "vmax": 2200,
      "tags": ["river", "stream", "cold"]
    },
    "wels_catfish": {
      "name": "六须鲇",
      "tier": 4,
      "wmin": 5,
      "wmax": 100,
      "vmin": 850,
      "vmax": 2000,
      "tags": ["lake", "deep", "night"]
    },
    "tuna": {
      "name": "金枪鱼",
      "tier": 4,
      "wmin": 5,
      "wmax": 200,
      "vmin": 900,
      "vmax": 2000,
      "tags": ["coast", "deep"]
    },
    "giant_grouper": {
      "name": "龙趸石斑",
      "tier": 4,
      "wmin": 10,
      "wmax": 300,
      "vmin": 1000,
      "vmax": 2200,
      "tags": ["coast", "deep"]
    },
    "mahseer": {
      "name": "结鱼",
      "tier": 4,
      "wmin": 3,
      "wmax": 30,
      "vmin": 800,
      "vmax": 1800,
      "tags": ["river", "stream", "cold"]
    },
    "marbled_eel": {
      "name": "花鳗鲡",
      "tier": 4,
      "wmin": 2,
      "wmax": 20,
      "vmin": 800,
      "vmax": 1800,
      "tags": ["river", "lake", "night"]
    },
    "marlin": {
      "name": "马林鱼",
      "tier": 4,
      "wmin": 30,
      "wmax": 300,
      "vmin": 1000,
      "vmax": 2200,
      "tags": ["coast", "deep"]
    },
    "giant_trevally": {
      "name": "浪人鲹",
      "tier": 4,
      "wmin": 5,
      "wmax": 50,
      "vmin": 900,
      "vmax": 2000,
      "tags": ["coast", "deep"]
    },
    "mahimahi": {
      "name": "鲯鳅",
      "tier": 4,
      "wmin": 3,
      "wmax": 30,
      "vmin": 800,
      "vmax": 1800,
      "tags": ["coast", "deep"]
    },
    "swordfish": {
      "name": "剑鱼",
      "tier": 4,
      "wmin": 30,
      "wmax": 200,
      "vmin": 950,
      "vmax": 2100,
      "tags": ["coast", "deep"]
    },
    "wahoo": {
      "name": "刺鲅",
      "tier": 4,
      "wmin": 2,
      "wmax": 40,
      "vmin": 800,
      "vmax": 1800,
      "tags": ["coast", "deep"]
    },
    "chinese_sturgeon": {
      "name": "中华鲟",
      "tier": 5,
      "wmin": 20,
      "wmax": 300,
      "vmin": 4500,
      "vmax": 9500,
      "tags": ["river", "coast", "protected"]
    },
    "kaluga": {
      "name": "达氏鳇",
      "tier": 5,
      "wmin": 50,
      "wmax": 1000,
      "vmin": 5000,
      "vmax": 11000,
      "tags": ["river", "deep", "protected"]
    },
    "sailfish": {
      "name": "旗鱼",
      "tier": 5,
      "wmin": 20,
      "wmax": 90,
      "vmin": 5000,
      "vmax": 10000,
      "tags": ["coast", "deep"]
    },
    "paddlefish": {
      "name": "白鲟",
      "tier": 5,
      "wmin": 50,
      "wmax": 300,
      "vmin": 5000,
      "vmax": 11000,
      "tags": ["river", "protected"]
    },
    "coelacanth": {
      "name": "矛尾鱼",
      "tier": 5,
      "wmin": 30,
      "wmax": 90,
      "vmin": 6000,
      "vmax": 12000,
      "tags": ["coast", "deep"]
    },
    "oarfish": {
      "name": "皇带鱼",
      "tier": 5,
      "wmin": 50,
      "wmax": 200,
      "vmin": 5500,
      "vmax": 11000,
      "tags": ["coast", "deep", "night"]
    },
    "whale_shark": {
      "name": "鲸鲨",
      "tier": 5,
      "wmin": 200,
      "wmax": 1000,
      "vmin": 6000,
      "vmax": 13000,
      "tags": ["coast", "deep", "protected"]
    }
  };
  const HAS_ART = {
    "whitebait": true,
    "topmouth": true,
    "loach": true,
    "crucian": true,
    "bighead": false,
    "yellowhead": false,
    "bluegill": false,
    "icefish": false,
    "bitterling": false,
    "sardine": false,
    "filefish": false,
    "goby": false,
    "minnow": false,
    "zacco": false,
    "gudgeon": true,
    "spined_loach": false,
    "ricefish": false,
    "paradisefish": false,
    "anchovy": false,
    "halfbeak": false,
    "sandlance": false,
    "dace": true,
    "carp": true,
    "grass": true,
    "bream": true,
    "blackcarp": true,
    "perch": false,
    "catfish": false,
    "swampeel": false,
    "tilapia": false,
    "mackerel": false,
    "small_croaker": false,
    "mullet": false,
    "rockfish": false,
    "redeye": true,
    "wuchang": false,
    "spotted_steed": false,
    "bigscale_loach": false,
    "yellowtail_fish": false,
    "yellow_drum": false,
    "greenling": false,
    "haarder": false,
    "flathead_fish": false,
    "bass": true,
    "fangbream": true,
    "barbel": false,
    "culter": false,
    "mandarin": true,
    "largemouth": false,
    "seabass": false,
    "blackbream": false,
    "hairtail": false,
    "flounder": false,
    "conger": false,
    "pufferfish": false,
    "spinibarbus": false,
    "mongolian_redfin": false,
    "small_snakehead": false,
    "yellowfin_seabream": false,
    "crimson_snapper": false,
    "spotted_scat": false,
    "octopus": false,
    "squid": false,
    "cuttlefish": false,
    "snakehead": true,
    "trout": true,
    "pike": true,
    "zander": false,
    "longsnout": true,
    "lenok": true,
    "yellowcheek": false,
    "eel": false,
    "seabream": false,
    "spanish_mackerel": false,
    "pomfret": false,
    "grouper": false,
    "yellowcroaker": false,
    "chinese_sucker": false,
    "burbot": false,
    "manchurian_trout": false,
    "amur_catfish": false,
    "amberjack": false,
    "cobia": false,
    "barramundi": false,
    "miiuy_croaker": false,
    "koi": true,
    "salmon": true,
    "sturgeon": true,
    "taimen": true,
    "wels_catfish": false,
    "tuna": false,
    "giant_grouper": false,
    "mahseer": false,
    "marbled_eel": false,
    "marlin": true,
    "giant_trevally": false,
    "mahimahi": false,
    "swordfish": false,
    "wahoo": false,
    "chinese_sturgeon": true,
    "kaluga": true,
    "sailfish": false,
    "paddlefish": false,
    "coelacanth": true,
    "oarfish": true,
    "whale_shark": false
  };
  const GENERIC_BY_TIER = ["generic_tier0", "generic_tier1", "generic_tier2", "generic_tier3", "generic_tier4", "generic_tier5"];
  function artFor(id) {
    return HAS_ART[id] ? id : GENERIC_BY_TIER[FISH[id].tier];
  }
  function tierOf(id) {
    return FISH[id].tier;
  }
  function poolFor(spotId) {
    const want = SPOTS[spotId].habitat_tags;
    const out = [];
    for (const fid in FISH) {
      const tags = FISH[fid].tags || ["river"];
      if (want.some(t => tags.includes(t))) out.push(fid);
    }
    out.sort((a, b) => tierOf(a) !== tierOf(b) ? tierOf(a) - tierOf(b) : a < b ? -1 : 1);
    return out;
  }
  function weightsForRod(rodLevel) {
    const lv = rodLevel - 1;
    return {
      0: Math.max(16.0, BASE_WEIGHTS[0] - lv * 2.4),
      1: BASE_WEIGHTS[1] + lv * 0.7,
      2: BASE_WEIGHTS[2] + lv * 0.85,
      3: BASE_WEIGHTS[3] + lv * 0.50,
      4: BASE_WEIGHTS[4] + lv * 0.22,
      5: BASE_WEIGHTS[5] + lv * 0.05
    };
  }
  function idsOfTier(ids, tier) {
    if (tier < 0 || tier > 5) return [];
    return ids.filter(id => FISH[id].tier === tier);
  }
  function rollFish(weights, pool) {
    let total = 0;
    for (const r in weights) total += weights[r];
    let pick = Math.random() * total,
      tier = 0;
    for (const r in weights) {
      pick -= weights[r];
      if (pick <= 0) {
        tier = +r;
        break;
      }
    }
    const ids = pool && pool.length ? pool : Object.keys(FISH);
    let cands = idsOfTier(ids, tier);
    if (!cands.length) {
      for (let d = 1; d < 6; d++) {
        cands = idsOfTier(ids, tier - d);
        if (!cands.length) cands = idsOfTier(ids, tier + d);
        if (cands.length) break;
      }
    }
    if (!cands.length) cands = ids;
    return cands[Math.floor(Math.random() * cands.length)];
  }
  function rollQuality(baitIdx) {
    const probs = BAITS[Math.max(0, Math.min(BAITS.length - 1, baitIdx))].probs;
    let q = 0;
    for (let lvl = 1; lvl < probs.length; lvl++) {
      if (Math.random() < probs[lvl]) q = lvl;else break;
    }
    return q;
  }
  function rollVariant() {
    const r = Math.random();
    let acc = 0;
    for (let vi = VARIANT_PROBS.length - 1; vi > 0; vi--) {
      acc += VARIANT_PROBS[vi];
      if (r < acc) return vi;
    }
    return 0;
  }
  function lerp(a, b, t) {
    return a + (b - a) * t;
  }
  function rollCatch(rodLevel, baitIdx, luck, pool) {
    baitIdx = baitIdx || 0;
    luck = luck || 0;
    const id = rollFish(weightsForRod(rodLevel + luck), pool);
    const f = FISH[id];
    let k = Math.random();
    k = k * k;
    const w = lerp(f.wmin, f.wmax, k);
    let sr = 0;
    if (f.wmax > f.wmin) sr = (w - f.wmin) / (f.wmax - f.wmin);
    const base = lerp(f.vmin, f.vmax, sr);
    const rodMult = 1.0 + (rodLevel - 1) * 0.08;
    const jitter = 0.92 + Math.random() * 0.16;
    const q = rollQuality(baitIdx);
    const vr = rollVariant();
    return {
      id,
      w: Math.round(w * 100) / 100,
      v: Math.max(1, Math.round(base * rodMult * jitter * QUALITY_MULTS[q] * VARIANT_MULTS[vr])),
      q,
      var: vr
    };
  }
  function qualityLabel(q) {
    if (q <= 0) return "";
    return QUALITY_NAMES[q] + "★".repeat(q) + "·";
  }
  function variantLabel(v) {
    if (v <= 0) return "";
    return VARIANT_NAMES[v] + "·";
  }
  function sizeTag(id, w) {
    const f = FISH[id];
    if (f.wmax <= f.wmin) return "";
    const r = (w - f.wmin) / (f.wmax - f.wmin);
    if (r >= 0.95) return "巨物·";
    if (r >= 0.75) return "大·";
    return "";
  }
  function displayName(id) {
    return FISH[id].name;
  }
  function fullName(c) {
    return variantLabel(c.var) + qualityLabel(c.q) + sizeTag(c.id, c.w) + displayName(c.id);
  }
  function rodCost(rodLevel) {
    return Math.round(200.0 * Math.pow(2.0, rodLevel - 1));
  }
  return {
    TIER_NAMES,
    TIER_COLORS,
    QUALITY_NAMES,
    QUALITY_MULTS,
    VARIANT_NAMES,
    VARIANT_MULTS,
    VARIANT_COLORS,
    VARIANT_PROBS,
    BAITS,
    HOOKS,
    BAG_CAPS,
    BAG_COSTS,
    SPOTS,
    SPOT_ORDER,
    FISH,
    HAS_ART,
    GENERIC_BY_TIER,
    artFor,
    tierOf,
    poolFor,
    weightsForRod,
    rollCatch,
    qualityLabel,
    variantLabel,
    sizeTag,
    displayName,
    fullName,
    rodCost,
    rollVariant,
    rollQuality
  };
}();
})(); } catch (e) { __ds_ns.__errors.push({ path: "playable/data.js", error: String((e && e.message) || e) }); }

// playable/game.js
try { (() => {
// 角落垂钓 — game logic (state machine, economy, orders, dex, save). Numbers 1:1 with Godot source.
window.Game = function () {
  const D = window.GAMEDATA;
  const SAVE_KEY = "corner_fishing_play_v1";
  const DAILY_ORDER_MULT = 2.5;
  const MERCHANT_MULT = 1.5;
  const OVERFLOW_SELL_RATE = 0.5;

  // ---- state ----
  const G = {
    coins: 0,
    rodLevel: 1,
    bagLevel: 1,
    baitLevel: 0,
    hookLevel: 0,
    inventory: [],
    dex: {},
    /* id -> {count, variants:[bool*4], bestQ, bestW, bestV} */
    lifetimeCatches: 0,
    lifetimeCoins: 0,
    biggest: null,
    bestValue: 0,
    currentSpot: "river_bend",
    unlockedSpots: ["river_bend"],
    dailyOrder: null,
    achievements: {},
    petSteals: 0,
    autoCast: true
  };

  // runtime (not saved)
  let state = "idle"; // idle | wait | bite
  let stateT = 0;
  let merchant = {
    active: false,
    t: 0
  };
  let event = null; // {key,name,icon,t,wait,value,luck}
  let eventT = 0;
  let dayT = 0; // day-night cycle seconds
  const DAY_LEN = 180;
  const cb = {
    catch: [],
    state: [],
    toast: [],
    update: [],
    event: []
  };
  function on(ev, fn) {
    cb[ev].push(fn);
  }
  function emit(ev, ...a) {
    for (const fn of cb[ev]) fn(...a);
  }
  function toast(msg, color) {
    emit("toast", msg, color || "#ECE8E0");
  }

  // ---- day phase ----
  const PHASES = [{
    key: "dawn",
    name: "黎明",
    wait: 0.9,
    sky: "rgba(255,214,160,0.10)"
  }, {
    key: "day",
    name: "白昼",
    wait: 1.0,
    sky: "rgba(255,255,255,0)"
  }, {
    key: "dusk",
    name: "黄昏",
    wait: 0.85,
    sky: "rgba(255,150,90,0.12)"
  }, {
    key: "night",
    name: "夜晚",
    wait: 1.05,
    sky: "rgba(30,40,80,0.26)"
  }];
  function phase() {
    return PHASES[Math.floor(dayT / DAY_LEN * 4) % 4];
  }

  // ---- events ----
  const EVENTS = [{
    key: "fish_run",
    name: "鱼汛",
    icon: "event_fish_run",
    dur: 45,
    wait: 0.6,
    value: 1,
    luck: 1,
    msg: "鱼汛来了——咬钩频频，运气大涨"
  }, {
    key: "lucky_current",
    name: "幸运暗流",
    icon: "event_crate",
    dur: 50,
    wait: 1,
    value: 1.4,
    luck: 0,
    msg: "一股幸运暗流——这阵子鱼格外值钱"
  }, {
    key: "tide_in",
    name: "涨潮",
    icon: "event_tide",
    dur: 40,
    wait: 0.7,
    value: 1,
    luck: 0,
    msg: "潮水涌上来，鱼群活跃"
  }, {
    key: "morning_fog",
    name: "晨雾",
    icon: "event_fog",
    dur: 40,
    wait: 1.15,
    value: 1.25,
    luck: 0,
    msg: "晨雾弥漫，少有人扰，大鱼更舍得现身"
  }];

  // ---- helpers ----
  function bagCap() {
    return D.BAG_CAPS[Math.min(G.bagLevel - 1, D.BAG_CAPS.length - 1)];
  }
  function bagFull() {
    return G.inventory.length >= bagCap();
  }
  function bagCost() {
    return G.bagLevel - 1 < D.BAG_COSTS.length ? D.BAG_COSTS[G.bagLevel - 1] : null;
  }
  function rodCost() {
    return D.rodCost(G.rodLevel);
  }
  function spotPool() {
    return D.poolFor(G.currentSpot);
  }
  function speciesCount() {
    return Object.keys(G.dex).length;
  }
  function variantCount() {
    let n = 0;
    for (const id in G.dex) for (let v = 0; v < 4; v++) if (G.dex[id].variants && G.dex[id].variants[v]) n++;
    return n;
  }
  function valueMult() {
    let m = D.SPOTS[G.currentSpot].value_mult;
    m *= phase().wait === 0.85 ? 1 : 1; // (phase doesn't change value)
    if (event) m *= event.value;
    if (merchant.active) m *= MERCHANT_MULT;
    return m;
  }

  // ---- fishing loop ----
  function beginWait() {
    if (bagFull()) {
      state = "idle";
      emit("state", "idle");
      return;
    }
    state = "wait";
    emit("state", "wait");
    let w = (3.5 + Math.random() * 3.5) * Math.max(0.4, 1 - (G.rodLevel - 1) * 0.06);
    w *= D.SPOTS[G.currentSpot].wait_mult;
    w *= phase().wait;
    if (event) w *= event.wait;
    stateT = w;
  }
  function beginBite() {
    state = "bite";
    emit("state", "bite");
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
    state = "idle";
    emit("state", "idle");
    if (caught.length) emit("catch", caught);
    checkAchievements();
    emit("update");
    save();
    // continue idle loop
    if (G.autoCast) setTimeout(() => {
      if (state === "idle") beginWait();
    }, 650);
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
    if (!G.biggest || c.w > G.biggest.w) G.biggest = {
      id: c.id,
      w: c.w,
      name: D.displayName(c.id)
    };
    return c;
  }
  function recordDex(c) {
    if (!G.dex[c.id]) G.dex[c.id] = {
      count: 0,
      variants: [false, false, false, false],
      bestQ: 0,
      bestW: 0,
      bestV: 0
    };
    const d = G.dex[c.id];
    d.count++;
    d.variants[c.var] = true;
    d.bestQ = Math.max(d.bestQ, c.q);
    d.bestW = Math.max(d.bestW, c.w);
    d.bestV = Math.max(d.bestV, c.v);
  }

  // manual: start fishing if idle
  function cast() {
    if (state === "idle") {
      if (bagFull()) {
        toast("鱼篓满了，先去鱼篓兑换吧", "#FFC773");
        return;
      }
      beginWait();
    } else if (state === "bite") reel();
  }

  // ---- selling ----
  function sellOne(uid) {
    const i = G.inventory.findIndex(c => c.uid === uid);
    if (i < 0) return;
    const c = G.inventory[i];
    if (c.lock) {
      toast("这条被你珍藏了", "#C7BDA8");
      return;
    }
    G.inventory.splice(i, 1);
    G.coins += c.v;
    G.lifetimeCoins += c.v;
    toast(`卖出「${c.name}」 +${c.v}`, "#FAD166");
    checkAchievements();
    emit("update");
    save();
  }
  function sellAll(keepLocked) {
    let total = 0,
      n = 0;
    G.inventory = G.inventory.filter(c => {
      if (c.lock) return true;
      total += c.v;
      n++;
      return false;
    });
    if (!n) {
      toast("没有可兑换的鱼", "#C7BDA8");
      return;
    }
    G.coins += total;
    G.lifetimeCoins += total;
    toast(`满篓兑换 ${n} 条 +${total}`, "#FAD166");
    checkAchievements();
    emit("update");
    save();
    if (G.autoCast && state === "idle") beginWait();
  }
  function toggleLock(uid) {
    const c = G.inventory.find(x => x.uid === uid);
    if (!c) return;
    c.lock = !c.lock;
    emit("update");
    save();
  }

  // ---- upgrades ----
  function upgradeRod() {
    const cost = rodCost();
    if (G.coins < cost) {
      toast("金币不够", "#FF8C7A");
      return;
    }
    G.coins -= cost;
    G.rodLevel++;
    toast(`鱼竿升到 Lv.${G.rodLevel}！`, "#8CD9F2");
    checkAchievements();
    emit("update");
    save();
  }
  function upgradeBag() {
    const cost = bagCost();
    if (cost == null) {
      toast("鱼篓已满级", "#C7BDA8");
      return;
    }
    if (G.coins < cost) {
      toast("金币不够", "#FF8C7A");
      return;
    }
    G.coins -= cost;
    G.bagLevel++;
    toast(`鱼篓扩到 ${bagCap()} 格！`, "#8CD9F2");
    checkAchievements();
    emit("update");
    save();
  }
  function buyBait(idx) {
    if (idx <= G.baitLevel) {
      setBait(idx);
      return;
    }
    const cost = D.BAITS[idx].cost;
    if (G.coins < cost) {
      toast("金币不够", "#FF8C7A");
      return;
    }
    G.coins -= cost;
    G.baitLevel = idx;
    toast(`换上「${D.BAITS[idx].name}」`, "#8CD9F2");
    checkAchievements();
    emit("update");
    save();
  }
  function setBait(idx) {
    if (idx <= G.baitLevel) {
      G.baitLevel = idx;
      emit("update");
      save();
    }
  }
  function buyHook(idx) {
    if (idx <= G.hookLevel) {
      G.hookLevel = idx;
      emit("update");
      save();
      return;
    }
    const cost = D.HOOKS[idx].cost;
    if (G.coins < cost) {
      toast("金币不够", "#FF8C7A");
      return;
    }
    G.coins -= cost;
    G.hookLevel = idx;
    toast(`换上「${D.HOOKS[idx].name}」`, "#8CD9F2");
    checkAchievements();
    emit("update");
    save();
  }

  // ---- spots ----
  function spotUnlocked(id) {
    const s = D.SPOTS[id];
    if (!s.unlock) return true;
    if (s.unlock.kind === "catches") return G.lifetimeCatches >= s.unlock.n;
    if (s.unlock.kind === "coins") return G.lifetimeCoins >= s.unlock.n;
    if (s.unlock.kind === "species") return speciesCount() >= s.unlock.n;
    return false;
  }
  function unlockText(id) {
    const s = D.SPOTS[id];
    if (!s.unlock) return "";
    const k = s.unlock;
    if (k.kind === "catches") return `累计钓到 ${k.n} 条鱼解锁（当前 ${G.lifetimeCatches}）`;
    if (k.kind === "coins") return `累计赚 ${k.n} 金币解锁`;
    if (k.kind === "species") return `图鉴收集 ${k.n} 种解锁`;
    return "";
  }
  function switchSpot(id) {
    if (!spotUnlocked(id)) {
      toast(unlockText(id), "#FFC773");
      return false;
    }
    G.currentSpot = id;
    state = "idle";
    if (!G.unlockedSpots.includes(id)) G.unlockedSpots.push(id);
    emit("update");
    save();
    if (G.autoCast) beginWait();
    return true;
  }

  // ---- daily order ----
  function todayKey() {
    const d = new Date();
    return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
  }
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
    const o = {
      date,
      kind,
      fish,
      done: false,
      need: 1,
      tier: 1,
      minw: 1.0
    };
    if (kind === "tier") {
      o.tier = 1 + Math.floor(Math.random() * maxTier);
      o.need = Math.max(1, Math.min(3, 4 - o.tier));
    } else if (kind === "weight") {
      o.minw = [1, 2, 3][Math.floor(Math.random() * 3)];
      o.need = 1 + Math.floor(Math.random() * 2);
    } else if (kind === "perfect") {
      o.need = 1;
    } else {
      const t = D.tierOf(fish);
      o.need = t === 0 ? 3 + Math.floor(Math.random() * 3) : t === 1 ? 2 + Math.floor(Math.random() * 2) : t === 2 ? 1 + Math.floor(Math.random() * 2) : 1;
    }
    return o;
  }
  function orderMatches(c) {
    const o = G.dailyOrder;
    if (!o) return false;
    if (o.kind === "tier") return D.tierOf(c.id) >= o.tier;
    if (o.kind === "weight") return c.w >= o.minw;
    if (o.kind === "perfect") return c.q >= 3;
    return c.id === o.fish;
  }
  function orderTitle() {
    const o = G.dailyOrder;
    if (!o) return "";
    if (o.kind === "tier") return `收 ${o.need} 条 ${D.TIER_NAMES[o.tier]}及以上`;
    if (o.kind === "weight") return `收 ${o.need} 条 ≥${o.minw.toFixed(1)}kg 的鱼`;
    if (o.kind === "perfect") return `收 ${o.need} 条 完美★★★ 渔获`;
    return `收 ${o.need} 条 ${D.displayName(o.fish)}`;
  }
  function orderMatchIndices() {
    return G.inventory.map((c, i) => ({
      c,
      i
    })).filter(x => orderMatches(x.c) && !x.c.lock).sort((a, b) => b.c.v - a.c.v).map(x => x.i);
  }
  function orderReward(idxs) {
    const o = G.dailyOrder;
    let total = 0;
    for (let k = 0; k < Math.min(o.need, idxs.length); k++) total += G.inventory[idxs[k]].v;
    let mult = DAILY_ORDER_MULT;
    if (merchant.active) mult *= MERCHANT_MULT;
    return Math.ceil(total * mult);
  }
  function completeOrder() {
    ensureOrder();
    const o = G.dailyOrder;
    if (o.done) {
      toast("今日订单已完成", "#C7BDA8");
      return;
    }
    const idxs = orderMatchIndices();
    if (idxs.length < o.need) {
      toast("目标鱼还不够", "#FF8C7A");
      return;
    }
    const reward = orderReward(idxs);
    const chosen = idxs.slice(0, o.need).sort((a, b) => b - a);
    for (const i of chosen) G.inventory.splice(i, 1);
    G.coins += reward;
    G.lifetimeCoins += reward;
    o.done = true;
    toast(`订单完成：+${reward} 金币${merchant.active ? "（鱼贩×1.5）" : ""}`, "#FAD166");
    checkAchievements();
    emit("update");
    save();
  }

  // ---- achievements ----
  const ACH = [{
    id: "first",
    name: "第一竿",
    desc: "钓到第一条鱼",
    test: () => G.lifetimeCatches >= 1
  }, {
    id: "c50",
    name: "小有渔获",
    desc: "累计钓到 50 条",
    test: () => G.lifetimeCatches >= 50
  }, {
    id: "c300",
    name: "钓界常客",
    desc: "累计钓到 300 条",
    test: () => G.lifetimeCatches >= 300
  }, {
    id: "rich",
    name: "万贯家财",
    desc: "累计赚 10000 金币",
    test: () => G.lifetimeCoins >= 10000
  }, {
    id: "rod5",
    name: "趁手好竿",
    desc: "鱼竿升到 Lv.5",
    test: () => G.rodLevel >= 5
  }, {
    id: "dex20",
    name: "见多识广",
    desc: "图鉴收集 20 种",
    test: () => speciesCount() >= 20
  }, {
    id: "dex50",
    name: "鱼谱过半",
    desc: "图鉴收集 50 种",
    test: () => speciesCount() >= 50
  }, {
    id: "epic",
    name: "史诗时刻",
    desc: "钓到史诗及以上的鱼",
    test: () => Object.keys(G.dex).some(id => D.tierOf(id) >= 3)
  }, {
    id: "mythic",
    name: "国宝现身",
    desc: "钓到神话级的鱼",
    test: () => Object.keys(G.dex).some(id => D.tierOf(id) >= 5)
  }, {
    id: "gild",
    name: "鎏金一瞬",
    desc: "钓到鎏金或七彩变体",
    test: () => variantCount() > 0 && Object.values(G.dex).some(d => d.variants[2] || d.variants[3])
  }, {
    id: "perfect",
    name: "完美主义",
    desc: "钓到完美★★★ 渔获",
    test: () => Object.values(G.dex).some(d => d.bestQ >= 3)
  }, {
    id: "allspots",
    name: "走遍水岸",
    desc: "解锁全部钓点",
    test: () => D.SPOT_ORDER.every(spotUnlocked)
  }];
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
    const dt = Math.min(0.25, (now - last) / 1000);
    last = now;
    dayT = (dayT + dt) % DAY_LEN;
    // fishing state
    if (state === "wait") {
      stateT -= dt;
      if (stateT <= 0) beginBite();
    } else if (state === "bite") {
      stateT -= dt;
      if (stateT <= 0) reel();
    }
    // merchant
    merchant.t -= dt;
    if (merchant.t <= 0) {
      merchant.active = !merchant.active;
      merchant.t = merchant.active ? 60 + Math.random() * 30 : 240 + Math.random() * 240;
      if (merchant.active) {
        toast("🐟 流动鱼贩来了！卖价 ×1.5", "#FAD166");
      }
      emit("update");
    }
    // events
    if (event) {
      eventT -= dt;
      if (eventT <= 0) {
        event = null;
        emit("event");
        emit("update");
      }
    } else {
      eventT -= dt;
      if (eventT <= 0) {
        const pool = EVENTS.filter(e => e.key !== "tide_in" || G.currentSpot === "coast_pier");
        const e = pool[Math.floor(Math.random() * pool.length)];
        event = e;
        eventT = e.dur;
        toast("✦ " + e.msg, "#8CD9F2");
        emit("event");
        emit("update");
      }
    }
  }

  // ---- save / load ----
  function save() {
    if (!G._loaded) return;
    try {
      localStorage.setItem(SAVE_KEY, JSON.stringify({
        coins: G.coins,
        rodLevel: G.rodLevel,
        bagLevel: G.bagLevel,
        baitLevel: G.baitLevel,
        hookLevel: G.hookLevel,
        inventory: G.inventory,
        dex: G.dex,
        lifetimeCatches: G.lifetimeCatches,
        lifetimeCoins: G.lifetimeCoins,
        biggest: G.biggest,
        bestValue: G.bestValue,
        currentSpot: G.currentSpot,
        unlockedSpots: G.unlockedSpots,
        dailyOrder: G.dailyOrder,
        achievements: G.achievements,
        autoCast: G.autoCast
      }));
    } catch (e) {}
  }
  function load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (raw) Object.assign(G, JSON.parse(raw));
    } catch (e) {}
    G._loaded = true;
    // sanity
    if (!G.unlockedSpots.includes("river_bend")) G.unlockedSpots.push("river_bend");
    for (const c of G.inventory) {
      if (!c.uid) c.uid = Math.random().toString(36).slice(2);
      if (!c.art) c.art = D.artFor(c.id);
      if (c.tier == null) c.tier = D.tierOf(c.id);
      c.tierColor = D.TIER_COLORS[c.tier];
      c.varColor = D.VARIANT_COLORS[c.var];
      if (!c.name) c.name = D.fullName(c);
    }
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
    G,
    on,
    start,
    cast,
    reel,
    sellOne,
    sellAll,
    toggleLock,
    upgradeRod,
    upgradeBag,
    buyBait,
    setBait,
    buyHook,
    switchSpot,
    spotUnlocked,
    unlockText,
    completeOrder,
    reset,
    // getters
    bagCap,
    bagFull,
    bagCost,
    rodCost,
    spotPool,
    speciesCount,
    variantCount,
    orderTitle,
    orderMatches,
    orderMatchIndices,
    orderReward,
    phase,
    getEvent: () => event,
    getMerchant: () => merchant,
    getState: () => state,
    ACH,
    get autoCast() {
      return G.autoCast;
    },
    set autoCast(v) {
      G.autoCast = v;
      save();
      if (v && state === "idle") beginWait();
    }
  };
}();
})(); } catch (e) { __ds_ns.__errors.push({ path: "playable/game.js", error: String((e && e.message) || e) }); }

// playable/scene.js
try { (() => {
// 角落垂钓 — canvas scene renderer (520×400 art space, 1:1 with Godot main.gd)
window.Scene = function () {
  const ART = {
    w: 520,
    h: 400
  };
  let canvas,
    ctx,
    dpr = 1;
  let A = {}; // loaded images
  let spot = "river_bend";
  let bite = [300, 322];
  let state = "wait"; // wait | bite | reel
  let t = 0; // global time (s)
  let dip = 0; // 0 idle .. 1 fully dipped
  let ripples = []; // {x,y,r,max,a}
  let flyers = []; // catch sprites in flight {img,x,y,vx,vy,t,life,scale,tier,onland}
  let splashFlash = 0;
  let last = performance.now();

  // fisher composite (flipped to face left toward the water)
  const FISHER = {
    dx: 332,
    dy: 214,
    w: 188,
    h: 188,
    scale: 1
  };
  const ROD_TIP = {
    x: 380,
    y: 236
  }; // approx rod tip after horizontal flip

  function img(name) {
    return A[name];
  }
  function init(c, assets) {
    canvas = c;
    A = assets;
    ctx = canvas.getContext("2d");
    resize();
    window.addEventListener("resize", resize);
    last = performance.now();
    setInterval(step, 1000 / 30);
  }
  function resize() {
    dpr = Math.min(2, window.devicePixelRatio || 1);
    const rect = canvas.getBoundingClientRect();
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
  }
  function setSpot(id, biteXY) {
    spot = id;
    if (biteXY) bite = biteXY;
    ripples = [];
  }
  function setState(s) {
    state = s;
    if (s === "bite") {
      addRipple(bite[0], bite[1], 26);
      setTimeout(() => addRipple(bite[0], bite[1], 34), 140);
    }
  }
  function addRipple(x, y, max) {
    ripples.push({
      x,
      y,
      r: 6,
      max,
      a: 0.55
    });
  }
  function splash() {
    splashFlash = 1;
    addRipple(bite[0], bite[1], 30);
  }

  // launch a caught fish from the bobber toward the basket (bottom-right)
  function playCatch(c, onArrive) {
    splash();
    const start = {
      x: bite[0],
      y: bite[1]
    };
    const target = {
      x: 452,
      y: 372
    };
    const f = {
      img: img(c.art),
      x: start.x,
      y: start.y,
      t: 0,
      life: 0.85,
      sx: start.x,
      sy: start.y,
      tx: target.x,
      ty: target.y,
      tier: c.tier,
      varc: c.varColor,
      onArrive
    };
    flyers.push(f);
  }
  function step() {
    const now = performance.now();
    const dt = Math.min(0.06, (now - last) / 1000);
    last = now;
    t += dt;
    // ease dip toward target
    const target = state === "bite" ? 1 : 0;
    dip += (target - dip) * Math.min(1, dt * (state === "bite" ? 10 : 6));
    // ripples
    for (const r of ripples) {
      r.r += dt * 42;
      r.a -= dt * 0.5;
    }
    ripples = ripples.filter(r => r.a > 0.02 && r.r < r.max);
    if (splashFlash > 0) splashFlash = Math.max(0, splashFlash - dt * 2.2);
    // flyers
    for (const f of flyers) {
      f.t += dt;
      const p = Math.min(1, f.t / f.life);
      const e = 1 - Math.pow(1 - p, 2);
      f.x = f.sx + (f.tx - f.sx) * e;
      const arc = Math.sin(p * Math.PI) * 70; // arc upward
      f.y = f.sy + (f.ty - f.sy) * e - arc;
      if (p >= 1 && !f._done) {
        f._done = true;
        if (f.onArrive) f.onArrive();
      }
    }
    flyers = flyers.filter(f => f.t < f.life + 0.05);
    render();
  }
  function render() {
    if (!ctx) return;
    const W = canvas.width,
      H = canvas.height;
    ctx.clearRect(0, 0, W, H);
    ctx.save();
    // map art space to canvas (contain)
    const sx = W / ART.w,
      sy = H / ART.h,
      s = Math.min(sx, sy);
    ctx.translate((W - ART.w * s) / 2, (H - ART.h * s) / 2);
    ctx.scale(s, s);

    // background scene
    const bg = img(spot);
    if (bg) ctx.drawImage(bg, 0, 0, ART.w, ART.h);

    // animated water shimmer
    const wh = img("water_highlight_overlay");
    if (wh) {
      ctx.save();
      ctx.globalAlpha = 0.28 + 0.12 * Math.sin(t * 1.3);
      const drift = Math.sin(t * 0.6) * 8;
      ctx.drawImage(wh, bite[0] - 130 + drift, bite[1] - 30, 260, 110);
      ctx.restore();
    }

    // ripples
    ctx.save();
    ctx.lineWidth = 1.4;
    for (const r of ripples) {
      ctx.strokeStyle = `rgba(231,228,220,${r.a})`;
      ctx.beginPath();
      ctx.ellipse(r.x, r.y, r.r, r.r * 0.42, 0, 0, Math.PI * 2);
      ctx.stroke();
    }
    ctx.restore();

    // fishing line + bobber
    const bob = bobberPos();
    ctx.save();
    ctx.strokeStyle = "rgba(40,44,46,0.5)";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(ROD_TIP.x, ROD_TIP.y);
    ctx.lineTo(bob.x, bob.y - 8);
    ctx.stroke();
    ctx.restore();
    const bobImg = state === "bite" ? img("bobber_bite") : img("bobber_idle");
    if (bobImg) {
      const bs = state === "bite" ? 34 : 30;
      ctx.drawImage(bobImg, bob.x - bs / 2, bob.y - bs + 6, bs, bs);
    }

    // fisher (flipped horizontally to face the water)
    const pose = state === "reel" ? img("fisher_pull_02") || img("fisher_idle") : dip > 0.5 ? img("fisher_pull_01") || img("fisher_idle") : img("fisher_idle");
    if (pose) {
      ctx.save();
      ctx.translate(FISHER.dx + FISHER.w, FISHER.dy);
      ctx.scale(-1, 1);
      const breathe = Math.sin(t * 1.6) * 1.2;
      ctx.drawImage(pose, 0, breathe, FISHER.w, FISHER.h);
      ctx.restore();
    }

    // flyers (caught fish arcing to basket)
    for (const f of flyers) {
      if (!f.img) continue;
      const fade = f.t > f.life * 0.8 ? Math.max(0, 1 - (f.t - f.life * 0.8) / (f.life * 0.2)) : 1;
      const sc = 0.5 + 0.18 * Math.sin(Math.min(1, f.t / f.life) * Math.PI);
      const fw = 64 * sc,
        fh = 64 * sc;
      ctx.save();
      ctx.globalAlpha = fade;
      if (f.tier >= 4) {
        ctx.shadowColor = f.varc && f.varc !== "#ffffff" ? f.varc : "#FFD659";
        ctx.shadowBlur = 16;
      }
      ctx.drawImage(f.img, f.x - fw / 2, f.y - fh / 2, fw, fh);
      ctx.restore();
    }
    ctx.restore();
  }
  function bobberPos() {
    const bobAmt = state === "bite" ? 6 + dip * 10 : 3;
    const y = bite[1] + Math.sin(t * 2.1) * (state === "bite" ? 1.2 : 2.6) + dip * 10;
    const x = bite[0] + Math.sin(t * 0.9) * 1.5;
    return {
      x,
      y
    };
  }
  return {
    init,
    setSpot,
    setState,
    playCatch,
    splash,
    addRipple,
    ART
  };
}();
})(); } catch (e) { __ds_ns.__errors.push({ path: "playable/scene.js", error: String((e && e.message) || e) }); }

// playable/ui.js
try { (() => {
// 角落垂钓 — UI layer: asset loading, HUD, panels, catch popup, toasts.
(function () {
  const D = window.GAMEDATA,
    Sc = window.Scene,
    Gm = window.Game,
    G = Gm.G;
  const $ = id => document.getElementById(id);

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
    const m = manifest();
    const keys = Object.keys(m);
    let done = 0;
    if (!keys.length) return cb();
    for (const k of keys) {
      const img = new Image();
      img.onload = img.onerror = () => {
        if (++done === keys.length) cb();
      };
      img.src = BASE + m[k];
      ASSET[k] = img;
    }
  }
  const A = k => ASSET[k];

  // ---------- formatting ----------
  function coinStr(n) {
    return n >= 10000 ? (n / 1000).toFixed(n >= 100000 ? 0 : 1) + "k" : n.toLocaleString();
  }
  function wStr(w) {
    return w >= 1 ? w.toFixed(2) + "kg" : Math.round(w * 1000) + "g";
  }
  function tierColor(t) {
    return D.TIER_COLORS[t];
  }
  function tierName(t) {
    return D.TIER_NAMES[t];
  }

  // ---------- HUD ----------
  function renderHud() {
    const cap = Gm.bagCap(),
      n = G.inventory.length;
    $("hud").innerHTML = `<div class="chip coin"><img src="${BASE}ui/icon_coin.png" alt="">${coinStr(G.coins)}</div>` + `<div class="chip ${n >= cap ? "warn" : ""}"><img src="${BASE}equipment/fish_basket.png" alt="">${n}/${cap}</div>` + `<div class="chip"><img src="${BASE}ui/icon_dex.png" alt="">${Gm.speciesCount()}/${Object.keys(D.FISH).length}</div>`;
  }
  function renderTopRight() {
    const ph = Gm.phase();
    const ev = Gm.getEvent();
    const mc = Gm.getMerchant();
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
    const b = $("action");
    b.className = "action";
    if (Gm.bagFull() && st !== "bite") {
      b.textContent = "鱼篓满了 · 去兑换";
      b.classList.add("full");
      return;
    }
    if (st === "bite") {
      b.textContent = "起钩！";
      b.classList.add("bite");
    } else if (st === "wait") {
      b.textContent = "· 等待咬钩 ·";
      b.classList.add("wait");
    } else {
      b.textContent = G.autoCast ? "自动垂钓中" : "起竿";
      if (G.autoCast) b.classList.add("wait");
    }
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
    pop.innerHTML = `<div class="catch-card" style="border-color:${c.tierColor}">` + `<div class="pill" style="background:${c.tierColor};color:#1a1a1a">${tierName(c.tier)}</div>` + `<img src="${BASE}fish/${c.art}.png" alt="">` + `<div class="catch-name">${c.name}</div>` + `<div class="catch-meta">${metaBits.join(" · ")}</div>` + `<div class="catch-val">+${c.v} 金币</div>${extra}</div>`;
    pop.classList.add("show");
    clearTimeout(popTimer);
    popTimer = setTimeout(() => pop.classList.remove("show"), 1700);
  }

  // ---------- toasts ----------
  function showToast(msg, color) {
    const t = document.createElement("div");
    t.className = "toast";
    t.style.color = color;
    t.textContent = msg;
    $("toasts").appendChild(t);
    setTimeout(() => {
      t.style.opacity = "0";
      t.style.transition = "opacity .4s";
      setTimeout(() => t.remove(), 400);
    }, 2200);
    while ($("toasts").children.length > 3) $("toasts").firstChild.remove();
  }

  // ---------- nav ----------
  // Quiet hairline glyphs (currentColor) — painterly world deserves no emoji.
  const SVG = {
    basket: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8q4-4.6 8 0"/><path d="M4.2 8h11.6l-1.5 8H5.7z"/><path d="M8.2 8l-.6 8M11.8 8l.6 8"/></svg>`,
    equip: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M5 15.6L14.6 5"/><circle cx="6.4" cy="13.9" r="1.15"/><path d="M14.6 5l.4 4.1"/><path d="M15 9.1q1.5.5.2 2"/></svg>`,
    dex: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M10 6v9.4"/><path d="M10 6C8.3 4.9 5.9 4.9 4.1 5.7V15c1.8-.8 4.2-.8 5.9.4"/><path d="M10 6c1.7-1.1 4.1-1.1 5.9-.3V15c-1.8-.8-4.2-.8-5.9.4"/></svg>`,
    orders: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><rect x="4.8" y="4.4" width="10.4" height="11.4" rx="2"/><path d="M7.6 8.4h4.8"/><path d="M7.6 11.6l1.4 1.4 3-3.2"/></svg>`,
    spots: `<svg viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.45" stroke-linecap="round" stroke-linejoin="round"><path d="M10 16.5s4.8-4.7 4.8-8.4a4.8 4.8 0 1 0-9.6 0c0 3.7 4.8 8.4 4.8 8.4z"/><circle cx="10" cy="8.1" r="1.7"/></svg>`
  };
  const NAV = [{
    id: "basket",
    label: "鱼篓"
  }, {
    id: "equip",
    label: "装备"
  }, {
    id: "dex",
    label: "图鉴"
  }, {
    id: "orders",
    label: "任务"
  }, {
    id: "spots",
    label: "钓点"
  }];
  function renderNav() {
    const orderReady = (() => {
      const o = G.dailyOrder;
      return o && !o.done && Gm.orderMatchIndices().length >= o.need;
    })();
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
  function closePanel() {
    curPanel = null;
    $("sheet").classList.remove("open");
    renderNav();
  }
  function renderPanel() {
    if (!curPanel) return;
    const map = {
      basket: renderBasket,
      equip: renderEquip,
      dex: renderDex,
      orders: renderOrders,
      spots: renderSpots
    };
    (map[curPanel] || (() => {}))();
  }

  // --- basket ---
  let basketSort = "new"; // new | value | tier
  function renderBasket() {
    $("sheetTitle").textContent = "鱼篓";
    $("sheetSub").textContent = `${G.inventory.length}/${Gm.bagCap()}`;
    const body = $("sheetBody");
    let inv = G.inventory.map((c, i) => ({
      c,
      i
    }));
    if (basketSort === "value") inv.sort((a, b) => b.c.v - a.c.v);else if (basketSort === "tier") inv.sort((a, b) => b.c.tier - a.c.tier || b.c.v - a.c.v);else inv.reverse();
    const sellableTotal = G.inventory.filter(c => !c.lock).reduce((s, c) => s + c.v, 0);
    let html = `<div class="seg">
      ${["new", "value", "tier"].map(s => `<div class="tab ${basketSort === s ? "on" : ""}" data-sort="${s}">${{
      new: "最新",
      value: "价值",
      tier: "品阶"
    }[s]}</div>`).join("")}
      <div style="flex:1"></div>
      <button class="btn" id="sellAll" ${sellableTotal ? "" : "disabled"}>全部兑换 +${coinStr(sellableTotal)}</button>
    </div>`;
    if (!G.inventory.length) html += `<div class="empty">鱼篓还是空的，<br>等浮漂动一动吧。</div>`;else {
      html += `<div class="bgrid">` + inv.map(({
        c,
        i
      }) => `<div class="fishcell" data-uid="${c.uid}" style="border-color:${c.var > 0 ? c.varColor : c.tierColor}">
          ${c.lock ? '<span class="lock">🔒</span>' : ''}
          <img src="${BASE}fish/${c.art}.png" alt="">
          <div class="fn" style="color:${c.var > 0 ? c.varColor : 'var(--text-on-glass)'}">${c.name}</div>
          <div class="fv">${coinStr(c.v)}</div>
        </div>`).join("") + `</div>`;
    }
    body.innerHTML = html;
    body.querySelectorAll(".tab").forEach(t => t.onclick = () => {
      basketSort = t.dataset.sort;
      renderBasket();
    });
    const sa = $("sellAll");
    if (sa) sa.onclick = () => Gm.sellAll();
    body.querySelectorAll(".fishcell").forEach(el => el.onclick = () => openFishMenu(el.dataset.uid));
  }
  function openFishMenu(uid) {
    const c = G.inventory.find(x => x.uid === uid);
    if (!c) return;
    // quick action: lock toggle on shift, else sell with confirm-less (it's a game)
    const action = window.confirm(`「${c.name}」 ${wStr(c.w)} · 价值 ${c.v}\n\n确定 = 兑换为金币\n取消 = ${c.lock ? "取消珍藏" : "珍藏（不被全部兑换）"}`);
    if (action) Gm.sellOne(uid);else Gm.toggleLock(uid);
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
      ${bc == null ? '<span class="pill" style="background:var(--glass-row);color:var(--text-muted-glass)">已满级</span>' : `<button class="btn" data-act="bag" ${G.coins < bc ? "disabled" : ""}>扩容<br>${coinStr(bc)}</button>`}
    </div>`;
    // bait
    html += `<div style="font-size:12px;color:var(--text-muted-glass);margin:14px 0 7px;font-weight:600">鱼饵 · 决定星级品质（卖价倍率）</div>`;
    D.BAITS.forEach((b, i) => {
      const owned = i <= G.baitLevel,
        eq = i === G.baitLevel;
      html += `<div class="row" style="${eq ? 'border-color:var(--gold)' : ''}">
        <img class="thumb" src="${BASE}equipment/bait_jar.png" alt="">
        <div class="grow"><div class="nm">${b.name} ${eq ? '<span class="pill" style="background:var(--gold);color:#2a2a1a">使用中</span>' : ''}</div>
        <div class="sub">${b.desc} · 上品率 ${(b.probs[1] * 100).toFixed(0)}%</div></div>
        ${eq ? '' : owned ? `<button class="btn sec" data-bait="${i}">换上</button>` : `<button class="btn" data-bait="${i}" ${G.coins < b.cost ? "disabled" : ""}>${coinStr(b.cost)}</button>`}
      </div>`;
    });
    // hook
    html += `<div style="font-size:12px;color:var(--text-muted-glass);margin:14px 0 7px;font-weight:600">鱼钩 · 决定双钩几率（一次两条）</div>`;
    D.HOOKS.forEach((h, i) => {
      const owned = i <= G.hookLevel,
        eq = i === G.hookLevel;
      html += `<div class="row" style="${eq ? 'border-color:var(--gold)' : ''}">
        <img class="thumb" src="${BASE}equipment/hook_basic.png" alt="">
        <div class="grow"><div class="nm">${h.name} ${eq ? '<span class="pill" style="background:var(--gold);color:#2a2a1a">使用中</span>' : ''}</div>
        <div class="sub">${h.desc} · 双钩 ${(h.double * 100).toFixed(0)}%</div></div>
        ${eq ? '' : owned ? `<button class="btn sec" data-hook="${i}">换上</button>` : `<button class="btn" data-hook="${i}" ${G.coins < h.cost ? "disabled" : ""}>${coinStr(h.cost)}</button>`}
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
      const d = G.dex[id],
        seen = !!d;
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
    body.querySelectorAll(".tab").forEach(t => t.onclick = () => {
      dexTier = +t.dataset.t;
      renderDex();
    });
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
        ${o.done ? '<span class="pill" style="background:var(--positive);color:#0e1a0e">完成</span>' : `<button class="btn" id="doOrder" ${ready ? "" : "disabled"}>交付</button>`}
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
    const dO = $("doOrder");
    if (dO) dO.onclick = () => Gm.completeOrder();
    $("resetBtn").onclick = () => {
      if (confirm("确定清空所有进度，从头开始？")) Gm.reset();
    };
  }

  // --- spots ---
  function renderSpots() {
    $("sheetTitle").textContent = "钓点";
    $("sheetSub").textContent = "";
    const body = $("sheetBody");
    let html = "";
    for (const id of D.SPOT_ORDER) {
      const s = D.SPOTS[id];
      const unlocked = Gm.spotUnlocked(id);
      const active = id === G.currentSpot;
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
      if (Gm.switchSpot(id)) {
        Sc.setSpot(id, D.SPOTS[id].bite);
        closePanel();
      }
    });
  }

  // ---------- wire up ----------
  function refreshAll() {
    renderHud();
    renderTopRight();
    renderNav();
    renderAction(Gm.getState());
    if (curPanel) renderPanel();
  }
  function boot() {
    Sc.init($("scene"), ASSET);
    Sc.setSpot(G.currentSpot, D.SPOTS[G.currentSpot].bite);
    Gm.on("update", refreshAll);
    Gm.on("event", () => {
      renderTopRight();
      renderNav();
    });
    Gm.on("toast", showToast);
    Gm.on("catch", showCatch);
    Gm.on("state", st => {
      Sc.setState(st === "wait" ? "wait" : st === "bite" ? "bite" : "wait");
      renderAction(st);
    });
    $("action").onclick = () => Gm.cast();
    $("sheetClose").onclick = closePanel;
    $("autoToggle").onclick = () => {
      Gm.autoCast = !Gm.autoCast;
      $("autoSwitch").classList.toggle("on", Gm.autoCast);
      renderAction(Gm.getState());
    };
    document.addEventListener("keydown", e => {
      if (e.code === "Space") {
        e.preventDefault();
        Gm.cast();
      }
      if (e.code === "Escape") closePanel();
    });
    $("autoSwitch").classList.toggle("on", G.autoCast);
    $("loading").style.display = "none";
    Gm.start();
    refreshAll();
    // periodic light refresh for phase/timers
    setInterval(() => {
      renderTopRight();
    }, 1500);
  }
  loadAll(boot);
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "playable/ui.js", error: String((e && e.message) || e) }); }

// ui_kits/corner_fishing/app.jsx
try { (() => {
/* 角落垂钓 — interactive widget recreation. Composes the design-system
   components from window.CornerFishingDesignSystem_301be0 (read inside App
   so it stays safe regardless of script-eval order). */

function App() {
  const NS = window.CornerFishingDesignSystem_301be0 || {};
  const {
    Panel,
    TabBar,
    Card,
    Button,
    RoundButton,
    Toggle,
    Slider,
    ProgressBar,
    FishRow,
    DexCard,
    SpotCard,
    HudChip,
    Badge,
    FishIcon
  } = NS;
  const D = window.CF_DATA;
  const COIN = "../../assets/ui/icon_coin.png";

  // Resilient to bundle lag: use the real DS components, but never hard-crash
  // to black if a freshly-added one hasn't landed in the served bundle yet.
  const HudLedger = NS.HudLedger || (({
    coins,
    used,
    capacity
  }) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 8,
      padding: "7px 12px",
      borderRadius: 12,
      background: "rgba(26,27,23,.62)",
      border: "1px solid rgba(224,214,189,.28)",
      backdropFilter: "blur(6px)",
      color: "#f7e9c8",
      fontFamily: "var(--font-display)",
      fontWeight: 900
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: COIN,
    width: "18",
    height: "18",
    alt: ""
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 18,
      fontVariantNumeric: "tabular-nums"
    }
  }, Number(coins).toLocaleString()), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 1,
      height: 22,
      background: "rgba(224,214,189,.3)"
    }
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontWeight: 400,
      fontSize: 11,
      color: "#d8d2c4"
    }
  }, "\u9C7C\u7BD3 ", used, "/", capacity)));
  const SummaryStrip = NS.SummaryStrip || (({
    used,
    capacity,
    value
  }) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      gap: 14,
      background: "rgba(0,0,0,.22)",
      border: "1px solid var(--glass-row-border)",
      borderRadius: 12,
      padding: "11px 14px",
      fontFamily: "var(--font-sans)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 12,
      color: "var(--text-muted-glass)"
    }
  }, "\u9C7C\u7BD3\u5BB9\u91CF ", used, "/", capacity), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-display)",
      fontWeight: 900,
      fontSize: 22,
      color: "var(--gold-bright)"
    }
  }, Number(value).toLocaleString(), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: "var(--font-sans)",
      fontWeight: 400,
      fontSize: 11,
      color: "var(--text-muted-glass)",
      marginLeft: 6
    }
  }, "\u53EF\u5356"))));
  const [open, setOpen] = React.useState(null); // null | "bag"
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
    setCoins(c => c + f.value);
    setInv(arr => arr.filter((_, j) => j !== i));
  }
  function toggleLock(i) {
    setInv(arr => arr.map((f, j) => j === i ? {
      ...f,
      locked: !f.locked
    } : f));
  }
  function sellAll() {
    const gain = inv.filter(f => !f.locked).reduce((s, f) => s + f.value, 0);
    setCoins(c => c + gain);
    setInv(arr => arr.filter(f => f.locked));
  }
  const sorted = React.useMemo(() => {
    const a = inv.map((f, i) => ({
      f,
      i
    }));
    if (sort === 1) a.sort((x, y) => y.f.value - x.f.value);else if (sort === 2) a.sort((x, y) => y.f.tier - x.f.tier);else if (sort === 3) a.sort((x, y) => y.f.weight - x.f.weight);
    return a;
  }, [inv, sort]);
  const unlockedCount = inv.filter(f => !f.locked).length;
  const totalValue = inv.filter(f => !f.locked).reduce((s, f) => s + f.value, 0);

  // ---- tab bodies ----
  function BagTab() {
    return /*#__PURE__*/React.createElement("div", {
      style: S.col
    }, /*#__PURE__*/React.createElement(SummaryStrip, {
      used: inv.length,
      capacity: cap,
      value: totalValue,
      coinIcon: COIN
    }), /*#__PURE__*/React.createElement("div", {
      style: S.sortRow
    }, /*#__PURE__*/React.createElement("div", {
      style: S.seg
    }, SORTS.map((s, m) => /*#__PURE__*/React.createElement("button", {
      key: m,
      onClick: () => setSort(m),
      style: {
        ...S.segBtn,
        ...(m === sort ? S.segBtnOn : {})
      }
    }, s))), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement("button", {
      style: S.filterBtn
    }, "\u8BA2\u5355\u9C7C")), /*#__PURE__*/React.createElement("div", {
      style: S.scroll
    }, /*#__PURE__*/React.createElement("div", {
      style: S.bagList
    }, sorted.map(({
      f,
      i
    }) => /*#__PURE__*/React.createElement(FishRow, {
      key: f.id + i,
      src: f.src,
      fallbackSrc: D.fb(f.tier),
      name: f.name,
      tier: f.tier,
      variant: f.variant,
      quality: f.quality,
      weight: f.weight,
      sizeTag: f.sizeTag,
      locked: f.locked,
      value: f.value,
      coinIcon: COIN,
      onSell: () => sellOne(i),
      onToggleLock: () => toggleLock(i)
    })))), /*#__PURE__*/React.createElement("div", {
      style: S.footBar
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      size: "sm"
    }, "\u5356\u6742\u9C7C"), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1
      }
    }), /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      size: "sm"
    }, "\u6269\u5BB9"), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      size: "sm",
      disabled: unlockedCount === 0,
      onClick: sellAll
    }, "\u5168\u90E8\u5356\u51FA", totalValue > 0 ? ` · +${totalValue}` : "")));
  }
  function DexTab() {
    const got = D.dex.filter(d => d.known).length;
    return /*#__PURE__*/React.createElement("div", {
      style: S.col
    }, /*#__PURE__*/React.createElement("div", {
      style: S.statLine
    }, "\u6536\u96C6 ", got, "/106\u3000\xB7\u3000\u53D8\u4F53 3/318\u3000\xB7\u3000\u6E14\u83B7 152"), /*#__PURE__*/React.createElement("div", {
      style: S.scroll
    }, /*#__PURE__*/React.createElement("div", {
      style: S.dexGrid
    }, D.dex.map(d => /*#__PURE__*/React.createElement(DexCard, {
      key: d.id,
      src: d.src,
      fallbackSrc: D.fb(d.tier),
      name: d.name,
      tier: d.tier,
      known: d.known,
      count: d.count,
      maxWeight: d.maxWeight,
      collected: d.collected,
      giant: d.giant,
      perfect: d.perfect,
      variants: d.variants || []
    })))));
  }
  function OrderTab() {
    return /*#__PURE__*/React.createElement("div", {
      style: S.col
    }, /*#__PURE__*/React.createElement("div", {
      style: S.statLine
    }, "\u6BCF\u65E5\u8BA2\u5355 \xB7 2026-06-16"), /*#__PURE__*/React.createElement(Card, {
      surface: "paper",
      pad: false
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 12,
        padding: 12,
        alignItems: "center"
      }
    }, /*#__PURE__*/React.createElement(FishIcon, {
      src: D.fb(2),
      size: 64,
      tier: 2,
      frame: true
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        gap: 4
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontFamily: "var(--font-display)",
        fontWeight: 700,
        fontSize: 17,
        color: "var(--ink)"
      }
    }, "\u6536 3 \u6761 \u4F18\u826F\u53CA\u4EE5\u4E0A"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 12,
        color: "var(--ink-soft)",
        lineHeight: 1.5
      }
    }, "\u6307\u5B9A\u54C1\u9636\u8BA2\u5355 \xB7 \u4EA4\u4ED8\u672A\u4E0A\u9501\u7684\u7B26\u5408\u6E14\u83B7\uFF0C\u6309\u9C7C\u4EF7 \xD72.5 \u7ED3\u7B97"), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 12,
        color: "var(--bronze)",
        fontWeight: 500
      }
    }, "\u53EF\u4EA4\u4ED8 2/3")), /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      disabled: true
    }, "\u4EA4\u4ED8"))), /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 12,
        color: "var(--text-muted-glass)"
      }
    }, "\u9501\u5B9A\u7684\u76EE\u6807\u9C7C\u4F1A\u7559\u5728\u9C7C\u7BD3\u91CC\uFF0C\u4E0D\u4F1A\u88AB\u8BA2\u5355\u4EA4\u4ED8\u3002"), /*#__PURE__*/React.createElement("div", {
      style: {
        height: 1,
        background: "var(--glass-row-border)",
        margin: "4px 0"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: S.statLine
    }, "\u672C\u5468\u6311\u6218"), /*#__PURE__*/React.createElement(Card, {
      surface: "paper"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        fontSize: 14,
        fontWeight: 500,
        color: "var(--ink)",
        marginBottom: 8
      }
    }, "\u672C\u5468\u7D2F\u8BA1\u9493\u5230 160 \u6761\u9C7C"), /*#__PURE__*/React.createElement(ProgressBar, {
      value: 80,
      max: 160,
      surface: "paper",
      caption: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("span", null, "80 / 160"), /*#__PURE__*/React.createElement("span", null, "\u5956\u52B1 4500 \u91D1\u5E01"))
    })));
  }
  function SpotTab() {
    return /*#__PURE__*/React.createElement("div", {
      style: S.col
    }, /*#__PURE__*/React.createElement("div", {
      style: S.statLine
    }, "\u9493\u70B9 \xB7 \u5DF2\u89E3\u9501 2/3"), /*#__PURE__*/React.createElement("div", {
      style: S.scroll
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 8
      }
    }, D.spots.map(s => /*#__PURE__*/React.createElement(SpotCard, {
      key: s.id,
      name: s.name,
      desc: s.desc,
      got: s.got,
      total: s.total,
      unlocked: s.unlocked,
      current: s.current,
      event: s.event,
      unlockText: s.unlockText
    })))));
  }
  function SettingsTab() {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        ...S.col,
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 8,
        fontSize: 13,
        color: "var(--text-muted-glass)"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        color: "var(--gold)"
      }
    }, "\uD83D\uDD12"), " \u81EA\u52A8\u5356\u9C7C", /*#__PURE__*/React.createElement(Badge, {
      tone: "gold",
      variant: "outline"
    }, "\u9AD8\u7EA7\u529F\u80FD \xB7 \u656C\u8BF7\u671F\u5F85")), /*#__PURE__*/React.createElement("div", {
      style: {
        height: 1,
        background: "var(--glass-row-border)"
      }
    }), /*#__PURE__*/React.createElement(Toggle, {
      label: "\u9759\u97F3",
      checked: mute,
      onChange: setMute,
      style: {
        justifyContent: "space-between",
        width: "100%"
      }
    }), /*#__PURE__*/React.createElement(Slider, {
      label: "\u4E3B\u97F3\u91CF",
      value: vol,
      onChange: setVol,
      disabled: mute
    }), /*#__PURE__*/React.createElement(Slider, {
      label: "\u97F3\u6548",
      value: sfx,
      onChange: setSfx,
      disabled: mute
    }), /*#__PURE__*/React.createElement(Slider, {
      label: "\u73AF\u5883\u97F3",
      value: amb,
      onChange: setAmb,
      disabled: mute
    }), /*#__PURE__*/React.createElement(Toggle, {
      label: "\u4E13\u6CE8\u6A21\u5F0F\uFF08\u5C11\u6253\u6270\uFF09",
      checked: focus,
      onChange: setFocus,
      style: {
        justifyContent: "space-between",
        width: "100%"
      }
    }), /*#__PURE__*/React.createElement(Slider, {
      label: "\u4E0D\u900F\u660E\u5EA6",
      value: opacity,
      min: 40,
      max: 100,
      onChange: setOpacity
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 8,
        marginTop: 4
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "secondary"
    }, "\u56DE\u5230\u53F3\u4E0B\u89D2"), /*#__PURE__*/React.createElement(Button, {
      variant: "secondary"
    }, "\u9000\u51FA\u6E38\u620F")));
  }
  const TABS = ["背包", "图鉴", "订单", "钓点", "设置"];
  const BODIES = [BagTab, DexTab, OrderTab, SpotTab, SettingsTab];
  const Body = BODIES[tab];
  return /*#__PURE__*/React.createElement("div", {
    style: S.desktop
  }, /*#__PURE__*/React.createElement("div", {
    style: S.hint
  }, "\u684C\u9762\u6302\u4EF6 \xB7 \u70B9 ", /*#__PURE__*/React.createElement("b", null, "\u91D1\u5E01\u680F"), " \u6253\u5F00\u9762\u677F"), /*#__PURE__*/React.createElement("div", {
    style: S.scene
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/scenes/spot_river_bend.png",
    alt: "",
    style: S.sceneImg
  }), /*#__PURE__*/React.createElement("img", {
    src: "../../assets/character/fisher_idle.png",
    alt: "",
    style: S.fisher
  }), /*#__PURE__*/React.createElement("img", {
    src: "../../assets/props/bobber_idle.png",
    alt: "",
    style: S.bobber
  }), /*#__PURE__*/React.createElement("div", {
    style: S.hud
  }, /*#__PURE__*/React.createElement("div", {
    onClick: () => {
      setOpen("bag");
      setTab(0);
    },
    style: {
      cursor: "pointer"
    }
  }, /*#__PURE__*/React.createElement(HudLedger, {
    coins: coins,
    used: inv.length,
    capacity: cap,
    coinIcon: "../../assets/ui/icon_coin.png"
  })), /*#__PURE__*/React.createElement(HudChip, {
    onClick: () => {
      setOpen("bag");
      setTab(3);
    },
    tone: "default",
    size: 13
  }, "\u65B0\u624B\u6CB3\u6E7E \xB7 \u9EC4\u660F"), /*#__PURE__*/React.createElement(HudChip, {
    tone: "gold",
    onClick: () => {
      setOpen("bag");
      setTab(2);
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontWeight: 700
    }
  }, "\u8BA2\u5355 2/3"), "\u3000\u8FD8\u5DEE 1 \u6761"))), open === "bag" && /*#__PURE__*/React.createElement("div", {
    style: S.overlay,
    onClick: e => {
      if (e.target === e.currentTarget) setOpen(null);
    }
  }, /*#__PURE__*/React.createElement(Panel, {
    title: "\u9C7C\u7BD3",
    subtitle: "2026-06-16",
    onClose: () => setOpen(null),
    width: 520,
    style: {
      maxHeight: "86vh"
    },
    bodyStyle: {
      overflow: "hidden"
    }
  }, /*#__PURE__*/React.createElement(TabBar, {
    variant: "underline",
    tabs: TABS.slice(0, 4),
    active: tab < 4 ? tab : -1,
    onChange: setTab,
    overflow: tab === 4 ? "设置 ✓" : "更多 ▾",
    onOverflow: () => setTab(4)
  }), /*#__PURE__*/React.createElement("div", {
    style: S.navRule
  }), /*#__PURE__*/React.createElement(Body, null))));
}
const S = {
  desktop: {
    position: "fixed",
    inset: 0,
    overflow: "hidden",
    background: "linear-gradient(160deg,#8893a0 0%,#9aa4ab 38%,#b4b3a6 72%,#ccc6b6 100%)",
    fontFamily: "var(--font-sans)"
  },
  hint: {
    position: "absolute",
    top: 18,
    left: 20,
    fontSize: 12,
    color: "rgba(40,44,48,.6)",
    background: "rgba(255,255,255,.34)",
    padding: "6px 12px",
    borderRadius: 999
  },
  scene: {
    position: "absolute",
    right: 0,
    bottom: 0,
    width: 520,
    height: 420
  },
  sceneImg: {
    position: "absolute",
    inset: 0,
    width: "100%",
    height: "100%",
    objectFit: "cover",
    objectPosition: "right bottom",
    WebkitMaskImage: "var(--feather-mask)",
    maskImage: "var(--feather-mask)"
  },
  fisher: {
    position: "absolute",
    right: 56,
    bottom: 70,
    width: 96,
    height: "auto",
    filter: "drop-shadow(0 2px 3px rgba(0,0,0,.3))"
  },
  bobber: {
    position: "absolute",
    right: 150,
    bottom: 74,
    width: 14,
    animation: "cf-bobber-bob 3s var(--ease-soft) infinite"
  },
  hud: {
    position: "absolute",
    right: 18,
    bottom: 150,
    display: "flex",
    flexDirection: "column",
    alignItems: "flex-end",
    gap: 7
  },
  overlay: {
    position: "fixed",
    inset: 0,
    background: "rgba(20,22,20,.34)",
    display: "grid",
    placeItems: "center",
    zIndex: 100,
    backdropFilter: "blur(1px)"
  },
  col: {
    display: "flex",
    flexDirection: "column",
    gap: 10,
    minHeight: 0
  },
  navRule: {
    height: 1,
    background: "var(--glass-row-border)",
    margin: "1px 0 0"
  },
  sortRow: {
    display: "flex",
    gap: 8,
    alignItems: "center"
  },
  seg: {
    display: "inline-flex",
    background: "rgba(0,0,0,.24)",
    borderRadius: 999,
    padding: 3,
    gap: 2
  },
  segBtn: {
    height: 24,
    padding: "0 12px",
    borderRadius: 999,
    border: "none",
    background: "transparent",
    color: "var(--text-muted-glass)",
    fontSize: 12,
    cursor: "pointer",
    fontFamily: "var(--font-sans)"
  },
  segBtnOn: {
    background: "var(--bronze)",
    color: "var(--ink-on-gold)",
    fontWeight: 700
  },
  filterBtn: {
    fontSize: 12,
    color: "var(--text-muted-glass)",
    cursor: "pointer",
    border: "1px solid var(--glass-row-border)",
    borderRadius: 999,
    padding: "4px 11px",
    background: "transparent",
    fontFamily: "var(--font-sans)"
  },
  scroll: {
    overflowY: "auto",
    overflowX: "hidden",
    maxHeight: "46vh",
    paddingRight: 6
  },
  bagList: {
    display: "flex",
    flexDirection: "column",
    gap: 6
  },
  footBar: {
    display: "flex",
    alignItems: "center",
    gap: 8,
    paddingTop: 8,
    borderTop: "1px solid var(--glass-row-border)"
  },
  dexGrid: {
    display: "grid",
    gridTemplateColumns: "repeat(4,1fr)",
    gap: 8,
    justifyItems: "center"
  },
  statLine: {
    fontSize: 13,
    color: "var(--text-muted-glass)"
  }
};
ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/corner_fishing/app.jsx", error: String((e && e.message) || e) }); }

// ui_kits/corner_fishing/data.js
try { (() => {
/* 角落垂钓 UI kit — sample game state (fake, for the recreation). */
(function () {
  const A = "../../assets/fish/";
  const fb = t => "../../assets/fish/generic_tier" + t + ".png";

  // [id, name, src, tier, variant, quality, weight, sizeTag, value, locked]
  const inventory = [{
    id: "gudgeon",
    name: "棒花鱼",
    src: A + "gudgeon.png",
    tier: 0,
    variant: 0,
    quality: 1,
    weight: 0.04,
    sizeTag: "",
    value: 4
  }, {
    id: "mandarin",
    name: "鳜鱼",
    src: A + "mandarin.png",
    tier: 3,
    variant: 0,
    quality: 0,
    weight: 0.79,
    sizeTag: "",
    value: 110
  }, {
    id: "fangbream",
    name: "翘嘴鲌",
    src: A + "fangbream.png",
    tier: 2,
    variant: 0,
    quality: 0,
    weight: 2.21,
    sizeTag: "",
    value: 114
  }, {
    id: "trout",
    name: "虹鳟",
    src: A + "trout.png",
    tier: 3,
    variant: 0,
    quality: 1,
    weight: 1.28,
    sizeTag: "",
    value: 504
  }, {
    id: "redeye",
    name: "赤眼鳟",
    src: A + "redeye.png",
    tier: 1,
    variant: 0,
    quality: 0,
    weight: 1.12,
    sizeTag: "",
    value: 26
  }, {
    id: "grass",
    name: "草鱼",
    src: A + "grass.png",
    tier: 1,
    variant: 0,
    quality: 0,
    weight: 9.95,
    sizeTag: "大",
    value: 39
  }, {
    id: "koi",
    name: "锦鲤",
    src: A + "koi.png",
    tier: 4,
    variant: 2,
    quality: 2,
    weight: 3.10,
    sizeTag: "",
    value: 1820,
    locked: true
  }, {
    id: "bass",
    name: "鲈鱼",
    src: A + "bass.png",
    tier: 2,
    variant: 0,
    quality: 0,
    weight: 1.84,
    sizeTag: "",
    value: 88
  }];

  // Codex order roughly by tier
  const dex = [{
    id: "whitebait",
    name: "白条",
    src: A + "whitebait.png",
    tier: 0,
    known: true,
    count: 14,
    maxWeight: 0.12,
    collected: true
  }, {
    id: "crucian",
    name: "鲫鱼",
    src: A + "crucian.png",
    tier: 0,
    known: true,
    count: 8,
    maxWeight: 0.66
  }, {
    id: "loach",
    name: "泥鳅",
    src: A + "loach.png",
    tier: 0,
    known: true,
    count: 3,
    maxWeight: 0.09
  }, {
    id: "gudgeon",
    name: "棒花鱼",
    src: A + "gudgeon.png",
    tier: 0,
    known: true,
    count: 1,
    maxWeight: 0.04
  }, {
    id: "topmouth",
    name: "麦穗鱼",
    src: A + "topmouth.png",
    tier: 0,
    known: false
  }, {
    id: "carp",
    name: "鲤鱼",
    src: A + "carp.png",
    tier: 1,
    known: true,
    count: 11,
    maxWeight: 3.4,
    collected: true,
    giant: true
  }, {
    id: "grass",
    name: "草鱼",
    src: A + "grass.png",
    tier: 1,
    known: true,
    count: 5,
    maxWeight: 9.95,
    giant: true
  }, {
    id: "redeye",
    name: "赤眼鳟",
    src: A + "redeye.png",
    tier: 1,
    known: true,
    count: 2,
    maxWeight: 1.12
  }, {
    id: "dace",
    name: "雅罗鱼",
    src: A + "dace.png",
    tier: 1,
    known: false
  }, {
    id: "bass",
    name: "鲈鱼",
    src: A + "bass.png",
    tier: 2,
    known: true,
    count: 4,
    maxWeight: 1.84
  }, {
    id: "bream",
    name: "鳊鱼",
    src: A + "bream.png",
    tier: 2,
    known: true,
    count: 1,
    maxWeight: 0.5,
    variants: [1]
  }, {
    id: "fangbream",
    name: "翘嘴鲌",
    src: A + "fangbream.png",
    tier: 2,
    known: true,
    count: 6,
    maxWeight: 2.21
  }, {
    id: "blackcarp",
    name: "青鱼",
    src: A + "blackcarp.png",
    tier: 2,
    known: false
  }, {
    id: "mandarin",
    name: "鳜鱼",
    src: A + "mandarin.png",
    tier: 3,
    known: true,
    count: 2,
    maxWeight: 0.79
  }, {
    id: "trout",
    name: "虹鳟",
    src: A + "trout.png",
    tier: 3,
    known: true,
    count: 3,
    maxWeight: 1.28,
    perfect: true
  }, {
    id: "pike",
    name: "白斑狗鱼",
    src: A + "pike.png",
    tier: 3,
    known: false
  }, {
    id: "snakehead",
    name: "黑鱼",
    src: A + "snakehead.png",
    tier: 3,
    known: false
  }, {
    id: "koi",
    name: "锦鲤",
    src: A + "koi.png",
    tier: 4,
    known: true,
    count: 2,
    maxWeight: 3.1,
    variants: [2]
  }, {
    id: "salmon",
    name: "大马哈鱼",
    src: A + "salmon.png",
    tier: 4,
    known: false
  }, {
    id: "taimen",
    name: "哲罗鲑",
    src: A + "taimen.png",
    tier: 4,
    known: false
  }, {
    id: "chinese_sturgeon",
    name: "中华鲟",
    src: A + "chinese_sturgeon.png",
    tier: 5,
    known: false
  }, {
    id: "kaluga",
    name: "达氏鳇",
    src: A + "kaluga.png",
    tier: 5,
    known: false
  }, {
    id: "oarfish",
    name: "皇带鱼",
    src: A + "oarfish.png",
    tier: 5,
    known: false
  }, {
    id: "coelacanth",
    name: "矛尾鱼",
    src: A + "coelacanth.png",
    tier: 5,
    known: false
  }];
  const spots = [{
    id: "river",
    name: "新手河湾",
    desc: "最初的那方静水，缓流绕过雪岸。从白条到国宝鲟，什么都可能上钩——新手友好的全能钓点。",
    got: 6,
    total: 44,
    unlocked: true,
    current: true,
    event: "风平浪静"
  }, {
    id: "lake",
    name: "静水湖泊",
    desc: "水草丰茂的冬日湖湾，掠食者潜伏在乱石与树根间。鲈、鳜、黑鱼、狗鱼当家，偶有巨鲟与鳇鲶。",
    got: 5,
    total: 43,
    unlocked: true
  }, {
    id: "coast",
    name: "海岸码头",
    desc: "海风咸涩，浪拍木桩，小灯在栈桥尽头摇。海鲈、鲷、带鱼、石斑、马鲛轮番登场，深处藏着金枪与旗鱼。",
    got: 0,
    total: 48,
    unlocked: false,
    unlockText: "累计渔获 120 条解锁"
  }];
  window.CF_DATA = {
    inventory,
    dex,
    spots,
    fb
  };
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/corner_fishing/data.js", error: String((e && e.message) || e) }); }

__ds_ns.DexCard = __ds_scope.DexCard;

__ds_ns.FishIcon = __ds_scope.FishIcon;

__ds_ns.FishRow = __ds_scope.FishRow;

__ds_ns.HudChip = __ds_scope.HudChip;

__ds_ns.HudLedger = __ds_scope.HudLedger;

__ds_ns.SpotCard = __ds_scope.SpotCard;

__ds_ns.SummaryStrip = __ds_scope.SummaryStrip;

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.ProgressBar = __ds_scope.ProgressBar;

__ds_ns.RoundButton = __ds_scope.RoundButton;

__ds_ns.Slider = __ds_scope.Slider;

__ds_ns.Toggle = __ds_scope.Toggle;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Panel = __ds_scope.Panel;

__ds_ns.TabBar = __ds_scope.TabBar;

})();
