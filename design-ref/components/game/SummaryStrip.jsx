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
export function SummaryStrip({
  used = 0, capacity = 20, value, coinIcon, capLabel = "鱼篓容量",
  valueLabel = "可卖（未锁）", style,
}) {
  useCfStyles("cf-summary-css", CSS);
  const pct = Math.max(0, Math.min(100, (used / capacity) * 100));
  const full = used >= capacity;
  return (
    <div className="cf-sum" style={style}>
      <div className="cf-sum__cap">
        <div className="cf-sum__top"><span>{capLabel}</span><span><b>{used}</b> / {capacity}</span></div>
        <div className={`cf-sum__bar${full ? " cf-sum__bar--full" : ""}`}>
          <i style={{ width: `${pct}%` }} />
        </div>
      </div>
      {value != null ? (
        <div className="cf-sum__val">
          {coinIcon ? <img src={coinIcon} alt="" /> : null}
          <div>
            <div className="cf-sum__v">{Number(value).toLocaleString()}</div>
            <div className="cf-sum__vlab">{valueLabel}</div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
