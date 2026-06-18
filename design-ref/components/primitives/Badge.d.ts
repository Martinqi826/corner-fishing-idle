import React from "react";

export type BadgeTone =
  | "tier-0" | "tier-1" | "tier-2" | "tier-3" | "tier-4" | "tier-5"
  | "variant-1" | "variant-2" | "variant-3"
  | "gold" | "positive" | "merchant" | "rust" | "neutral"
  | string;

export interface BadgeProps {
  children?: React.ReactNode;
  /** Semantic colour — tier, variant, or status. */
  tone?: BadgeTone;
  /** text = coloured label · pill = filled · outline = hollow. */
  variant?: "text" | "pill" | "outline";
  /** Add a warm-ink outline so coloured text reads on parchment. */
  legible?: boolean;
  style?: React.CSSProperties;
}

/** Rarity / status / variant badge. */
export function Badge(props: BadgeProps): JSX.Element;
