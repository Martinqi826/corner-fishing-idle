import React from "react";

export interface ProgressBarProps {
  value: number;
  max?: number;
  /** Show centred % label. Default true. */
  showPercent?: boolean;
  /** Optional caption row below (e.g. "80 / 160  奖励 4500 金币"). */
  caption?: React.ReactNode;
  /** Tune track contrast for dark glass vs warm paper. */
  surface?: "glass" | "paper";
  style?: React.CSSProperties;
}

/** Bronze→gold fill bar for weekly/collection progress. */
export function ProgressBar(props: ProgressBarProps): JSX.Element;
