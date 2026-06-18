import React from "react";

/* Shared once-injected stylesheet for the primitives group.
   Plain DOM injection (not a CSS-in-JS lib) so :hover / :active work
   while components stay self-contained and token-driven. */
function useCfStyles(id, css) {
  if (typeof document === "undefined") return;
  if (document.getElementById(id)) return;
  const el = document.createElement("style");
  el.id = id;
  el.textContent = css;
  document.head.appendChild(el);
}

const CSS = `
.cf-btn{
  display:inline-flex;align-items:center;justify-content:center;gap:6px;
  font-family:var(--font-sans);font-weight:var(--w-medium);
  border-radius:var(--r-btn);border:1px solid transparent;cursor:pointer;
  white-space:nowrap;user-select:none;line-height:1;
  transition:background-color var(--dur-fast) var(--ease-calm),
             border-color var(--dur-fast) var(--ease-calm),
             color var(--dur-fast) var(--ease-calm), opacity var(--dur-fast);
}
.cf-btn:focus-visible{outline:2px solid var(--gold);outline-offset:2px;}
.cf-btn--sm{height:24px;padding:0 10px;font-size:var(--fs-xs);}
.cf-btn--md{height:var(--btn-h);padding:0 14px;font-size:var(--fs-sm);}
.cf-btn--lg{height:38px;padding:0 22px;font-size:var(--fs-body);}

.cf-btn--primary{background:var(--btn-primary-bg);color:var(--btn-primary-fg);
  border-color:rgba(255,222,140,0.28);font-weight:var(--w-bold);}
.cf-btn--primary:hover{background:var(--btn-primary-bg-hover);}
.cf-btn--primary:active{background:var(--btn-primary-bg-press);}

.cf-btn--secondary{background:var(--btn-secondary-bg);color:var(--btn-secondary-fg);
  border-color:rgba(214,205,174,0.22);}
.cf-btn--secondary:hover{background:var(--btn-secondary-bg-hover);}
.cf-btn--secondary:active{background:rgba(64,64,56,0.95);}

.cf-btn--ghost{background:transparent;color:var(--text-muted-glass);}
.cf-btn--ghost:hover{background:var(--glass-row-hover);color:var(--text-on-glass);}

.cf-btn:disabled{opacity:0.45;cursor:default;pointer-events:none;}
.cf-btn__icon{width:1.05em;height:1.05em;object-fit:contain;display:block;}
`;

/**
 * Bronze / glass / ghost button — the workhorse control of the widget.
 * Primary = warm bronze with dark ink (sell, deliver, upgrade).
 */
export function Button({
  children,
  variant = "secondary",
  size = "md",
  icon,
  disabled = false,
  onClick,
  className = "",
  style,
  ...rest
}) {
  useCfStyles("cf-primitives-css", CSS);
  return (
    <button
      type="button"
      className={`cf-btn cf-btn--${variant} cf-btn--${size} ${className}`}
      disabled={disabled}
      onClick={onClick}
      style={style}
      {...rest}
    >
      {icon ? <img className="cf-btn__icon" src={icon} alt="" aria-hidden="true" /> : null}
      {children}
    </button>
  );
}
