// Charts drawn with inline SVG / CSS - no chart library is installed and the
// brief asked not to add one.

import { moneyShort } from './data.js'

/** Smooth-ish area + line chart for the weekly revenue trend. */
export function RevenueChart({ series, height = 220 }) {
  const width = 640
  const pad = { top: 16, right: 8, bottom: 28, left: 8 }
  const max = Math.max(...series.map((d) => d.revenue)) * 1.12
  const innerW = width - pad.left - pad.right
  const innerH = height - pad.top - pad.bottom
  const step = innerW / (series.length - 1)

  const points = series.map((d, i) => ({
    x: pad.left + i * step,
    y: pad.top + innerH - (d.revenue / max) * innerH,
    ...d,
  }))

  const line = points
    .map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x.toFixed(1)},${p.y.toFixed(1)}`)
    .join(' ')
  const area =
    `${line} L${points.at(-1).x.toFixed(1)},${pad.top + innerH} ` +
    `L${points[0].x.toFixed(1)},${pad.top + innerH} Z`

  return (
    <div className="w-full">
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="h-[220px] w-full"
        preserveAspectRatio="none"
        role="img"
        aria-label="Weekly revenue trend"
      >
        <defs>
          <linearGradient id="fx-area" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#10b981" stopOpacity="0.28" />
            <stop offset="100%" stopColor="#10b981" stopOpacity="0" />
          </linearGradient>
        </defs>

        {[0, 0.25, 0.5, 0.75, 1].map((t) => (
          <line
            key={t}
            x1={pad.left}
            x2={width - pad.right}
            y1={pad.top + innerH * t}
            y2={pad.top + innerH * t}
            stroke="#eef2f6"
            strokeWidth="1"
          />
        ))}

        <path d={area} fill="url(#fx-area)" />
        <path
          d={line}
          fill="none"
          stroke="#10b981"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          vectorEffect="non-scaling-stroke"
        />

        {points.map((p) => (
          <g key={p.label}>
            <circle cx={p.x} cy={p.y} r="4.5" fill="#fff" stroke="#10b981" strokeWidth="2.5" />
            <text
              x={p.x}
              y={height - 8}
              textAnchor="middle"
              className="fill-slate-400"
              style={{ fontSize: 11, fontWeight: 600 }}
            >
              {p.label}
            </text>
          </g>
        ))}
      </svg>

      <div className="mt-2 flex flex-wrap items-center justify-between gap-2 text-xs text-slate-400">
        <span>Peak {moneyShort(Math.max(...series.map((d) => d.revenue)))} on Saturday</span>
        <span className="flex items-center gap-1.5">
          <span className="h-2 w-2 rounded-full bg-brand-500" /> Revenue
        </span>
      </div>
    </div>
  )
}

/** CSS bar chart for bookings per day. */
export function BookingsBars({ series }) {
  const max = Math.max(...series.map((d) => d.bookings))
  return (
    <div className="flex h-[180px] items-end gap-2.5">
      {series.map((d) => (
        <div key={d.label} className="group flex flex-1 flex-col items-center gap-2">
          <span className="text-xs font-semibold text-slate-400 group-hover:text-slate-700">
            {d.bookings}
          </span>
          <div className="flex w-full flex-1 items-end">
            <div
              className="w-full rounded-t-lg bg-gradient-to-t from-teal-500/80 to-brand-400 transition-all duration-500 group-hover:from-teal-600 group-hover:to-brand-500"
              style={{ height: `${(d.bookings / max) * 100}%` }}
            />
          </div>
          <span className="text-xs font-medium text-slate-400">{d.label}</span>
        </div>
      ))}
    </div>
  )
}

/** Horizontal share bars for the charger-type mix. */
export function MixBars({ items }) {
  const tones = ['bg-brand-500', 'bg-teal-500', 'bg-sky-500', 'bg-slate-300']
  return (
    <ul className="space-y-4">
      {items.map((item, i) => (
        <li key={item.label}>
          <div className="mb-1.5 flex items-baseline justify-between text-sm">
            <span className="font-medium text-slate-700">{item.label}</span>
            <span className="font-semibold text-slate-900">{item.value}%</span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full bg-slate-100">
            <div
              className={`h-full rounded-full ${tones[i % tones.length]} transition-[width] duration-500`}
              style={{ width: `${item.value}%` }}
            />
          </div>
        </li>
      ))}
    </ul>
  )
}
