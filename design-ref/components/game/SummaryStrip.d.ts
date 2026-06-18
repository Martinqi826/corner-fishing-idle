import React from "react";

export interface SummaryStripProps {
  used?: number;
  capacity?: number;
  /** Headline sellable value (omit to hide the right block). */
  value?: number;
  /** Coin glyph URL beside the value. */
  coinIcon?: string;
  capLabel?: string;
  valueLabel?: string;
  style?: React.CSSProperties;
}

/** Bag overview strip — capacity meter + sellable-value readout. */
export function SummaryStrip(props: SummaryStripProps): JSX.Element;
