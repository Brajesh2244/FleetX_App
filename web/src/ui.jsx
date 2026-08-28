// Small presentation primitives shared by every page.

const TONES = {
  AVAILABLE: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  LIMITED: 'bg-amber-50 text-amber-700 ring-amber-200',
  FULL: 'bg-rose-50 text-rose-700 ring-rose-200',
  OCCUPIED: 'bg-amber-50 text-amber-700 ring-amber-200',
  OUT_OF_SERVICE: 'bg-slate-100 text-slate-600 ring-slate-200',
  ACTIVE: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  IDLE: 'bg-slate-100 text-slate-600 ring-slate-200',
  CHARGING: 'bg-sky-50 text-sky-700 ring-sky-200',
  MAINTENANCE: 'bg-amber-50 text-amber-700 ring-amber-200',
  CONFIRMED: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  PENDING: 'bg-amber-50 text-amber-700 ring-amber-200',
  COMPLETED: 'bg-slate-100 text-slate-600 ring-slate-200',
  CANCELLED: 'bg-rose-50 text-rose-700 ring-rose-200',
  SUCCESS: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  REFUNDED: 'bg-sky-50 text-sky-700 ring-sky-200',
  DRIVER: 'bg-sky-50 text-sky-700 ring-sky-200',
  ADMIN: 'bg-violet-50 text-violet-700 ring-violet-200',
  CREDIT: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  DEBIT: 'bg-rose-50 text-rose-700 ring-rose-200',
}

const LABELS = {
  OUT_OF_SERVICE: 'Out of service',
  AC_SLOW: 'AC slow',
  BHARAT_DC: 'Bharat DC',
}

export function StatusPill({ value, className = '' }) {
  const tone = TONES[value] ?? 'bg-slate-100 text-slate-600 ring-slate-200'
  const label =
    LABELS[value] ??
    value.charAt(0) + value.slice(1).toLowerCase().replaceAll('_', ' ')
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset ${tone} ${className}`}
    >
      <span className="h-1.5 w-1.5 rounded-full bg-current opacity-70" />
      {label}
    </span>
  )
}

export function Card({ children, className = '', ...rest }) {
  return (
    <div
      className={`rounded-2xl border border-slate-200/80 bg-white shadow-[0_1px_2px_rgba(16,24,40,0.04),0_8px_24px_-12px_rgba(16,24,40,0.10)] ${className}`}
      {...rest}
    >
      {children}
    </div>
  )
}

export function SectionHeader({ title, subtitle, action }) {
  return (
    <div className="mb-4 flex items-end justify-between gap-4">
      <div>
        <h2 className="text-base font-semibold tracking-tight text-slate-900">
          {title}
        </h2>
        {subtitle && (
          <p className="mt-0.5 text-sm text-slate-500">{subtitle}</p>
        )}
      </div>
      {action}
    </div>
  )
}

export function PageHeader({ title, subtitle, children }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900">
          {title}
        </h1>
        <p className="mt-1 text-sm text-slate-500">{subtitle}</p>
      </div>
      {children}
    </div>
  )
}

export function StatCard({ icon: Icon, label, value, delta, hint, accent }) {
  const up = delta?.startsWith('+')
  return (
    <Card className="p-5 transition-shadow hover:shadow-[0_1px_2px_rgba(16,24,40,0.04),0_16px_32px_-16px_rgba(16,24,40,0.18)]">
      <div className="flex items-start justify-between">
        <div
          className={`grid h-11 w-11 place-items-center rounded-xl ${accent}`}
        >
          <Icon size={20} strokeWidth={2.2} />
        </div>
        {delta && (
          <span
            className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
              up
                ? 'bg-emerald-50 text-emerald-700'
                : 'bg-rose-50 text-rose-600'
            }`}
          >
            {delta}
          </span>
        )}
      </div>
      <p className="mt-4 text-sm font-medium text-slate-500">{label}</p>
      <p className="mt-1 text-2xl font-bold tracking-tight text-slate-900">
        {value}
      </p>
      {hint && <p className="mt-1 text-xs text-slate-400">{hint}</p>}
    </Card>
  )
}

export function Meter({ value, tone = 'bg-brand-500', className = '' }) {
  return (
    <div className={`h-2 w-full overflow-hidden rounded-full bg-slate-100 ${className}`}>
      <div
        className={`h-full rounded-full ${tone} transition-[width] duration-500`}
        style={{ width: `${Math.max(0, Math.min(100, value))}%` }}
      />
    </div>
  )
}

export function Avatar({ name, className = '' }) {
  const initials = name
    .split(' ')
    .map((part) => part[0])
    .slice(0, 2)
    .join('')
  return (
    <span
      className={`grid place-items-center rounded-full bg-gradient-to-br from-brand-500 to-teal-600 text-xs font-bold text-white ${className}`}
    >
      {initials}
    </span>
  )
}

export function Th({ children, className = '' }) {
  return (
    <th
      className={`whitespace-nowrap px-5 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500 ${className}`}
    >
      {children}
    </th>
  )
}

export function Td({ children, className = '' }) {
  return (
    <td className={`whitespace-nowrap px-5 py-4 text-sm text-slate-600 ${className}`}>
      {children}
    </td>
  )
}
