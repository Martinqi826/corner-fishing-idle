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
.cf-fishicon{position:relative;display:grid;place-items:center;flex:0 0 auto;
  border-radius:8px;box-sizing:border-box;overflow:hidden;}
.cf-fishicon--frame{background:rgba(0,0,0,0.16);border:1px solid var(--cf-tier,transparent);}
.cf-fishicon img{width:84%;height:84%;object-fit:contain;display:block;
  image-rendering:auto;filter:drop-shadow(0 1px 1px rgba(0,0,0,0.25));}
.cf-fishicon--dimmed img{opacity:0.28;filter:grayscale(1) brightness(0.7);}
.cf-fishicon--v1 img{filter:drop-shadow(0 0 7px rgba(140,217,242,0.85));}
.cf-fishicon--v2 img{animation:cf-variant-shimmer var(--dur-slow) var(--ease-soft) infinite;}
.cf-fishicon--v3 img{filter:drop-shadow(0 0 8px rgba(242,140,242,0.85));}
`;

const TIER_VARS = ["var(--tier-0)","var(--tier-1)","var(--tier-2)","var(--tier-3)","var(--tier-4)","var(--tier-5)"];

/**
 * A fish (or equipment) icon. Optional tier frame ring + rare-variant glow.
 * Falls back to a generic tier silhouette via `fallbackSrc`.
 */
export function FishIcon({ src, fallbackSrc, alt = "", size = 34, tier = 0, variant = 0, frame = false, dimmed = false, className = "", style, ...rest }) {
  useCfStyles("cf-fishicon-css", CSS);
  const cls = [
    "cf-fishicon",
    frame ? "cf-fishicon--frame" : "",
    dimmed ? "cf-fishicon--dimmed" : "",
    variant ? `cf-fishicon--v${variant}` : "",
    className,
  ].filter(Boolean).join(" ");
  return (
    <span
      className={cls}
      style={{ width: size, height: size, "--cf-tier": TIER_VARS[tier] || "transparent", ...style }}
      {...rest}
    >
      <img
        src={src}
        alt={alt}
        onError={fallbackSrc ? (e) => { if (e.currentTarget.src !== fallbackSrc) e.currentTarget.src = fallbackSrc; } : undefined}
      />
    </span>
  );
}
