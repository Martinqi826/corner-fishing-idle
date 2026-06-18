import React from "react";

export interface SliderProps {
  label?: string;
  value: number;
  min?: number;
  max?: number;
  step?: number;
  onChange?: (next: number) => void;
  /** Custom value formatter; defaults to a percentage. */
  format?: (value: number) => string;
  disabled?: boolean;
  style?: React.CSSProperties;
}

/** Labeled value slider — volume / opacity in Settings. */
export function Slider(props: SliderProps): JSX.Element;
