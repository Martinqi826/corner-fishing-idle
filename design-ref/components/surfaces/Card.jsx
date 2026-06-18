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
export function Card({
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
  const cls = [
    "cf-card",
    `cf-card--${surface}`,
    pad ? "cf-card--pad" : "",
    interactive ? "cf-card--interactive" : "",
    locked ? "cf-card--locked" : "",
    className,
  ].filter(Boolean).join(" ");
  return (
    <div className={cls} onClick={interactive ? onClick : undefined} style={style} {...rest}>
      {children}
    </div>
  );
}
