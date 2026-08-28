package com.fleetx.config;

import com.fleetx.entity.*;
import com.fleetx.entity.enums.*;
import com.fleetx.repository.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

/**
 * Loads the demo dataset on first start so the app looks populated immediately.
 * Runs only when the users table is empty, so restarts never duplicate data.
 */
@Component
@ConditionalOnProperty(name = "fleetx.seed.enabled", havingValue = "true", matchIfMissing = true)
public class DataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private static final BigDecimal PARKING_FEE = new BigDecimal("20.00");

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;
    private final ChargingStationRepository stationRepository;
    private final ParkingSlotRepository parkingSlotRepository;
    private final BookingRepository bookingRepository;
    private final PaymentRepository paymentRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(RoleRepository roleRepository,
                      UserRepository userRepository,
                      VehicleRepository vehicleRepository,
                      ChargingStationRepository stationRepository,
                      ParkingSlotRepository parkingSlotRepository,
                      BookingRepository bookingRepository,
                      PaymentRepository paymentRepository,
                      WalletRepository walletRepository,
                      TransactionRepository transactionRepository,
                      PasswordEncoder passwordEncoder) {
        this.roleRepository = roleRepository;
        this.userRepository = userRepository;
        this.vehicleRepository = vehicleRepository;
        this.stationRepository = stationRepository;
        this.parkingSlotRepository = parkingSlotRepository;
        this.bookingRepository = bookingRepository;
        this.paymentRepository = paymentRepository;
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        Role driverRole = roleRepository.findByName(RoleName.DRIVER)
                .orElseGet(() -> roleRepository.save(new Role(RoleName.DRIVER)));
        Role adminRole = roleRepository.findByName(RoleName.ADMIN)
                .orElseGet(() -> roleRepository.save(new Role(RoleName.ADMIN)));

        if (userRepository.count() > 0) {
            log.info("FleetX demo data already present - skipping seed.");
            return;
        }

        log.info("Seeding FleetX demo data...");

        // ---------- Users (3) ----------
        User ravi = createUser("Ravi Kumar", "ravi@fleetx.com", "9876543210", "driver123", driverRole);
        User priya = createUser("Priya Sharma", "priya@fleetx.com", "9812345678", "driver123", driverRole);
        User admin = createUser("FleetX Admin", "admin@fleetx.com", "9800000000", "admin123", adminRole);

        Wallet raviWallet = seedWallet(ravi, new BigDecimal("2500.00"));
        Wallet priyaWallet = seedWallet(priya, new BigDecimal("1200.00"));
        seedWallet(admin, new BigDecimal("0.00"));

        // ---------- Vehicles (5) ----------
        Vehicle nexon = createVehicle(ravi, "KA01AB1234", VehicleType.CAR, 40.5, 312.0, VehicleStatus.ACTIVE);
        Vehicle xuv = createVehicle(ravi, "KA02CD5678", VehicleType.SUV, 60.0, 420.0, VehicleStatus.IDLE);
        createVehicle(ravi, "KA03EF9012", VehicleType.BIKE, 3.2, 95.0, VehicleStatus.CHARGING);
        Vehicle tiago = createVehicle(priya, "KA04GH3456", VehicleType.CAR, 30.2, 250.0, VehicleStatus.ACTIVE);
        createVehicle(priya, "KA05IJ7890", VehicleType.TRUCK, 120.0, 180.0, VehicleStatus.MAINTENANCE);

        // ---------- Stations (5) + chargers (15) + parking slots (20) ----------
        ChargingStation koramangala = createStation("FleetX Hub Koramangala",
                "80 Feet Road, 4th Block, Koramangala, Bengaluru", 12.9352, 77.6245, 1.2, 4.6, "24 x 7");
        addCharger(koramangala, "C1", ChargerType.CCS2, 60.0, "18.50", ChargerStatus.AVAILABLE);
        addCharger(koramangala, "C2", ChargerType.TYPE2, 22.0, "12.00", ChargerStatus.AVAILABLE);
        addCharger(koramangala, "C3", ChargerType.AC_SLOW, 7.4, "9.50", ChargerStatus.AVAILABLE);
        addParkingSlots(koramangala, "P", 4, 0);

        ChargingStation indiranagar = createStation("GreenCharge Indiranagar",
                "100 Feet Road, Indiranagar, Bengaluru", 12.9784, 77.6408, 2.8, 4.3, "06:00 - 23:00");
        addCharger(indiranagar, "C1", ChargerType.CCS2, 50.0, "17.00", ChargerStatus.AVAILABLE);
        addCharger(indiranagar, "C2", ChargerType.CHADEMO, 50.0, "17.50", ChargerStatus.OCCUPIED);
        addCharger(indiranagar, "C3", ChargerType.TYPE2, 22.0, "12.50", ChargerStatus.OCCUPIED);
        addParkingSlots(indiranagar, "P", 4, 1);

        ChargingStation whitefield = createStation("VoltPark Whitefield",
                "ITPL Main Road, Whitefield, Bengaluru", 12.9698, 77.7500, 5.4, 4.1, "24 x 7");
        addCharger(whitefield, "C1", ChargerType.CCS2, 60.0, "19.00", ChargerStatus.OCCUPIED);
        addCharger(whitefield, "C2", ChargerType.BHARAT_DC, 15.0, "11.00", ChargerStatus.OCCUPIED);
        addCharger(whitefield, "C3", ChargerType.AC_SLOW, 7.4, "9.00", ChargerStatus.OUT_OF_SERVICE);
        addParkingSlots(whitefield, "P", 4, 3);

        ChargingStation electronicCity = createStation("EcoCharge Electronic City",
                "Hosur Road, Phase 1, Electronic City, Bengaluru", 12.8452, 77.6602, 8.9, 4.7, "05:00 - 00:00");
        addCharger(electronicCity, "C1", ChargerType.CCS2, 120.0, "22.00", ChargerStatus.AVAILABLE);
        addCharger(electronicCity, "C2", ChargerType.CCS2, 60.0, "18.00", ChargerStatus.AVAILABLE);
        addCharger(electronicCity, "C3", ChargerType.TYPE2, 22.0, "12.00", ChargerStatus.OCCUPIED);
        addParkingSlots(electronicCity, "P", 4, 1);

        ChargingStation mgRoad = createStation("PowerGrid MG Road",
                "MG Road, Near Trinity Metro, Bengaluru", 12.9756, 77.6068, 3.6, 3.9, "24 x 7");
        addCharger(mgRoad, "C1", ChargerType.TYPE2, 22.0, "13.00", ChargerStatus.AVAILABLE);
        addCharger(mgRoad, "C2", ChargerType.CHADEMO, 50.0, "17.50", ChargerStatus.OCCUPIED);
        addCharger(mgRoad, "C3", ChargerType.AC_SLOW, 7.4, "10.00", ChargerStatus.OUT_OF_SERVICE);
        addParkingSlots(mgRoad, "P", 4, 2);

        List<ChargingStation> stations = List.of(koramangala, indiranagar, whitefield, electronicCity, mgRoad);
        stations.forEach(s -> {
            s.setStatus(availabilityOf(s));
            stationRepository.save(s);
        });

        // ---------- Bookings + payments ----------
        LocalDate today = LocalDate.now();

        // Confirmed and paid - this is the one the dashboard shows as the active booking.
        Booking b1 = createBooking(ravi, nexon, koramangala, charger(koramangala, "C1"),
                slot(koramangala, "P1"), today, LocalTime.of(18, 0), LocalTime.of(19, 30));
        payFor(b1, PaymentMethod.WALLET, raviWallet);

        // Awaiting payment - demonstrates the PENDING state in booking history.
        createBooking(ravi, xuv, indiranagar, charger(indiranagar, "C1"),
                null, today.plusDays(1), LocalTime.of(9, 0), LocalTime.of(10, 0));

        // Upcoming, already paid by UPI.
        Booking b3 = createBooking(ravi, nexon, electronicCity, charger(electronicCity, "C1"),
                slot(electronicCity, "P2"), today.plusDays(2), LocalTime.of(20, 0), LocalTime.of(21, 0));
        payFor(b3, PaymentMethod.UPI, null);

        // Finished trip.
        Booking b4 = createBooking(priya, tiago, mgRoad, charger(mgRoad, "C1"),
                null, today.minusDays(1), LocalTime.of(14, 0), LocalTime.of(15, 0));
        payFor(b4, PaymentMethod.WALLET, priyaWallet);
        b4.setStatus(BookingStatus.COMPLETED);
        bookingRepository.save(b4);

        // Cancelled trip.
        Booking b5 = createBooking(priya, tiago, whitefield, charger(whitefield, "C1"),
                null, today.minusDays(3), LocalTime.of(11, 0), LocalTime.of(12, 0));
        b5.setStatus(BookingStatus.CANCELLED);
        bookingRepository.save(b5);

        log.info("FleetX demo data seeded: {} users, {} vehicles, {} stations, {} bookings.",
                userRepository.count(), vehicleRepository.count(),
                stationRepository.count(), bookingRepository.count());
    }

    // ---------------------------------------------------------------- helpers

    private User createUser(String name, String email, String phone, String rawPassword, Role role) {
        User user = new User();
        user.setName(name);
        user.setEmail(email);
        user.setPhone(phone);
        user.setPassword(passwordEncoder.encode(rawPassword));
        user.setRole(role);
        return userRepository.save(user);
    }

    private Wallet seedWallet(User user, BigDecimal balance) {
        Wallet wallet = walletRepository.save(new Wallet(user, balance));
        if (balance.signum() > 0) {
            transactionRepository.save(new Transaction(wallet, TransactionType.CREDIT, balance,
                    "Opening balance (demo credit)"));
        }
        return wallet;
    }

    private Vehicle createVehicle(User owner, String number, VehicleType type,
                                  Double battery, Double range, VehicleStatus status) {
        Vehicle vehicle = new Vehicle();
        vehicle.setUser(owner);
        vehicle.setVehicleNumber(number);
        vehicle.setVehicleType(type);
        vehicle.setDriverName(owner.getName());
        vehicle.setDriverContact(owner.getPhone());
        vehicle.setBatteryCapacity(battery);
        vehicle.setCurrentRange(range);
        vehicle.setStatus(status);
        return vehicleRepository.save(vehicle);
    }

    private ChargingStation createStation(String name, String address, double lat, double lng,
                                          double distance, double rating, String hours) {
        ChargingStation station = new ChargingStation();
        station.setName(name);
        station.setAddress(address);
        station.setLatitude(lat);
        station.setLongitude(lng);
        station.setDistance(distance);
        station.setRating(rating);
        station.setOperatingHours(hours);
        return stationRepository.save(station);
    }

    private void addCharger(ChargingStation station, String code, ChargerType type,
                            double power, String price, ChargerStatus status) {
        Charger charger = new Charger();
        charger.setCode(code);
        charger.setType(type);
        charger.setPower(power);
        charger.setPricePerKwh(new BigDecimal(price));
        charger.setStatus(status);
        station.addCharger(charger);
    }

    /** Creates {@code count} slots, marking the first {@code occupied} of them as taken. */
    private void addParkingSlots(ChargingStation station, String prefix, int count, int occupied) {
        for (int i = 1; i <= count; i++) {
            ParkingSlot slot = new ParkingSlot();
            slot.setSlotNumber(prefix + i);
            slot.setStatus(i <= occupied ? SlotStatus.OCCUPIED : SlotStatus.AVAILABLE);
            station.addParkingSlot(slot);
        }
    }

    private static AvailabilityStatus availabilityOf(ChargingStation station) {
        long available = station.getChargers().stream()
                .filter(c -> c.getStatus() == ChargerStatus.AVAILABLE)
                .count();
        if (available == 0) {
            return AvailabilityStatus.FULL;
        }
        return available * 2 <= station.getChargers().size()
                ? AvailabilityStatus.LIMITED
                : AvailabilityStatus.AVAILABLE;
    }

    private static Charger charger(ChargingStation station, String code) {
        return station.getChargers().stream()
                .filter(c -> c.getCode().equals(code))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Seed charger " + code + " missing"));
    }

    private static ParkingSlot slot(ChargingStation station, String slotNumber) {
        return station.getParkingSlots().stream()
                .filter(p -> p.getSlotNumber().equals(slotNumber))
                .findFirst()
                .orElseThrow(() -> new IllegalStateException("Seed slot " + slotNumber + " missing"));
    }

    private Booking createBooking(User user, Vehicle vehicle, ChargingStation station, Charger charger,
                                  ParkingSlot parkingSlot, LocalDate date, LocalTime start, LocalTime end) {
        Booking booking = new Booking();
        booking.setReference(nextReference());
        booking.setUser(user);
        booking.setVehicle(vehicle);
        booking.setStation(station);
        booking.setCharger(charger);
        booking.setParkingSlot(parkingSlot);
        booking.setBookingDate(date);
        booking.setStartTime(start);
        booking.setEndTime(end);
        booking.setAmount(priceOf(charger, vehicle, start, end, parkingSlot != null));
        booking.setStatus(BookingStatus.PENDING);

        if (parkingSlot != null) {
            parkingSlot.setStatus(SlotStatus.RESERVED);
            parkingSlotRepository.save(parkingSlot);
        }

        return bookingRepository.save(booking);
    }

    /** Mirrors BookingService pricing so seeded amounts match what the API would charge. */
    private static BigDecimal priceOf(Charger charger, Vehicle vehicle, LocalTime start, LocalTime end,
                                      boolean withParking) {
        double hours = Duration.between(start, end).toMinutes() / 60.0;
        double energyKwh = charger.getPower() * hours;

        if (vehicle.getBatteryCapacity() != null && vehicle.getBatteryCapacity() > 0) {
            energyKwh = Math.min(energyKwh, vehicle.getBatteryCapacity());
        }

        BigDecimal amount = charger.getPricePerKwh()
                .multiply(BigDecimal.valueOf(energyKwh))
                .setScale(2, RoundingMode.HALF_UP);

        return withParking ? amount.add(PARKING_FEE) : amount;
    }

    /** Records a successful simulated payment and confirms the booking. */
    private void payFor(Booking booking, PaymentMethod method, Wallet walletToDebit) {
        Payment payment = new Payment();
        payment.setBooking(booking);
        payment.setAmount(booking.getAmount());
        payment.setMethod(method);
        payment.setStatus(PaymentStatus.SUCCESS);
        payment.setTransactionRef("TXN-" + randomToken(10));
        payment.setPaidAt(LocalDateTime.now());
        paymentRepository.save(payment);

        booking.setStatus(BookingStatus.CONFIRMED);
        booking.setPayment(payment);
        bookingRepository.save(booking);

        if (walletToDebit != null) {
            walletToDebit.setBalance(walletToDebit.getBalance().subtract(booking.getAmount()));
            walletRepository.save(walletToDebit);
            transactionRepository.save(new Transaction(walletToDebit, TransactionType.DEBIT,
                    booking.getAmount(), "Charging booking " + booking.getReference()));
        }
    }

    private String nextReference() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String reference = "FLX-" + randomToken(8);
            if (bookingRepository.findByReference(reference).isEmpty()) {
                return reference;
            }
        }
        throw new IllegalStateException("Could not allocate a seed booking reference");
    }

    private static String randomToken(int length) {
        return java.util.UUID.randomUUID().toString().replace("-", "").substring(0, length).toUpperCase();
    }
}
