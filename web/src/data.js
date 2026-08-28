// Demo data for the FleetX admin dashboard.
//
// Ported from the Flutter prototype's in-memory backend
// (mobile/lib/data/mock_backend.dart) so both surfaces show the same fleet,
// the same five Bengaluru stations and the same bookings. No API calls, no
// backend changes - this is presentation data only.

const DAY = 86_400_000

const iso = (offsetDays) =>
  new Date(Date.now() + offsetDays * DAY).toISOString().slice(0, 10)

export const money = (value) =>
  '₹' +
  Number(value || 0).toLocaleString('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })

export const moneyShort = (value) =>
  '₹' + Number(value || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 })

export const timeLabel = (wire) => {
  const [h, m] = String(wire).split(':')
  const hour = Number(h)
  const suffix = hour >= 12 ? 'PM' : 'AM'
  const shown = hour % 12 === 0 ? 12 : hour % 12
  return `${String(shown).padStart(2, '0')}:${m} ${suffix}`
}

export const dateLabel = (isoDate) =>
  new Date(isoDate + 'T00:00:00').toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })

export const prettyEnum = (value) => {
  if (!value) return '—'
  const words = value.toLowerCase().replaceAll('_', ' ')
  return words[0].toUpperCase() + words.slice(1)
}

// ------------------------------------------------------------------- profile

export const admin = {
  name: 'FleetX Admin',
  email: 'admin@fleetx.com',
  role: 'ADMIN',
  initials: 'FA',
}

// ------------------------------------------------------------------ vehicles

export const vehicles = [
  {
    id: 1,
    vehicleNumber: 'KA01AB1234',
    model: 'Tata Nexon EV',
    owner: 'Ravi Kumar',
    type: 'CAR',
    batteryCapacity: 40.5,
    battery: 82,
    range: 312,
    status: 'ACTIVE',
    odometer: 24_180,
  },
  {
    id: 2,
    vehicleNumber: 'KA02CD5678',
    model: 'Mahindra XUV400',
    owner: 'Ravi Kumar',
    type: 'SUV',
    batteryCapacity: 60,
    battery: 64,
    range: 420,
    status: 'IDLE',
    odometer: 11_640,
  },
  {
    id: 3,
    vehicleNumber: 'KA03EF9012',
    model: 'Ather 450X',
    owner: 'Ravi Kumar',
    type: 'BIKE',
    batteryCapacity: 3.2,
    battery: 47,
    range: 95,
    status: 'CHARGING',
    odometer: 6_220,
  },
  {
    id: 4,
    vehicleNumber: 'KA04GH3456',
    model: 'Tata Tiago EV',
    owner: 'Priya Sharma',
    type: 'CAR',
    batteryCapacity: 30.2,
    battery: 91,
    range: 250,
    status: 'ACTIVE',
    odometer: 18_905,
  },
  {
    id: 5,
    vehicleNumber: 'KA05IJ7890',
    model: 'Tata Ace EV',
    owner: 'Priya Sharma',
    type: 'TRUCK',
    batteryCapacity: 120,
    battery: 18,
    range: 180,
    status: 'MAINTENANCE',
    odometer: 42_310,
  },
]

// ------------------------------------------------------------------ stations

const stationStatus = (free, total) => {
  if (free === 0) return 'FULL'
  if (free * 2 <= total) return 'LIMITED'
  return 'AVAILABLE'
}

const buildStation = (s) => {
  const free = s.chargers.filter((c) => c.status === 'AVAILABLE').length
  return {
    ...s,
    totalChargers: s.chargers.length,
    availableChargers: free,
    status: stationStatus(free, s.chargers.length),
  }
}

export const stations = [
  {
    id: 1,
    name: 'FleetX Hub Koramangala',
    address: '80 Feet Road, 4th Block, Koramangala, Bengaluru',
    distance: 1.2,
    rating: 4.6,
    hours: '24 x 7',
    totalSlots: 4,
    availableSlots: 4,
    chargers: [
      { code: 'C1', type: 'CCS2', power: 60, price: 18.5, status: 'AVAILABLE' },
      { code: 'C2', type: 'TYPE2', power: 22, price: 12.0, status: 'AVAILABLE' },
      { code: 'C3', type: 'AC_SLOW', power: 7.4, price: 9.5, status: 'AVAILABLE' },
    ],
  },
  {
    id: 2,
    name: 'GreenCharge Indiranagar',
    address: '100 Feet Road, Indiranagar, Bengaluru',
    distance: 2.8,
    rating: 4.3,
    hours: '06:00 - 23:00',
    totalSlots: 4,
    availableSlots: 3,
    chargers: [
      { code: 'C1', type: 'CCS2', power: 50, price: 17.0, status: 'AVAILABLE' },
      { code: 'C2', type: 'CHADEMO', power: 50, price: 17.5, status: 'OCCUPIED' },
      { code: 'C3', type: 'TYPE2', power: 22, price: 12.5, status: 'OCCUPIED' },
    ],
  },
  {
    id: 3,
    name: 'VoltPark Whitefield',
    address: 'ITPL Main Road, Whitefield, Bengaluru',
    distance: 5.4,
    rating: 4.1,
    hours: '24 x 7',
    totalSlots: 4,
    availableSlots: 1,
    chargers: [
      { code: 'C1', type: 'CCS2', power: 60, price: 19.0, status: 'OCCUPIED' },
      { code: 'C2', type: 'BHARAT_DC', power: 15, price: 11.0, status: 'OCCUPIED' },
      {
        code: 'C3',
        type: 'AC_SLOW',
        power: 7.4,
        price: 9.0,
        status: 'OUT_OF_SERVICE',
      },
    ],
  },
  {
    id: 4,
    name: 'EcoCharge Electronic City',
    address: 'Hosur Road, Phase 1, Electronic City, Bengaluru',
    distance: 8.9,
    rating: 4.7,
    hours: '05:00 - 00:00',
    totalSlots: 4,
    availableSlots: 3,
    chargers: [
      { code: 'C1', type: 'CCS2', power: 120, price: 22.0, status: 'AVAILABLE' },
      { code: 'C2', type: 'CCS2', power: 60, price: 18.0, status: 'AVAILABLE' },
      { code: 'C3', type: 'TYPE2', power: 22, price: 12.0, status: 'OCCUPIED' },
    ],
  },
  {
    id: 5,
    name: 'PowerGrid MG Road',
    address: 'MG Road, Near Trinity Metro, Bengaluru',
    distance: 3.6,
    rating: 3.9,
    hours: '24 x 7',
    totalSlots: 4,
    availableSlots: 2,
    chargers: [
      { code: 'C1', type: 'TYPE2', power: 22, price: 13.0, status: 'AVAILABLE' },
      { code: 'C2', type: 'CHADEMO', power: 50, price: 17.5, status: 'OCCUPIED' },
      {
        code: 'C3',
        type: 'AC_SLOW',
        power: 7.4,
        price: 10.0,
        status: 'OUT_OF_SERVICE',
      },
    ],
  },
].map(buildStation)

// ------------------------------------------------------------------- parking

export const parkingSlots = stations.flatMap((station) =>
  Array.from({ length: station.totalSlots }, (_, i) => ({
    id: station.id * 10 + i + 1,
    stationId: station.id,
    stationName: station.name,
    slotNumber: `P${i + 1}`,
    occupied: i >= station.availableSlots,
  })),
)

// ------------------------------------------------------------------ bookings

export const bookings = [
  {
    id: 1,
    reference: 'FX8H2K4M',
    user: 'Ravi Kumar',
    vehicleNumber: 'KA01AB1234',
    station: 'FleetX Hub Koramangala',
    charger: 'C1 · CCS2',
    slot: 'P1',
    date: iso(0),
    start: '18:00',
    end: '19:30',
    amount: 1_685.0,
    status: 'CONFIRMED',
    payment: 'SUCCESS',
  },
  {
    id: 2,
    reference: 'FX3T7Q1B',
    user: 'Ravi Kumar',
    vehicleNumber: 'KA02CD5678',
    station: 'GreenCharge Indiranagar',
    charger: 'C1 · CCS2',
    slot: '—',
    date: iso(1),
    start: '09:00',
    end: '10:00',
    amount: 850.0,
    status: 'PENDING',
    payment: 'PENDING',
  },
  {
    id: 3,
    reference: 'FX9R5W2N',
    user: 'Ravi Kumar',
    vehicleNumber: 'KA01AB1234',
    station: 'EcoCharge Electronic City',
    charger: 'C1 · CCS2',
    slot: 'P2',
    date: iso(2),
    start: '20:00',
    end: '21:00',
    amount: 911.0,
    status: 'CONFIRMED',
    payment: 'SUCCESS',
  },
  {
    id: 4,
    reference: 'FX2L8D6V',
    user: 'Priya Sharma',
    vehicleNumber: 'KA04GH3456',
    station: 'PowerGrid MG Road',
    charger: 'C1 · TYPE2',
    slot: '—',
    date: iso(-1),
    start: '14:00',
    end: '15:00',
    amount: 286.0,
    status: 'COMPLETED',
    payment: 'SUCCESS',
  },
  {
    id: 5,
    reference: 'FX6Y4J9C',
    user: 'Priya Sharma',
    vehicleNumber: 'KA04GH3456',
    station: 'VoltPark Whitefield',
    charger: 'C1 · CCS2',
    slot: '—',
    date: iso(-3),
    start: '11:00',
    end: '12:00',
    amount: 1_140.0,
    status: 'CANCELLED',
    payment: 'REFUNDED',
  },
  {
    id: 6,
    reference: 'FX1M3P8X',
    user: 'Ravi Kumar',
    vehicleNumber: 'KA03EF9012',
    station: 'FleetX Hub Koramangala',
    charger: 'C3 · AC_SLOW',
    slot: 'P3',
    date: iso(-4),
    start: '08:30',
    end: '09:30',
    amount: 70.3,
    status: 'COMPLETED',
    payment: 'SUCCESS',
  },
]

// -------------------------------------------------------------------- wallet

export const wallets = [
  { user: 'Ravi Kumar', email: 'ravi@fleetx.com', balance: 2_500 },
  { user: 'Priya Sharma', email: 'priya@fleetx.com', balance: 1_200 },
  { user: 'FleetX Admin', email: 'admin@fleetx.com', balance: 0 },
]

export const transactions = [
  {
    id: 7,
    user: 'Ravi Kumar',
    type: 'DEBIT',
    amount: 1_685.0,
    note: 'Booking FX8H2K4M · Koramangala',
    when: 'Today, 05:42 PM',
  },
  {
    id: 6,
    user: 'Priya Sharma',
    type: 'CREDIT',
    amount: 1_140.0,
    note: 'Refund · booking FX6Y4J9C cancelled',
    when: '3 days ago, 10:12 AM',
  },
  {
    id: 5,
    user: 'Priya Sharma',
    type: 'DEBIT',
    amount: 286.0,
    note: 'Booking FX2L8D6V · MG Road',
    when: 'Yesterday, 01:50 PM',
  },
  {
    id: 4,
    user: 'Ravi Kumar',
    type: 'CREDIT',
    amount: 1_000.0,
    note: 'Wallet recharge · UPI',
    when: '2 days ago, 09:05 PM',
  },
  {
    id: 3,
    user: 'Priya Sharma',
    type: 'CREDIT',
    amount: 1_200.0,
    note: 'Opening balance (demo credit)',
    when: '6 days ago, 11:30 AM',
  },
  {
    id: 2,
    user: 'Ravi Kumar',
    type: 'CREDIT',
    amount: 2_500.0,
    note: 'Opening balance (demo credit)',
    when: '6 days ago, 11:28 AM',
  },
]

// --------------------------------------------------------------------- users

export const users = [
  {
    id: 1,
    name: 'Ravi Kumar',
    email: 'ravi@fleetx.com',
    phone: '+91 98765 43210',
    role: 'DRIVER',
    vehicles: 3,
    bookings: 4,
    active: true,
  },
  {
    id: 2,
    name: 'Priya Sharma',
    email: 'priya@fleetx.com',
    phone: '+91 98123 45678',
    role: 'DRIVER',
    vehicles: 2,
    bookings: 2,
    active: true,
  },
  {
    id: 3,
    name: 'FleetX Admin',
    email: 'admin@fleetx.com',
    phone: '+91 98000 00000',
    role: 'ADMIN',
    vehicles: 0,
    bookings: 0,
    active: true,
  },
]

// ------------------------------------------------------------------- revenue

export const revenueSeries = [
  { label: 'Mon', revenue: 4_260, bookings: 6 },
  { label: 'Tue', revenue: 5_180, bookings: 8 },
  { label: 'Wed', revenue: 3_940, bookings: 5 },
  { label: 'Thu', revenue: 6_720, bookings: 11 },
  { label: 'Fri', revenue: 8_150, bookings: 14 },
  { label: 'Sat', revenue: 9_480, bookings: 17 },
  { label: 'Sun', revenue: 7_310, bookings: 12 },
]

export const energyMix = [
  { label: 'CCS2', value: 46 },
  { label: 'TYPE2', value: 27 },
  { label: 'CHADEMO', value: 15 },
  { label: 'AC / Slow', value: 12 },
]

export const notifications = [
  {
    id: 1,
    title: 'Charger C3 out of service',
    body: 'VoltPark Whitefield · reported 20 min ago',
    tone: 'warn',
  },
  {
    id: 2,
    title: 'Payment received',
    body: 'FX8H2K4M · ₹1,685.00 from Ravi Kumar',
    tone: 'ok',
  },
  {
    id: 3,
    title: 'Booking awaiting payment',
    body: 'FX3T7Q1B · GreenCharge Indiranagar',
    tone: 'info',
  },
]

// -------------------------------------------------------------------- totals

const liveStatuses = ['PENDING', 'CONFIRMED']

export const stats = {
  vehicles: vehicles.length,
  stations: stations.length,
  activeBookings: bookings.filter((b) => liveStatuses.includes(b.status)).length,
  revenue: bookings
    .filter((b) => b.payment === 'SUCCESS')
    .reduce((sum, b) => sum + b.amount, 0),
  chargersOnline: stations.reduce(
    (n, s) => n + s.chargers.filter((c) => c.status !== 'OUT_OF_SERVICE').length,
    0,
  ),
  chargersTotal: stations.reduce((n, s) => n + s.totalChargers, 0),
  slotsFree: parkingSlots.filter((s) => !s.occupied).length,
  slotsTotal: parkingSlots.length,
  drivers: users.filter((u) => u.role === 'DRIVER').length,
}
