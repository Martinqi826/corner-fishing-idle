import React from "react";
import { Button } from "../primitives/Button.jsx";

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
export function SpotCard({
  name, desc, got = 0, total = 0, unlocked = false, current = false,
  event, unlockText, onGo, style,
}) {
  useCfStyles("cf-spot-css", CSS);
  const tone = unlocked ? "on" : "off";
  return (
    <div className={`cf-spot cf-spot--${tone}`} style={style}>
      <div className="cf-spot__head">
        <span className={`cf-spot__name cf-spot__name--${tone}`}>
          {current ? "📍 " : ""}{name}
        </span>
        {current ? (
          <Button variant="secondary" size="md" disabled style={{ minWidth: 70 }}>当前</Button>
        ) : unlocked ? (
          <Button variant="primary" size="md" onClick={onGo} style={{ minWidth: 70 }}>前往</Button>
        ) : (
          <Button variant="secondary" size="md" disabled style={{ minWidth: 70 }}>未解锁</Button>
        )}
      </div>
      <div className={`cf-spot__desc cf-spot__desc--${tone}`}>{desc}</div>
      <div className={`cf-spot__foot cf-spot__foot--${tone}`}>
        {unlocked
          ? `鱼种收集 ${got}/${total}${current ? `　·　${event || "风平浪静"}` : ""}`
          : `🔒 ${unlockText}`}
      </div>
    </div>
  );
}
