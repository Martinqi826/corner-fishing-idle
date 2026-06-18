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

const RAIL_VARS = ["var(--tier-0)","var(--tier-1)","var(--tier-2)","var(--tier-3)","var(--tier-4)","var(--tier-5)"];
const VARIANT_VARS = [null,"var(--variant-1)","var(--variant-2)","var(--variant-3)"];

/**
 * Codex (图鉴) grid cell — legibility-first. Known = parchment with a tier
 * rail/frame, dark-ink name, record + a /10 collection meter; unknown = dim.
 */
export function DexCard({
  src, fallbackSrc, name, tier = 0, known = false, count = 0, maxWeight = 0,
  collected = false, giant = false, perfect = false, variants = [], style,
}) {
  useCfStyles("cf-dex-css", CSS);
  if (!known) {
    return (
      <div className="cf-dex cf-dex--unknown" style={style}>
        <FishIcon src={src} fallbackSrc={fallbackSrc} tier={tier} size={42} dimmed />
        <span className="cf-dex__name cf-dex__name--unknown">未发现</span>
      </div>
    );
  }
  const pct = Math.max(0, Math.min(100, (count / 10) * 100));
  const hasMarks = giant || perfect || variants.length > 0;
  return (
    <div className="cf-dex cf-dex--known" style={{ "--cf-rail": RAIL_VARS[tier], ...style }}>
      <FishIcon src={src} fallbackSrc={fallbackSrc} tier={tier} size={46} />
      <span className="cf-dex__name">{name}</span>
      <span className="cf-dex__rec">
        <span>×<b>{count}</b></span>
        {maxWeight > 0 ? <span>最大 {maxWeight.toFixed(2)}kg</span> : null}
      </span>
      <div className="cf-dex__milestone">
        {collected ? (
          <span className="cf-dex__done">✦ 集齐</span>
        ) : (
          <>
            <span className="cf-dex__bar"><i style={{ width: `${pct}%` }} /></span>
            <span className="cf-dex__barnum">{count}/10</span>
          </>
        )}
      </div>
      {hasMarks ? (
        <div className="cf-dex__marks">
          {giant ? <span className="cf-dex__mark" style={{ color: "var(--tier-4)" }}>巨</span> : null}
          {perfect ? <span className="cf-dex__mark" style={{ color: "var(--tier-3)" }}>完★</span> : null}
          {variants.map((v) => (
            <span key={v} className="cf-dex__dot" style={{ color: VARIANT_VARS[v] }}>●</span>
          ))}
        </div>
      ) : null}
    </div>
  );
}
