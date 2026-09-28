import { colors } from '@/src/theme/colors';

type Props = Readonly<{ energy?: number }>;

/** Atmospheric RideBuddy network — not a search map. */
export function MovementField({ energy = 0 }: Props) {
  const lit = Math.min(7, Math.max(3, energy || 3));

  return (
    <svg
      viewBox="0 0 800 560"
      width="100%"
      height="100%"
      preserveAspectRatio="xMidYMid slice"
      style={{ display: 'block' }}>
      <defs>
        <linearGradient id="rbSky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor="#C5DAFF" />
          <stop offset="42%" stopColor="#E3EEF8" />
          <stop offset="78%" stopColor="#F3F7FB" />
          <stop offset="100%" stopColor={colors.surface} />
        </linearGradient>
        <radialGradient id="rbGlowB" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={colors.brandBlue} stopOpacity="0.35" />
          <stop offset="100%" stopColor={colors.brandBlue} stopOpacity="0" />
        </radialGradient>
        <radialGradient id="rbGlowO" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor={colors.brandOrange} stopOpacity="0.32" />
          <stop offset="100%" stopColor={colors.brandOrange} stopOpacity="0" />
        </radialGradient>
        <filter id="rbSoft">
          <feGaussianBlur stdDeviation="18" />
        </filter>
      </defs>

      <rect width="800" height="560" fill="url(#rbSky)" />
      <ellipse cx="160" cy="150" rx="150" ry="70" fill="#D3E3F6" opacity="0.7" filter="url(#rbSoft)" />
      <ellipse cx="620" cy="240" rx="190" ry="90" fill="#D8E6F7" opacity="0.55" filter="url(#rbSoft)" />
      <ellipse cx="300" cy="380" rx="160" ry="60" fill="#D6E4F5" opacity="0.4" filter="url(#rbSoft)" />

      {STREETS.map((d, i) => (
        <path key={`s${i}`} d={d} fill="none" stroke="#94A3B8" strokeWidth="0.6" opacity="0.18" />
      ))}

      <path
        d="M30 390 C 150 230, 270 430, 410 250 S 630 150, 790 300"
        fill="none"
        stroke={colors.brandBlue}
        strokeWidth="3.2"
        strokeLinecap="round"
        opacity="0.55"
      />
      <path
        d="M10 210 C 170 290, 290 70, 470 210 S 690 370, 800 190"
        fill="none"
        stroke={colors.brandOrange}
        strokeWidth="2.6"
        strokeLinecap="round"
        opacity="0.48"
      />
      <path
        d="M80 130 C 210 170, 250 320, 390 320 S 610 250, 760 430"
        fill="none"
        stroke={colors.brandBlue}
        strokeWidth="2"
        strokeLinecap="round"
        opacity="0.26"
      />
      <path
        d="M220 80 C 340 140, 380 40, 520 120 S 700 80, 780 160"
        fill="none"
        stroke={colors.brandOrange}
        strokeWidth="1.6"
        strokeLinecap="round"
        opacity="0.22"
      />

      {NODES.slice(0, lit).map((n) => (
        <g key={n.id}>
          <circle cx={n.x} cy={n.y} r="16" fill={n.glow} />
          <circle cx={n.x} cy={n.y} r="5.5" fill={n.fill} />
        </g>
      ))}
    </svg>
  );
}

const STREETS = [
  'M0 120 H800',
  'M0 220 H800',
  'M0 320 H800',
  'M0 420 H800',
  'M120 0 V560',
  'M260 0 V560',
  'M400 0 V560',
  'M540 0 V560',
  'M680 0 V560',
];

const NODES = [
  { id: 'a', x: 138, y: 276, fill: colors.brandBlue, glow: 'url(#rbGlowB)' },
  { id: 'b', x: 318, y: 318, fill: colors.brandOrange, glow: 'url(#rbGlowO)' },
  { id: 'c', x: 428, y: 246, fill: colors.brandBlue, glow: 'url(#rbGlowB)' },
  { id: 'd', x: 568, y: 208, fill: colors.brandOrange, glow: 'url(#rbGlowO)' },
  { id: 'e', x: 688, y: 268, fill: colors.brandBlue, glow: 'url(#rbGlowB)' },
  { id: 'f', x: 236, y: 168, fill: colors.brandOrange, glow: 'url(#rbGlowO)' },
  { id: 'g', x: 500, y: 360, fill: colors.brandBlue, glow: 'url(#rbGlowB)' },
];
