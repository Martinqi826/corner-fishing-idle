import React from "react";

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
export function HudLedger({ coins = 0, used = 0, capacity = 20, coinIcon, style }) {
  useCfStyles("cf-ledger-css", CSS);
  const pct = Math.max(0, Math.min(100, (used / capacity) * 100));
  const full = used >= capacity;
  return (
    <div className="cf-ledger" style={style}>
      <div className="cf-ledger__coin">
        {coinIcon ? <img src={coinIcon} alt="" /> : null}
        <span className="cf-ledger__v">{Number(coins).toLocaleString()}</span>
      </div>
      <div className="cf-ledger__sep" />
      <div className="cf-ledger__bag">
        <span className={`cf-ledger__t${full ? " cf-ledger__t--full" : ""}`}>鱼篓 {used}/{capacity}</span>
        <span className={`cf-ledger__b${full ? " cf-ledger__b--full" : ""}`}><i style={{ width: `${pct}%` }} /></span>
      </div>
    </div>
  );
}
