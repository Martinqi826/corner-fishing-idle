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
.cf-panel{
  display:flex;flex-direction:column;box-sizing:border-box;
  background:var(--surface-panel);border:var(--border-glass);
  border-radius:var(--r-panel);box-shadow:var(--shadow-panel);
  backdrop-filter:var(--blur-glass);-webkit-backdrop-filter:var(--blur-glass);
  color:var(--text-on-glass);font-family:var(--font-sans);
  padding:var(--panel-pad-y) var(--panel-pad-x);
}
.cf-panel__head{display:flex;align-items:center;gap:8px;height:26px;
  margin-bottom:var(--row-gap);cursor:grab;flex:0 0 auto;}
.cf-panel__title{font-family:var(--font-display);font-weight:var(--w-bold);
  font-size:var(--fs-title);color:var(--text-title);letter-spacing:var(--track-tight);}
.cf-panel__sub{font-size:var(--fs-xs);color:var(--text-muted-glass);
  margin-left:auto;align-self:center;}
.cf-panel__close{margin-left:auto;width:28px;height:26px;border:none;background:transparent;
  color:var(--text-muted-glass);font-size:18px;line-height:1;cursor:pointer;border-radius:6px;
  transition:background-color var(--dur-fast),color var(--dur-fast);}
.cf-panel__close:hover{background:var(--glass-row-hover);color:var(--text-on-glass);}
.cf-panel__sub + .cf-panel__close{margin-left:8px;}
.cf-panel__body{display:flex;flex-direction:column;gap:var(--row-gap);min-height:0;flex:1 1 auto;}
`;

/** Floating dark-glass dialog — the widget's pop-up panel chrome. */
export function Panel({ title, subtitle, onClose, children, width = 520, style, bodyStyle, ...rest }) {
  useCfStyles("cf-panel-css", CSS);
  return (
    <section className="cf-panel" style={{ width, ...style }} {...rest}>
      {(title || onClose) && (
        <header className="cf-panel__head">
          {title ? <span className="cf-panel__title">{title}</span> : null}
          {subtitle ? <span className="cf-panel__sub">{subtitle}</span> : null}
          {onClose ? (
            <button className="cf-panel__close" onClick={onClose} aria-label="关闭" title="关闭">×</button>
          ) : null}
        </header>
      )}
      <div className="cf-panel__body" style={bodyStyle}>{children}</div>
    </section>
  );
}
