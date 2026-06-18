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
export function TabBar({ tabs, active = 0, onChange, variant = "pill", overflow, onOverflow, style }) {
  useCfStyles("cf-tabs-css", CSS);
  if (variant === "underline") {
    return (
      <div className="cf-tabs cf-tabs--underline" role="tablist" style={style}>
        {tabs.map((t, i) => {
          const label = typeof t === "string" ? t : t.label;
          return (
            <button key={i} role="tab" aria-selected={i === active}
              className={`cf-utab${i === active ? " cf-utab--active" : ""}`}
              onClick={() => i !== active && onChange && onChange(i)}>
              {label}
            </button>
          );
        })}
        {overflow ? (
          <button className="cf-utab cf-utab--more" onClick={onOverflow}>{overflow}</button>
        ) : null}
      </div>
    );
  }
  return (
    <div className="cf-tabs" role="tablist" style={style}>
      {tabs.map((t, i) => {
        const label = typeof t === "string" ? t : t.label;
        return (
          <button key={i} role="tab" aria-selected={i === active}
            className={`cf-tab${i === active ? " cf-tab--active" : ""}`}
            onClick={() => i !== active && onChange && onChange(i)}>
            {label}
          </button>
        );
      })}
    </div>
  );
}
