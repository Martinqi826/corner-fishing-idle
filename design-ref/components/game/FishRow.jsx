import React from "react";
import { FishIcon } from "./FishIcon.jsx";

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

const TIER_VARS = ["var(--tier-0)","var(--tier-1)","var(--tier-2)","var(--tier-3)","var(--tier-4)","var(--tier-5)"];
const VARIANT_VARS = [null,"var(--variant-1)","var(--variant-2)","var(--variant-3)"];
const VARIANT_NAMES = ["", "斑斓", "鎏金", "七彩"];
const VARIANT_MULTS = [0, 2, 5, 12];
const VARIANT_SOFT = [null, "rgba(140,217,242,.16)", "rgba(255,214,89,.16)", "rgba(242,140,242,.16)"];
const TIER_SOFT = ["rgba(199,199,204,.10)","rgba(89,199,77,.12)","rgba(77,158,242,.13)","rgba(184,107,242,.15)","rgba(255,140,31,.16)","rgba(255,97,82,.16)"];

const LOCK = (
  <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor"
    strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <rect x="5" y="11" width="14" height="9" rx="2" />
    <path d="M8 11V8a4 4 0 0 1 8 0v3" />
  </svg>
);

/**
 * Rich basket entry: tier-framed icon + tier rail · tier-coloured name ·
 * variant/size/quality tags · favourite-lock · coin-pill price.
 * Tier ≥4 or any rare variant auto-emphasises (tinted row).
 */
export function FishRow({
  src, fallbackSrc, name, tier = 0, variant = 0, quality = 0, weight, sizeTag,
  locked = false, value, coinIcon, emphasis, onSell, onToggleLock, style,
}) {
  useCfStyles("cf-fishrow-css", CSS);
  const railVar = variant ? VARIANT_VARS[variant] : TIER_VARS[tier];
  const railSoft = variant ? VARIANT_SOFT[variant] : TIER_SOFT[tier];
  const nameColor = variant ? VARIANT_VARS[variant] : TIER_VARS[tier];
  const hi = emphasis != null ? emphasis : (tier >= 4 || variant >= 1);
  return (
    <div className={`cf-fr${hi ? " cf-fr--hi" : ""}`}
      style={{ "--cf-rail": railVar, "--cf-railsoft": railSoft, ...style }}>
      <FishIcon className="cf-fr__ic" src={src} fallbackSrc={fallbackSrc}
        tier={tier} variant={variant} size={46} frame />
      <div className="cf-fr__main">
        <span className="cf-fr__nm" style={{ color: nameColor }}>
          {variant ? <span className="cf-fr__gem">◆</span> : null}{name}
        </span>
        <span className="cf-fr__tags">
          {variant ? (
            <span className="cf-fr__pill" style={{ background: railSoft, color: VARIANT_VARS[variant] }}>
              {VARIANT_NAMES[variant]} ×{VARIANT_MULTS[variant]}
            </span>
          ) : null}
          {sizeTag ? (
            <span className="cf-fr__pill" style={{ background: "rgba(255,140,31,.16)", color: "var(--tier-4)" }}>
              {sizeTag === "大" ? "大物" : sizeTag}
            </span>
          ) : null}
          {quality > 0 ? <span className="cf-fr__q">{"★".repeat(quality)}</span> : null}
          {weight != null ? <span className="cf-fr__wt">{Number(weight).toFixed(2)}kg</span> : null}
        </span>
      </div>
      <div className="cf-fr__right">
        <button className={`cf-fr__fav${locked ? " cf-fr__fav--on" : ""}`}
          title={locked ? "解除收藏锁" : "上锁收藏（不会被卖出 / 交付）"} onClick={onToggleLock}>
          {LOCK}
        </button>
        {locked ? (
          <span className="cf-fr__coin cf-fr__coin--locked">锁定</span>
        ) : (
          <button className="cf-fr__coin" onClick={onSell}>
            {coinIcon ? <img src={coinIcon} alt="" /> : null}{value}
          </button>
        )}
      </div>
    </div>
  );
}
