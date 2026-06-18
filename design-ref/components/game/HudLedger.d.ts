import React from "react";

export interface HudLedgerProps {
  coins?: number;
  used?: number;
  capacity?: number;
  /** Coin glyph URL. */
  coinIcon?: string;
  style?: React.CSSProperties;
}

/** Frosted-glass on-scene HUD capsule: coins + basket capacity meter. */
export function HudLedger(props: HudLedgerProps): JSX.Element;
