import React from "react";

export interface PanelProps {
  /** Header title (serif display). Omit for a chrome-less panel. */
  title?: string;
  /** Right-aligned small subtitle in the header (e.g. a date). */
  subtitle?: string;
  /** Render a close × when provided. */
  onClose?: () => void;
  children?: React.ReactNode;
  /** Panel width in px. Default 520 (canonical). */
  width?: number;
  style?: React.CSSProperties;
  bodyStyle?: React.CSSProperties;
}

/**
 * The floating dark-glass dialog that every menu lives in.
 * @startingPoint section="Surfaces" subtitle="Floating glass panel shell" viewport="560x420"
 */
export function Panel(props: PanelProps): JSX.Element;
