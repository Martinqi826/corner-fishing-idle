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
.cf-toggle{display:inline-flex;align-items:center;gap:10px;cursor:pointer;
  font-family:var(--font-sans);font-size:var(--fs-body);color:var(--text-on-glass);}
.cf-toggle--disabled{opacity:0.5;cursor:default;}
.cf-toggle__track{
  position:relative;width:42px;height:22px;border-radius:999px;flex:0 0 auto;
  background:rgba(0,0,0,0.35);border:1px solid var(--glass-row-border);
  transition:background-color var(--dur-base) var(--ease-calm);
}
.cf-toggle__track--on{background:var(--bronze);border-color:rgba(255,222,140,0.4);}
.cf-toggle__knob{
  position:absolute;top:2px;left:2px;width:16px;height:16px;border-radius:50%;
  background:#F3ECDC;box-shadow:0 1px 2px rgba(0,0,0,0.45);
  transition:transform var(--dur-base) var(--ease-calm);
}
.cf-toggle__track--on .cf-toggle__knob{transform:translateX(20px);}
`;

/** On/off switch — used in Settings (mute, focus-mode). */
export function Toggle({ checked = false, onChange, label, disabled = false, style }) {
  useCfStyles("cf-toggle-css", CSS);
  return (
    <label className={`cf-toggle${disabled ? " cf-toggle--disabled" : ""}`} style={style}>
      {label ? <span>{label}</span> : null}
      <span
        role="switch"
        aria-checked={checked}
        tabIndex={disabled ? -1 : 0}
        className={`cf-toggle__track${checked ? " cf-toggle__track--on" : ""}`}
        onClick={() => !disabled && onChange && onChange(!checked)}
        onKeyDown={(e) => {
          if (!disabled && (e.key === "Enter" || e.key === " ")) {
            e.preventDefault();
            onChange && onChange(!checked);
          }
        }}
      >
        <span className="cf-toggle__knob" />
      </span>
    </label>
  );
}
