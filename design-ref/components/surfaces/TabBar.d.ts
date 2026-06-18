import React from "react";

export interface TabBarProps {
  /** Tab labels, or {label} objects. */
  tabs: Array<string | { label: string }>;
  active?: number;
  onChange?: (index: number) => void;
  /** pill = filled pills (default) · underline = light primary nav. */
  variant?: "pill" | "underline";
  /** underline only: a right-aligned overflow item, e.g. "更多 ▾". */
  overflow?: string;
  onOverflow?: () => void;
  style?: React.CSSProperties;
}

/** Tab bar — dense pill list nav, or a light underline primary nav. */
export function TabBar(props: TabBarProps): JSX.Element;
