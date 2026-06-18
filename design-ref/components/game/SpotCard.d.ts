import React from "react";

export interface SpotCardProps {
  name: string;
  desc: string;
  /** Species collected at this spot. */
  got?: number;
  total?: number;
  unlocked?: boolean;
  /** The spot you're fishing right now (📍 + 当前). */
  current?: boolean;
  /** Active event name, shown for the current spot. */
  event?: string;
  /** Unlock requirement text, shown when locked. */
  unlockText?: string;
  onGo?: () => void;
  style?: React.CSSProperties;
}

/** Fishing-spot card (钓点) — current / available / locked. */
export function SpotCard(props: SpotCardProps): JSX.Element;
