import React from "react";

export interface HudChipProps {
  children?: React.ReactNode;
  /** Optional leading icon URL (coin / capacity / event glyph). */
  icon?: string;
  /** Colour intent — default/muted, or status (gold/positive/warn/water). */
  tone?: "default" | "muted" | "gold" | "positive" | "warn" | "water" | string;
  /** Font size in px. Default 14. */
  size?: number;
  /** When provided, the chip is clickable (opens a panel). */
  onClick?: () => void;
  style?: React.CSSProperties;
}

/** A flat HUD line floating over the scene (coin ledger, spot, order). */
export function HudChip(props: HudChipProps): JSX.Element;
