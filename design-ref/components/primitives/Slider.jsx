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
.cf-slider{display:flex;flex-direction:column;gap:6px;font-family:var(--font-sans);}
.cf-slider__top{display:flex;justify-content:space-between;align-items:baseline;
  font-size:var(--fs-xs);}
.cf-slider__label{color:var(--text-muted-glass);}
.cf-slider__val{color:var(--gold);font-variant-numeric:tabular-nums;}
.cf-slider input[type=range]{
  -webkit-appearance:none;appearance:none;width:100%;height:6px;border-radius:999px;
  background:rgba(0,0,0,0.34);outline:none;cursor:pointer;margin:6px 0;
}
.cf-slider input[type=range]::-webkit-slider-thumb{
  -webkit-appearance:none;appearance:none;width:16px;height:16px;border-radius:50%;
  background:#F3ECDC;border:1px solid var(--bronze);box-shadow:0 1px 3px rgba(0,0,0,0.45);
  transition:transform var(--dur-fast) var(--ease-calm);
}
.cf-slider input[type=range]::-webkit-slider-thumb:hover{transform:scale(1.12);}
.cf-slider input[type=range]::-moz-range-thumb{
  width:16px;height:16px;border-radius:50%;background:#F3ECDC;
  border:1px solid var(--bronze);box-shadow:0 1px 3px rgba(0,0,0,0.45);
}
.cf-slider--disabled{opacity:0.5;pointer-events:none;}
`;

/** Labeled value slider — volume / opacity controls in Settings. */
export function Slider({
  label,
  value,
  min = 0,
  max = 100,
  step = 1,
  onChange,
  format,
  disabled = false,
  style,
}) {
  useCfStyles("cf-slider-css", CSS);
  const display = format ? format(value) : `${Math.round((value / (max - min)) * 100)}%`;
  return (
    <div className={`cf-slider${disabled ? " cf-slider--disabled" : ""}`} style={style}>
      <div className="cf-slider__top">
        <span className="cf-slider__label">{label}</span>
        <span className="cf-slider__val">{display}</span>
      </div>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        disabled={disabled}
        onChange={(e) => onChange && onChange(Number(e.target.value))}
      />
    </div>
  );
}
