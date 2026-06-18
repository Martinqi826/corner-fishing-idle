import React from "react";

export interface RoundButtonProps {
  /** PNG face URL (e.g. assets/ui/ui_button_fish.png). */
  icon: string;
  /** Diameter in px. Default 40. */
  size?: number;
  /** Accessible label + tooltip. */
  title?: string;
  /** Optional notification count bubble (e.g. basket count). */
  badge?: string | number;
  onClick?: (e: React.MouseEvent<HTMLButtonElement>) => void;
  style?: React.CSSProperties;
}

/** Round painterly corner-widget button (rod / basket / coin). */
export function RoundButton(props: RoundButtonProps): JSX.Element;
