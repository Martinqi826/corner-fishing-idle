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
  "tier-0": "var(--tier-0)", "tier-1": "var(--tier-1)", "tier-2": "var(--tier-2)",
  "tier-3": "var(--tier-3)", "tier-4": "var(--tier-4)", "tier-5": "var(--tier-5)",
  "variant-1": "var(--variant-1)", "variant-2": "var(--variant-2)", "variant-3": "var(--variant-3)",
  gold: "var(--gold)", positive: "var(--positive)", merchant: "var(--merchant)",
  rust: "var(--rust)", neutral: "var(--text-muted-glass)",
};

/**
 * Small status / rarity badge. `text` = colored label (codex marks),
 * `pill` = filled pill, `outline` = hollow pill.
 */
export function Badge({ children, tone = "neutral", variant = "text", legible = false, style, ...rest }) {
  useCfStyles("cf-badge-css", CSS);
  const color = TONES[tone] || tone;
  let extra = {};
  if (variant === "pill") {
    extra = { background: color, color: "var(--glass-solid)", borderColor: "rgba(255,255,255,0.18)" };
  } else if (variant === "outline") {
    extra = { color };
  } else {
    extra = { color };
  }
  return (
    <span
      className={`cf-badge cf-badge--${variant}${legible ? " cf-badge--legible" : ""}`}
      style={{ ...extra, ...style }}
      {...rest}
    >
      {children}
    </span>
  );
}
