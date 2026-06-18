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
export function ProgressBar({
  value,
  max = 100,
  showPercent = true,
  caption,
  surface = "glass",
  style,
}) {
  useCfStyles("cf-progress-css", CSS);
  const pct = Math.max(0, Math.min(100, (value / max) * 100));
  return (
    <div className="cf-prog" style={style}>
      <div className={`cf-prog__track${surface === "paper" ? " cf-prog__track--paper" : ""}`}>
        <div className="cf-prog__fill" style={{ width: `${pct}%` }} />
        {showPercent ? <span className="cf-prog__pct">{Math.round(pct)}%</span> : null}
      </div>
      {caption ? <div className="cf-prog__cap">{caption}</div> : null}
    </div>
  );
}
