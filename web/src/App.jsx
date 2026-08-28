import { useEffect, useState } from 'react'
import {
  Bell,
  CalendarCheck,
  Car,
  ChevronDown,
  LayoutDashboard,
  LayoutGrid,
  LogOut,
  Menu,
  Moon,
  Search,
  Settings,
  Sun,
  TrendingUp,
  Users as UsersIcon,
  Wallet,
  X,
  Zap,
} from 'lucide-react'

import { admin, notifications } from './data.js'
import { Avatar } from './ui.jsx'
import {
  Bookings,
  Dashboard,
  Parking,
  Revenue,
  Stations,
  Users,
  Vehicles,
  WalletPage,
} from './pages.jsx'

const NAV = [
  { key: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, page: Dashboard },
  { key: 'vehicles', label: 'Vehicles', icon: Car, page: Vehicles },
  { key: 'stations', label: 'Charging Stations', icon: Zap, page: Stations },
  { key: 'parking', label: 'Parking', icon: LayoutGrid, page: Parking },
  { key: 'bookings', label: 'Bookings', icon: CalendarCheck, page: Bookings },
  { key: 'wallet', label: 'Wallet', icon: Wallet, page: WalletPage },
  { key: 'users', label: 'Users', icon: UsersIcon, page: Users },
  { key: 'revenue', label: 'Revenue', icon: TrendingUp, page: Revenue },
]

const TONE_DOT = {
  warn: 'bg-amber-400',
  ok: 'bg-emerald-400',
  info: 'bg-sky-400',
}

function Sidebar({ active, onSelect, open, onClose }) {
  return (
    <>
      {/* Mobile scrim */}
      <div
        onClick={onClose}
        className={`fixed inset-0 z-30 bg-slate-900/40 backdrop-blur-sm transition-opacity lg:hidden ${
          open ? 'opacity-100' : 'pointer-events-none opacity-0'
        }`}
      />
      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-[264px] flex-col bg-ink-900 transition-transform duration-300 lg:translate-x-0 ${
          open ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <div className="flex items-center gap-3 px-6 py-6">
          <div className="grid h-10 w-10 place-items-center rounded-xl bg-gradient-to-br from-brand-400 to-teal-600 shadow-lg shadow-brand-500/20">
            <Zap size={20} strokeWidth={2.6} className="text-white" />
          </div>
          <div className="min-w-0">
            <p className="text-[15px] font-bold tracking-tight text-white">FleetX</p>
            <p className="truncate text-[11px] text-slate-400">
              Smart Mobility & EV
            </p>
          </div>
          <button
            onClick={onClose}
            className="ml-auto text-slate-400 transition hover:text-white lg:hidden"
            aria-label="Close navigation"
          >
            <X size={20} />
          </button>
        </div>

        <p className="px-6 pb-2 pt-2 text-[10px] font-bold uppercase tracking-[0.14em] text-slate-500">
          Operations
        </p>

        <nav className="flex-1 space-y-1 overflow-y-auto px-3">
          {NAV.map((item) => {
            const isActive = item.key === active
            return (
              <button
                key={item.key}
                onClick={() => onSelect(item.key)}
                className={`group flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium transition ${
                  isActive
                    ? 'bg-brand-500/15 text-white ring-1 ring-inset ring-brand-400/30'
                    : 'text-slate-400 hover:bg-white/5 hover:text-white'
                }`}
              >
                <item.icon
                  size={18}
                  strokeWidth={2.1}
                  className={isActive ? 'text-brand-400' : ''}
                />
                <span className="truncate">{item.label}</span>
                {isActive && (
                  <span className="ml-auto h-1.5 w-1.5 rounded-full bg-brand-400" />
                )}
              </button>
            )
          })}
        </nav>

        <div className="p-3">
          <div className="rounded-2xl bg-gradient-to-br from-brand-500/20 to-teal-600/10 p-4 ring-1 ring-inset ring-white/10">
            <p className="text-sm font-semibold text-white">Fleet health</p>
            <p className="mt-0.5 text-xs text-slate-400">
              13 of 15 chargers online
            </p>
            <div className="mt-3 h-1.5 w-full overflow-hidden rounded-full bg-white/10">
              <div className="h-full w-[87%] rounded-full bg-brand-400" />
            </div>
          </div>

          <div className="mt-3 flex items-center gap-2 border-t border-white/5 px-2 pt-3">
            <button className="flex flex-1 items-center gap-2 rounded-lg px-2 py-2 text-sm font-medium text-slate-400 transition hover:text-white">
              <Settings size={17} /> Settings
            </button>
            <button
              className="rounded-lg p-2 text-slate-500 transition hover:text-rose-400"
              aria-label="Sign out"
            >
              <LogOut size={17} />
            </button>
          </div>
        </div>
      </aside>
    </>
  )
}

function Topbar({ title, onMenu, theme, onToggleTheme }) {
  const [bellOpen, setBellOpen] = useState(false)
  const isDark = theme === 'dark'

  return (
    <header className="sticky top-0 z-20 border-b border-slate-200/80 bg-white/85 backdrop-blur-md">
      <div className="flex items-center gap-3 px-4 py-3.5 sm:px-6 lg:px-8">
        <button
          onClick={onMenu}
          className="rounded-lg p-2 text-slate-500 transition hover:bg-slate-100 lg:hidden"
          aria-label="Open navigation"
        >
          <Menu size={20} />
        </button>

        <div className="hidden min-w-0 md:block">
          <p className="truncate text-sm font-semibold text-slate-900">{title}</p>
          <p className="text-xs text-slate-400">FleetX Operations Console</p>
        </div>

        <div className="relative ml-auto w-full max-w-md">
          <Search
            size={17}
            className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400"
          />
          <input
            type="search"
            placeholder="Search vehicles, stations, bookings…"
            className="w-full rounded-xl border border-slate-200 bg-slate-50/70 py-2.5 pl-10 pr-4 text-sm text-slate-700 outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:bg-white focus:ring-4 focus:ring-brand-100"
          />
        </div>

        <button
          onClick={onToggleTheme}
          className="shrink-0 rounded-xl p-2.5 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
          title={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
          aria-label={isDark ? 'Switch to light mode' : 'Switch to dark mode'}
        >
          {isDark ? <Sun size={19} /> : <Moon size={19} />}
        </button>

        <div className="relative shrink-0">
          <button
            onClick={() => setBellOpen((v) => !v)}
            className="relative rounded-xl p-2.5 text-slate-500 transition hover:bg-slate-100 hover:text-slate-900"
            aria-label="Notifications"
          >
            <Bell size={19} />
            <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-rose-500 ring-2 ring-white" />
          </button>

          {bellOpen && (
            <div className="absolute right-0 mt-2 w-80 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-xl shadow-slate-900/10">
              <div className="flex items-center justify-between border-b border-slate-100 px-4 py-3">
                <p className="text-sm font-semibold text-slate-900">Notifications</p>
                <span className="rounded-full bg-brand-50 px-2 py-0.5 text-xs font-semibold text-brand-700">
                  {notifications.length} new
                </span>
              </div>
              <ul className="divide-y divide-slate-100">
                {notifications.map((note) => (
                  <li key={note.id} className="flex gap-3 px-4 py-3 hover:bg-slate-50">
                    <span
                      className={`mt-1.5 h-2 w-2 shrink-0 rounded-full ${TONE_DOT[note.tone]}`}
                    />
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-slate-900">
                        {note.title}
                      </p>
                      <p className="text-xs text-slate-500">{note.body}</p>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>

        <button className="flex shrink-0 items-center gap-2.5 rounded-xl py-1.5 pl-1.5 pr-2 transition hover:bg-slate-100">
          <Avatar name={admin.name} className="h-9 w-9" />
          <span className="hidden text-left sm:block">
            <span className="block text-sm font-semibold leading-tight text-slate-900">
              {admin.name}
            </span>
            <span className="block text-xs leading-tight text-slate-400">
              {admin.email}
            </span>
          </span>
          <ChevronDown size={16} className="hidden text-slate-400 sm:block" />
        </button>
      </div>
    </header>
  )
}

export default function App() {
  const [active, setActive] = useState('dashboard')
  const [navOpen, setNavOpen] = useState(false)
  const [theme, setTheme] = useState(
    () => localStorage.getItem('fleetx.theme') ?? 'light',
  )

  useEffect(() => {
    document.documentElement.classList.toggle('dark', theme === 'dark')
    localStorage.setItem('fleetx.theme', theme)
  }, [theme])

  const current = NAV.find((item) => item.key === active) ?? NAV[0]
  const Page = current.page

  return (
    <div className="min-h-screen">
      <Sidebar
        active={active}
        onSelect={(key) => {
          setActive(key)
          setNavOpen(false)
        }}
        open={navOpen}
        onClose={() => setNavOpen(false)}
      />

      <div className="lg:pl-[264px]">
        <Topbar
          title={current.label}
          onMenu={() => setNavOpen(true)}
          theme={theme}
          onToggleTheme={() =>
            setTheme((value) => (value === 'dark' ? 'light' : 'dark'))
          }
        />
        <main className="mx-auto max-w-[1500px] px-4 py-6 sm:px-6 lg:px-8">
          <Page />
        </main>
        <footer className="px-4 pb-8 text-center text-xs text-slate-400 sm:px-6 lg:px-8">
          FleetX · Smart Mobility & EV Charging Platform · prototype demo data
        </footer>
      </div>
    </div>
  )
}
