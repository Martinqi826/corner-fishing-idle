import React from "react";

export interface FishIconProps {
  /** Fish/equipment PNG URL. */
  src: string;
  /** Generic tier silhouette to swap in if `src` 404s. */
  fallbackSrc?: string;
  alt?: string;
  /** Box size in px. Default 34. */
  size?: number;
  /** 0–5 rarity tier (drives the frame ring colour). */
  tier?: number;
  /** 0–3 rare variant (0 none · 1 斑斓 · 2 鎏金 · 3 七彩) — adds glow. */
  variant?: number;
  /** Show a tier-coloured frame ring + dark backing. */
  frame?: boolean;
  /** Render undiscovered (grayscale + faded) for the codex. */
  dimmed?: boolean;
  style?: React.CSSProperties;
}

/** Painterly fish/equipment icon with tier frame + variant glow. */
export function FishIcon(props: FishIconProps): JSX.Element;
