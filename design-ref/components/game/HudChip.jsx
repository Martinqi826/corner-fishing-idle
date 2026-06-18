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
  default: "#ECE8E0", muted: "var(--text-muted-glass)", gold: "var(--merchant)",
  positive: "var(--positive)", warn: "var(--bag-full)", water: "var(--water-light)",
};

/**
 * A HUD line that floats over the scene — coin/basket ledger, spot·phase,
 * order progress. Flat, text-shadowed for readability on any wallpaper.
 */
export function HudChip({ children, icon, tone = "default", size = 14, onClick, style, ...rest }) {
  useCfStyles("cf-chip-css", CSS);
  const color = TONES[tone] || tone;
  return (
    <button
      type="button"
      className={`cf-chip${onClick ? " cf-chip--btn" : ""}`}
      onClick={onClick}
      tabIndex={onClick ? 0 : -1}
      style={{ color, fontSize: size, ...style }}
      {...rest}
    >
      {icon ? <img className="cf-chip__icon" src={icon} alt="" aria-hidden="true" /> : null}
      {children}
    </button>
  );
}
