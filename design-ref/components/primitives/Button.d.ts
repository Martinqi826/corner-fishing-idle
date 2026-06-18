import React from "react";

export interface ButtonProps {
  children?: React.ReactNode;
  /** Visual weight. primary = bronze (key action), secondary = glass, ghost = chrome-less. */
  variant?: "primary" | "secondary" | "ghost";
  size?: "sm" | "md" | "lg";
  /** Optional leading icon URL (e.g. coin / sell glyph). */
  icon?: string;
  disabled?: boolean;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  className?: string;
  style?: React.CSSProperties;
}

/**
 * The widget's workhorse button.
 * @startingPoint section="Primitives" subtitle="Bronze / glass / ghost buttons" viewport="700x180"
 */
export function Button(props: ButtonProps): JSX.Element;
