import React from "react";

export interface CardProps {
  children?: React.ReactNode;
  /** paper = warm parchment · row = dark inset · glass = translucent block. */
  surface?: "paper" | "row" | "glass";
  /** Apply default 10/12px padding. Default true. */
  pad?: boolean;
  /** Add hover affordance. */
  interactive?: boolean;
  /** Dim + desaturate for locked / unavailable state. */
  locked?: boolean;
  onClick?: (e: React.MouseEvent<HTMLDivElement>) => void;
  className?: string;
  style?: React.CSSProperties;
}

/** Surface container: parchment, dark row, or glass. */
export function Card(props: CardProps): JSX.Element;
