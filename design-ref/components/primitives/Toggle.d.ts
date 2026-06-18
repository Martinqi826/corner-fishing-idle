import React from "react";

export interface ToggleProps {
  checked?: boolean;
  onChange?: (next: boolean) => void;
  /** Optional leading label, shown on the glass surface. */
  label?: string;
  disabled?: boolean;
  style?: React.CSSProperties;
}

/** On/off switch for Settings (mute, focus mode). */
export function Toggle(props: ToggleProps): JSX.Element;
