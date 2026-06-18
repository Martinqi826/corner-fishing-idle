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
.cf-round{
  display:grid;place-items:center;padding:0;border:none;background:transparent;
  cursor:pointer;border-radius:50%;line-height:0;
  filter:drop-shadow(var(--shadow-round));
  transition:transform var(--dur-fast) var(--ease-calm),
             filter var(--dur-fast) var(--ease-calm);
}
.cf-round img{width:100%;height:100%;object-fit:contain;display:block;}
.cf-round:hover{transform:translateY(-1px);
  filter:drop-shadow(0 4px 9px rgba(0,0,0,0.42)) brightness(1.06);}
.cf-round:active{transform:translateY(0) scale(0.96);}
.cf-round:focus-visible{outline:2px solid var(--gold);outline-offset:3px;}
.cf-round__badge{
  position:absolute;top:-3px;right:-3px;min-width:16px;height:16px;padding:0 4px;
  display:grid;place-items:center;border-radius:999px;
  background:var(--rust);color:#fff;font-family:var(--font-sans);
  font-weight:var(--w-bold);font-size:10px;line-height:1;
  box-shadow:0 1px 3px rgba(0,0,0,0.4);
}
`;

/**
 * Round desktop-widget button — the three corner controls
 * (rod / fish-basket / coin). Renders a painterly PNG face.
 */
export function RoundButton({ icon, size = 40, title, badge, onClick, style, ...rest }) {
  useCfStyles("cf-roundbtn-css", CSS);
  return (
    <button
      type="button"
      className="cf-round"
      title={title}
      aria-label={title}
      onClick={onClick}
      style={{ width: size, height: size, position: badge != null ? "relative" : undefined, ...style }}
      {...rest}
    >
      <img src={icon} alt="" aria-hidden="true" />
      {badge != null ? <span className="cf-round__badge">{badge}</span> : null}
    </button>
  );
}
