import { useMemo, useState } from 'react'
import {
  ArrowUpRight,
  BatteryCharging,
  Car,
  Clock,
  Gauge,
  IndianRupee,
  MapPin,
  Plug,
  Star,
  TrendingUp,
  Users as UsersIcon,
  Zap,
} from 'lucide-react'

import {
  bookings,
  dateLabel,
  energyMix,
  money,
  moneyShort,
  parkingSlots,
  prettyEnum,
  revenueSeries,
  stations,
  stats,
  timeLabel,
  transactions,
  users,
  vehicles,
  wallets,
} from './data.js'
import { BookingsBars, MixBars, RevenueChart } from './charts.jsx'
import {
  Avatar,
  Card,
  Meter,
  PageHeader,
  SectionHeader,
  StatCard,
  StatusPill,
  Td,
  Th,
} from './ui.jsx'

const batteryTone = (pct) =>
  pct >= 60 ? 'bg-brand-500' : pct >= 30 ? 'bg-amber-500' : 'bg-rose-500'

// ------------------------------------------------------------------ dashboard

export function Dashboard() {
  return (
    <>
      <PageHeader
        title="Fleet overview"
        subtitle="Live snapshot of vehicles, charging stations and bookings across Bengaluru."
      >
        <div className="flex items-center gap-2">
          <span className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 text-xs font-semibold text-slate-600 ring-1 ring-slate-200">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-brand-400 opacity-75" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-brand-500" />
            </span>
            Live
          </span>
          <button className="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800">
            Export report
          </button>
        </div>
      </PageHeader>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          icon={Car}
          label="Total vehicles"
          value={stats.vehicles}
          delta="+2 this week"
          hint={`${vehicles.filter((v) => v.status === 'ACTIVE').length} active right now`}
          accent="bg-brand-50 text-brand-600"
        />
        <StatCard
          icon={Zap}
          label="Charging stations"
          value={stats.stations}
          delta="+1 this month"
          hint={`${stats.chargersOnline}/${stats.chargersTotal} chargers online`}
          accent="bg-teal-50 text-teal-600"
        />
        <StatCard
          icon={Clock}
          label="Active bookings"
          value={stats.activeBookings}
          delta="+4 today"
          hint={`${bookings.filter((b) => b.status === 'PENDING').length} awaiting payment`}
          accent="bg-sky-50 text-sky-600"
        />
        <StatCard
          icon={IndianRupee}
          label="Revenue collected"
          value={moneyShort(stats.revenue)}
          delta="+18.4%"
          hint="Settled payments, all time"
          accent="bg-violet-50 text-violet-600"
        />
      </div>

      <div className="mt-5 grid grid-cols-1 gap-5 xl:grid-cols-3">
        <Card className="p-5 xl:col-span-2">
          <SectionHeader
            title="Revenue trend"
            subtitle="Last 7 days · all stations"
            action={
              <span className="inline-flex items-center gap-1 text-sm font-semibold text-brand-600">
                <TrendingUp size={16} /> +18.4%
              </span>
            }
          />
          <RevenueChart series={revenueSeries} />
        </Card>

        <Card className="p-5">
          <SectionHeader title="Charger type mix" subtitle="Share of sessions" />
          <MixBars items={energyMix} />
          <div className="mt-6 rounded-xl bg-slate-50 p-4">
            <p className="text-xs font-semibold uppercase tracking-wider text-slate-400">
              Utilisation
            </p>
            <div className="mt-2 flex items-baseline gap-2">
              <span className="text-2xl font-bold text-slate-900">68%</span>
              <span className="text-xs font-semibold text-brand-600">
                +6% vs last week
              </span>
            </div>
            <Meter value={68} className="mt-3" />
          </div>
        </Card>
      </div>

      <div className="mt-5 grid grid-cols-1 gap-5 xl:grid-cols-3">
        <Card className="p-5">
          <SectionHeader title="Bookings per day" subtitle="Last 7 days" />
          <BookingsBars series={revenueSeries} />
        </Card>

        <Card className="p-5 xl:col-span-2">
          <SectionHeader
            title="Station availability"
            subtitle="Chargers free right now"
            action={
              <button className="inline-flex items-center gap-1 text-sm font-semibold text-brand-600 hover:text-brand-700">
                View all <ArrowUpRight size={15} />
              </button>
            }
          />
          <ul className="divide-y divide-slate-100">
            {stations.map((station) => (
              <li key={station.id} className="flex items-center gap-4 py-3">
                <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-600">
                  <Zap size={18} strokeWidth={2.2} />
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-slate-900">
                    {station.name}
                  </p>
                  <p className="truncate text-xs text-slate-400">
                    {station.availableChargers}/{station.totalChargers} chargers ·{' '}
                    {station.availableSlots}/{station.totalSlots} parking
                  </p>
                </div>
                <div className="hidden w-32 sm:block">
                  <Meter
                    value={(station.availableChargers / station.totalChargers) * 100}
                    tone={
                      station.status === 'FULL'
                        ? 'bg-rose-500'
                        : station.status === 'LIMITED'
                          ? 'bg-amber-500'
                          : 'bg-brand-500'
                    }
                  />
                </div>
                <StatusPill value={station.status} />
              </li>
            ))}
          </ul>
        </Card>
      </div>

      <div className="mt-5">
        <BookingsTable
          title="Recent bookings"
          subtitle="Latest charging sessions across the fleet"
          rows={bookings.slice(0, 5)}
        />
      </div>
    </>
  )
}

// ------------------------------------------------------------------- vehicles

export function Vehicles() {
  return (
    <>
      <PageHeader
        title="Vehicles"
        subtitle={`${vehicles.length} EVs registered by ${stats.drivers} drivers.`}
      >
        <button className="rounded-xl bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-700">
          Add vehicle
        </button>
      </PageHeader>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
        {vehicles.map((vehicle) => (
          <Card key={vehicle.id} className="p-5">
            <div className="flex items-start justify-between gap-3">
              <div className="flex items-center gap-3">
                <div className="grid h-11 w-11 place-items-center rounded-xl bg-slate-900 text-white">
                  <Car size={20} strokeWidth={2.2} />
                </div>
                <div>
                  <p className="font-semibold tracking-tight text-slate-900">
                    {vehicle.vehicleNumber}
                  </p>
                  <p className="text-xs text-slate-500">{vehicle.model}</p>
                </div>
              </div>
              <StatusPill value={vehicle.status} />
            </div>

            <div className="mt-5">
              <div className="mb-1.5 flex items-baseline justify-between">
                <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-500">
                  <BatteryCharging size={14} /> Battery
                </span>
                <span className="text-sm font-bold text-slate-900">
                  {vehicle.battery}%
                </span>
              </div>
              <Meter value={vehicle.battery} tone={batteryTone(vehicle.battery)} />
            </div>

            <dl className="mt-5 grid grid-cols-3 gap-3 rounded-xl bg-slate-50 p-3 text-center">
              <div>
                <dt className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                  Range
                </dt>
                <dd className="mt-0.5 text-sm font-bold text-slate-900">
                  {vehicle.range} km
                </dd>
              </div>
              <div className="border-x border-slate-200">
                <dt className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                  Capacity
                </dt>
                <dd className="mt-0.5 text-sm font-bold text-slate-900">
                  {vehicle.batteryCapacity} kWh
                </dd>
              </div>
              <div>
                <dt className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                  Odometer
                </dt>
                <dd className="mt-0.5 text-sm font-bold text-slate-900">
                  {(vehicle.odometer / 1000).toFixed(1)}k
                </dd>
              </div>
            </dl>

            <div className="mt-4 flex items-center justify-between border-t border-slate-100 pt-4">
              <span className="inline-flex items-center gap-2 text-xs text-slate-500">
                <Avatar name={vehicle.owner} className="h-6 w-6" />
                {vehicle.owner}
              </span>
              <span className="rounded-md bg-slate-100 px-2 py-0.5 text-[11px] font-semibold text-slate-600">
                {vehicle.type}
              </span>
            </div>
          </Card>
        ))}
      </div>
    </>
  )
}

// ------------------------------------------------------------------- stations

export function Stations() {
  const [filter, setFilter] = useState('ALL')
  const shown = useMemo(
    () => (filter === 'ALL' ? stations : stations.filter((s) => s.status === filter)),
    [filter],
  )
  const tabs = ['ALL', 'AVAILABLE', 'LIMITED', 'FULL']

  return (
    <>
      <PageHeader
        title="Charging stations"
        subtitle={`${stations.length} stations · ${stats.chargersOnline} of ${stats.chargersTotal} chargers online.`}
      >
        <div className="flex rounded-xl bg-white p-1 ring-1 ring-slate-200">
          {tabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setFilter(tab)}
              className={`rounded-lg px-3 py-1.5 text-xs font-semibold capitalize transition ${
                filter === tab
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              {tab.toLowerCase()}
            </button>
          ))}
        </div>
      </PageHeader>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2 2xl:grid-cols-3">
        {shown.map((station) => (
          <Card key={station.id} className="flex flex-col p-5">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <p className="truncate font-semibold tracking-tight text-slate-900">
                  {station.name}
                </p>
                <p className="mt-1 flex items-start gap-1.5 text-xs text-slate-500">
                  <MapPin size={13} className="mt-0.5 shrink-0" />
                  <span className="line-clamp-2">{station.address}</span>
                </p>
              </div>
              <StatusPill value={station.status} />
            </div>

            <div className="mt-4 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs font-medium text-slate-500">
              <span className="inline-flex items-center gap-1 text-amber-600">
                <Star size={13} fill="currentColor" /> {station.rating}
              </span>
              <span className="inline-flex items-center gap-1">
                <MapPin size={13} /> {station.distance} km
              </span>
              <span className="inline-flex items-center gap-1">
                <Clock size={13} /> {station.hours}
              </span>
            </div>

            <div className="mt-4 grid grid-cols-2 gap-3">
              <div className="rounded-xl bg-brand-50/70 p-3">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-brand-700/70">
                  Chargers free
                </p>
                <p className="mt-0.5 text-lg font-bold text-brand-700">
                  {station.availableChargers}
                  <span className="text-sm font-semibold text-brand-600/60">
                    /{station.totalChargers}
                  </span>
                </p>
              </div>
              <div className="rounded-xl bg-slate-50 p-3">
                <p className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                  Parking free
                </p>
                <p className="mt-0.5 text-lg font-bold text-slate-800">
                  {station.availableSlots}
                  <span className="text-sm font-semibold text-slate-400">
                    /{station.totalSlots}
                  </span>
                </p>
              </div>
            </div>

            <ul className="mt-4 space-y-2 border-t border-slate-100 pt-4">
              {station.chargers.map((charger) => (
                <li key={charger.code} className="flex items-center gap-3">
                  <span className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-slate-100 text-slate-500">
                    <Plug size={15} strokeWidth={2.2} />
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold text-slate-800">
                      {charger.code} · {prettyEnum(charger.type)}
                    </p>
                    <p className="text-xs text-slate-400">
                      {charger.power} kW · {money(charger.price)}/kWh
                    </p>
                  </div>
                  <StatusPill value={charger.status} />
                </li>
              ))}
            </ul>

            <button className="mt-5 w-full rounded-xl bg-slate-900 py-2.5 text-sm font-semibold text-white transition hover:bg-slate-800">
              Manage station
            </button>
          </Card>
        ))}
      </div>
    </>
  )
}

// -------------------------------------------------------------------- parking

export function Parking() {
  return (
    <>
      <PageHeader
        title="Parking"
        subtitle={`${stats.slotsFree} of ${stats.slotsTotal} slots free across ${stations.length} stations.`}
      />
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2 2xl:grid-cols-3">
        {stations.map((station) => {
          const slots = parkingSlots.filter((s) => s.stationId === station.id)
          const free = slots.filter((s) => !s.occupied).length
          return (
            <Card key={station.id} className="p-5">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <p className="truncate font-semibold tracking-tight text-slate-900">
                    {station.name}
                  </p>
                  <p className="mt-0.5 text-xs text-slate-500">
                    {free} of {slots.length} slots free
                  </p>
                </div>
                <StatusPill
                  value={free === 0 ? 'FULL' : free * 2 <= slots.length ? 'LIMITED' : 'AVAILABLE'}
                />
              </div>

              <div className="mt-4 grid grid-cols-4 gap-2.5">
                {slots.map((slot) => (
                  <div
                    key={slot.id}
                    className={`rounded-xl border py-3 text-center transition ${
                      slot.occupied
                        ? 'border-slate-200 bg-slate-50 text-slate-400'
                        : 'border-brand-200 bg-brand-50 text-brand-700'
                    }`}
                  >
                    <p className="text-sm font-bold">{slot.slotNumber}</p>
                    <p className="mt-0.5 text-[10px] font-semibold uppercase tracking-wider">
                      {slot.occupied ? 'Taken' : 'Free'}
                    </p>
                  </div>
                ))}
              </div>

              <Meter value={(free / slots.length) * 100} className="mt-4" />
            </Card>
          )
        })}
      </div>
    </>
  )
}

// ------------------------------------------------------------------- bookings

function BookingsTable({ title, subtitle, rows }) {
  return (
    <Card className="overflow-hidden">
      <div className="px-5 pt-5">
        <SectionHeader
          title={title}
          subtitle={subtitle}
          action={
            <button className="inline-flex items-center gap-1 text-sm font-semibold text-brand-600 hover:text-brand-700">
              View all <ArrowUpRight size={15} />
            </button>
          }
        />
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[900px] border-collapse">
          <thead className="bg-slate-50/80">
            <tr className="border-y border-slate-100">
              <Th>Booking</Th>
              <Th>Vehicle</Th>
              <Th>Station</Th>
              <Th>Date</Th>
              <Th>Time</Th>
              <Th className="text-right">Amount</Th>
              <Th>Status</Th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {rows.map((row) => (
              <tr key={row.id} className="transition hover:bg-slate-50/70">
                <Td>
                  <div className="flex items-center gap-3">
                    <Avatar name={row.user} className="h-8 w-8" />
                    <div>
                      <p className="font-semibold text-slate-900">{row.reference}</p>
                      <p className="text-xs text-slate-400">{row.user}</p>
                    </div>
                  </div>
                </Td>
                <Td>
                  <p className="font-medium text-slate-800">{row.vehicleNumber}</p>
                  <p className="text-xs text-slate-400">{row.charger}</p>
                </Td>
                <Td>
                  <p className="font-medium text-slate-800">{row.station}</p>
                  <p className="text-xs text-slate-400">Parking {row.slot}</p>
                </Td>
                <Td>{dateLabel(row.date)}</Td>
                <Td>
                  {timeLabel(row.start)} – {timeLabel(row.end)}
                </Td>
                <Td className="text-right font-semibold text-slate-900">
                  {money(row.amount)}
                </Td>
                <Td>
                  <div className="flex items-center gap-2">
                    <StatusPill value={row.status} />
                    <StatusPill value={row.payment} />
                  </div>
                </Td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  )
}

export function Bookings() {
  const [filter, setFilter] = useState('ALL')
  const tabs = ['ALL', 'CONFIRMED', 'PENDING', 'COMPLETED', 'CANCELLED']
  const rows = filter === 'ALL' ? bookings : bookings.filter((b) => b.status === filter)

  return (
    <>
      <PageHeader
        title="Bookings"
        subtitle={`${bookings.length} sessions · ${stats.activeBookings} active · ${money(stats.revenue)} collected.`}
      >
        <div className="flex flex-wrap rounded-xl bg-white p-1 ring-1 ring-slate-200">
          {tabs.map((tab) => (
            <button
              key={tab}
              onClick={() => setFilter(tab)}
              className={`rounded-lg px-3 py-1.5 text-xs font-semibold capitalize transition ${
                filter === tab
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-500 hover:text-slate-900'
              }`}
            >
              {tab.toLowerCase()}
            </button>
          ))}
        </div>
      </PageHeader>

      <BookingsTable
        title="All bookings"
        subtitle={`${rows.length} matching ${rows.length === 1 ? 'session' : 'sessions'}`}
        rows={rows}
      />
    </>
  )
}

// --------------------------------------------------------------------- wallet

export function WalletPage() {
  const total = wallets.reduce((sum, w) => sum + w.balance, 0)
  return (
    <>
      <PageHeader
        title="Wallet"
        subtitle="Prepaid balances and the simulated transaction ledger."
      />

      <div className="grid grid-cols-1 gap-5 xl:grid-cols-3">
        <div className="space-y-4">
          <Card className="overflow-hidden border-0 bg-gradient-to-br from-brand-600 via-emerald-600 to-teal-700 p-6 text-white">
            <p className="text-xs font-semibold uppercase tracking-wider text-white/70">
              Total float held
            </p>
            <p className="mt-2 text-3xl font-bold tracking-tight">{money(total)}</p>
            <p className="mt-1 text-sm text-white/70">
              Across {wallets.length} FleetX wallets
            </p>
            <div className="mt-6 flex gap-2">
              <button className="flex-1 rounded-xl bg-white/15 py-2.5 text-sm font-semibold backdrop-blur transition hover:bg-white/25">
                Recharge
              </button>
              <button className="flex-1 rounded-xl bg-white py-2.5 text-sm font-semibold text-brand-700 transition hover:bg-white/90">
                Statement
              </button>
            </div>
          </Card>

          {wallets.map((wallet) => (
            <Card key={wallet.email} className="flex items-center gap-3 p-4">
              <Avatar name={wallet.user} className="h-10 w-10" />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-slate-900">
                  {wallet.user}
                </p>
                <p className="truncate text-xs text-slate-400">{wallet.email}</p>
              </div>
              <p className="text-sm font-bold text-slate-900">{money(wallet.balance)}</p>
            </Card>
          ))}
        </div>

        <Card className="p-5 xl:col-span-2">
          <SectionHeader
            title="Transaction ledger"
            subtitle="Most recent first · simulated payments"
          />
          <ul className="divide-y divide-slate-100">
            {transactions.map((tx) => (
              <li key={tx.id} className="flex items-center gap-4 py-3.5">
                <span
                  className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl ${
                    tx.type === 'CREDIT'
                      ? 'bg-emerald-50 text-emerald-600'
                      : 'bg-rose-50 text-rose-600'
                  }`}
                >
                  <IndianRupee size={17} strokeWidth={2.4} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-slate-900">
                    {tx.note}
                  </p>
                  <p className="text-xs text-slate-400">
                    {tx.user} · {tx.when}
                  </p>
                </div>
                <p
                  className={`text-sm font-bold ${
                    tx.type === 'CREDIT' ? 'text-emerald-600' : 'text-rose-600'
                  }`}
                >
                  {tx.type === 'CREDIT' ? '+' : '−'}
                  {money(tx.amount)}
                </p>
              </li>
            ))}
          </ul>
        </Card>
      </div>
    </>
  )
}

// ---------------------------------------------------------------------- users

export function Users() {
  return (
    <>
      <PageHeader
        title="Users"
        subtitle={`${users.length} accounts · ${stats.drivers} drivers, 1 admin.`}
      >
        <button className="rounded-xl bg-brand-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-brand-700">
          Invite user
        </button>
      </PageHeader>

      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] border-collapse">
            <thead className="bg-slate-50/80">
              <tr className="border-b border-slate-100">
                <Th>Name</Th>
                <Th>Contact</Th>
                <Th>Role</Th>
                <Th className="text-right">Vehicles</Th>
                <Th className="text-right">Bookings</Th>
                <Th>Status</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {users.map((user) => (
                <tr key={user.id} className="transition hover:bg-slate-50/70">
                  <Td>
                    <div className="flex items-center gap-3">
                      <Avatar name={user.name} className="h-9 w-9" />
                      <p className="font-semibold text-slate-900">{user.name}</p>
                    </div>
                  </Td>
                  <Td>
                    <p className="text-slate-800">{user.email}</p>
                    <p className="text-xs text-slate-400">{user.phone}</p>
                  </Td>
                  <Td>
                    <StatusPill value={user.role} />
                  </Td>
                  <Td className="text-right font-semibold text-slate-900">
                    {user.vehicles}
                  </Td>
                  <Td className="text-right font-semibold text-slate-900">
                    {user.bookings}
                  </Td>
                  <Td>
                    <StatusPill value={user.active ? 'ACTIVE' : 'IDLE'} />
                  </Td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </>
  )
}

// -------------------------------------------------------------------- revenue

export function Revenue() {
  const week = revenueSeries.reduce((sum, d) => sum + d.revenue, 0)
  const sessions = revenueSeries.reduce((sum, d) => sum + d.bookings, 0)

  const byStation = stations.map((station, i) => ({
    name: station.name,
    revenue: [12_450, 9_820, 6_140, 14_760, 7_530][i],
    sessions: [24, 19, 12, 31, 15][i],
  }))
  const peak = Math.max(...byStation.map((s) => s.revenue))

  return (
    <>
      <PageHeader
        title="Revenue"
        subtitle="Collections, session volume and per-station performance."
      />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          icon={IndianRupee}
          label="This week"
          value={moneyShort(week)}
          delta="+18.4%"
          hint={`${sessions} charging sessions`}
          accent="bg-brand-50 text-brand-600"
        />
        <StatCard
          icon={TrendingUp}
          label="Avg. per session"
          value={moneyShort(week / sessions)}
          delta="+4.1%"
          hint="Energy + parking fees"
          accent="bg-teal-50 text-teal-600"
        />
        <StatCard
          icon={Gauge}
          label="Energy delivered"
          value="3,412 kWh"
          delta="+11.2%"
          hint="Across all chargers"
          accent="bg-sky-50 text-sky-600"
        />
        <StatCard
          icon={UsersIcon}
          label="Paying drivers"
          value={stats.drivers}
          delta="+1"
          hint="Repeat rate 74%"
          accent="bg-violet-50 text-violet-600"
        />
      </div>

      <div className="mt-5 grid grid-cols-1 gap-5 xl:grid-cols-3">
        <Card className="p-5 xl:col-span-2">
          <SectionHeader title="Daily collections" subtitle="Last 7 days" />
          <RevenueChart series={revenueSeries} />
        </Card>
        <Card className="p-5">
          <SectionHeader title="Sessions per day" subtitle="Last 7 days" />
          <BookingsBars series={revenueSeries} />
        </Card>
      </div>

      <Card className="mt-5 p-5">
        <SectionHeader title="Revenue by station" subtitle="Last 30 days" />
        <ul className="space-y-4">
          {byStation.map((station) => (
            <li key={station.name}>
              <div className="mb-1.5 flex items-baseline justify-between gap-4 text-sm">
                <span className="truncate font-medium text-slate-700">
                  {station.name}
                </span>
                <span className="shrink-0 font-semibold text-slate-900">
                  {moneyShort(station.revenue)}
                  <span className="ml-2 text-xs font-medium text-slate-400">
                    {station.sessions} sessions
                  </span>
                </span>
              </div>
              <Meter value={(station.revenue / peak) * 100} />
            </li>
          ))}
        </ul>
      </Card>
    </>
  )
}
