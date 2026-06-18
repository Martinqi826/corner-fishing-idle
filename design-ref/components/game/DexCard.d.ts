import React from "react";

export interface DexCardProps {
  src: string;
  fallbackSrc?: string;
  name: string;
  tier?: number;
  /** Discovered? Unknown shows a dim "未发现" silhouette. */
  known?: boolean;
  count?: number;
  maxWeight?: number;
  /** Caught ≥10 (✦集齐 badge). */
  collected?: boolean;
  /** Giant specimen recorded. */
  giant?: boolean;
  /** Perfect-quality recorded. */
  perfect?: boolean;
  /** Rare-variant ids seen, e.g. [1,2] → cyan + gold dots. */
  variants?: number[];
  style?: React.CSSProperties;
}

/** Codex (图鉴) grid cell with record + long-haul badges. */
export function DexCard(props: DexCardProps): JSX.Element;
