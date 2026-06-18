import React from "react";

export interface FishRowProps {
  src: string;
  fallbackSrc?: string;
  name: string;
  /** 0–5 rarity tier (colours name, frame ring + rail). */
  tier?: number;
  /** 0–3 rare variant (◆ gem, coloured name, glow, pill, rail). */
  variant?: number;
  /** 0–3 quality stars. */
  quality?: number;
  weight?: number;
  /** Size tag, e.g. "大" → 大物 pill, or "巨物". */
  sizeTag?: string;
  /** Favourite-locked (kept from selling/delivery). */
  locked?: boolean;
  /** Sell value shown on the coin pill. */
  value?: number;
  /** Optional coin glyph URL shown inside the price pill. */
  coinIcon?: string;
  /** Force the tinted high-emphasis row (defaults to tier≥4 or variant≥1). */
  emphasis?: boolean;
  onSell?: () => void;
  onToggleLock?: () => void;
  style?: React.CSSProperties;
}

/**
 * Rich single-row basket entry — framed icon, tier rail, tags, lock + coin price.
 * @startingPoint section="Game" subtitle="Rich basket fish row" viewport="480x66"
 */
export function FishRow(props: FishRowProps): JSX.Element;
