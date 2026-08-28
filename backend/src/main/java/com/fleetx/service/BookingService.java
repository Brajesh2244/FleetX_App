package com.fleetx.service;

import com.fleetx.dto.BookingRequest;
import com.fleetx.dto.BookingResponse;
import com.fleetx.entity.*;
import com.fleetx.entity.enums.BookingStatus;
import com.fleetx.entity.enums.ChargerStatus;
import com.fleetx.entity.enums.PaymentStatus;
import com.fleetx.entity.enums.SlotStatus;
import com.fleetx.exception.BadRequestException;
import com.fleetx.exception.ConflictException;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * The central business flow: reserve a charger (and optionally a parking slot)
 * for a time window, price it, and keep it free of double bookings.
 */
@Service
public class BookingService {

    /** Bookings in these states still hold the charger / slot. */
    static final Set<BookingStatus> LIVE_STATUSES = Set.of(BookingStatus.PENDING, BookingStatus.CONFIRMED);

    private static final BigDecimal PARKING_FEE = new BigDecimal("20.00");

    private final BookingRepository bookingRepository;
    private final VehicleRepository vehicleRepository;
    private final ChargingStationRepository stationRepository;
    private final ChargerRepository chargerRepository;
    private final ParkingSlotRepository parkingSlotRepository;
    private final UserRepository userRepository;
    private final WalletService walletService;

    public BookingService(BookingRepository bookingRepository,
                          VehicleRepository vehicleRepository,
                          ChargingStationRepository stationRepository,
                          ChargerRepository chargerRepository,
                          ParkingSlotRepository parkingSlotRepository,
                          UserRepository userRepository,
                          WalletService walletService) {
        this.bookingRepository = bookingRepository;
        this.vehicleRepository = vehicleRepository;
        this.stationRepository = stationRepository;
        this.chargerRepository = chargerRepository;
        this.parkingSlotRepository = parkingSlotRepository;
        this.userRepository = userRepository;
        this.walletService = walletService;
    }

    @Transactional
    public BookingResponse create(BookingRequest request, Long userId) {
        if (!request.endTime().isAfter(request.startTime())) {
            throw new BadRequestException("End time must be after start time");
        }
        if (request.bookingDate().isBefore(LocalDate.now())) {
            throw new BadRequestException("Booking date cannot be in the past");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        Vehicle vehicle = vehicleRepository.findByIdAndUserId(request.vehicleId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle", request.vehicleId()));

        ChargingStation station = stationRepository.findById(request.stationId())
                .orElseThrow(() -> new ResourceNotFoundException("Charging station", request.stationId()));

        Charger charger = chargerRepository.findById(request.chargerId())
                .orElseThrow(() -> new ResourceNotFoundException("Charger", request.chargerId()));

        if (!charger.getStation().getId().equals(station.getId())) {
            throw new BadRequestException("Charger " + charger.getCode() + " does not belong to " + station.getName());
        }
        if (charger.getStatus() == ChargerStatus.OUT_OF_SERVICE) {
            throw new ConflictException("Charger " + charger.getCode() + " is out of service");
        }

        if (bookingRepository.hasChargerConflict(charger.getId(), request.bookingDate(),
                request.startTime(), request.endTime(), LIVE_STATUSES)) {
            throw new ConflictException("Charger " + charger.getCode()
                    + " is already booked between " + request.startTime() + " and " + request.endTime());
        }

        ParkingSlot slot = resolveParkingSlot(request, station);

        Booking booking = new Booking();
        booking.setReference(nextReference());
        booking.setUser(user);
        booking.setVehicle(vehicle);
        booking.setStation(station);
        booking.setCharger(charger);
        booking.setParkingSlot(slot);
        booking.setBookingDate(request.bookingDate());
        booking.setStartTime(request.startTime());
        booking.setEndTime(request.endTime());
        booking.setAmount(calculateAmount(charger, vehicle, request, slot != null));
        booking.setStatus(BookingStatus.PENDING);

        if (slot != null) {
            slot.setStatus(SlotStatus.RESERVED);
            parkingSlotRepository.save(slot);
        }

        return BookingResponse.from(bookingRepository.save(booking));
    }

    @Transactional(readOnly = true)
    public List<BookingResponse> listMyBookings(Long userId) {
        return bookingRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(BookingResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public BookingResponse getMyBooking(Long id, Long userId) {
        return BookingResponse.from(requireOwnedBooking(id, userId));
    }

    @Transactional
    public BookingResponse cancel(Long id, Long userId) {
        Booking booking = requireOwnedBooking(id, userId);

        if (booking.getStatus() == BookingStatus.CANCELLED) {
            throw new ConflictException("Booking is already cancelled");
        }
        if (booking.getStatus() == BookingStatus.COMPLETED) {
            throw new ConflictException("A completed booking cannot be cancelled");
        }

        booking.setStatus(BookingStatus.CANCELLED);

        if (booking.getParkingSlot() != null) {
            ParkingSlot slot = booking.getParkingSlot();
            slot.setStatus(SlotStatus.AVAILABLE);
            parkingSlotRepository.save(slot);
        }

        // Refund a simulated payment back into the simulated wallet.
        Payment payment = booking.getPayment();
        if (payment != null && payment.getStatus() == PaymentStatus.SUCCESS) {
            walletService.credit(userId, payment.getAmount(),
                    "Refund for cancelled booking " + booking.getReference());
        }

        return BookingResponse.from(bookingRepository.save(booking));
    }

    /** Admin view - every booking in the system. */
    @Transactional(readOnly = true)
    public List<BookingResponse> listAll() {
        return bookingRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(BookingResponse::from)
                .toList();
    }

    /** Dashboard card - the next upcoming booking, if any. */
    @Transactional(readOnly = true)
    public BookingResponse findActiveBooking(Long userId) {
        return bookingRepository.findActiveBookings(userId, LIVE_STATUSES).stream()
                .findFirst()
                .map(BookingResponse::from)
                .orElse(null);
    }

    Booking requireBooking(Long id) {
        return bookingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Booking", id));
    }

    private Booking requireOwnedBooking(Long id, Long userId) {
        return bookingRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking", id));
    }

    private ParkingSlot resolveParkingSlot(BookingRequest request, ChargingStation station) {
        ParkingSlot slot = null;

        if (request.parkingSlotId() != null) {
            slot = parkingSlotRepository.findById(request.parkingSlotId())
                    .orElseThrow(() -> new ResourceNotFoundException("Parking slot", request.parkingSlotId()));
            if (!slot.getStation().getId().equals(station.getId())) {
                throw new BadRequestException("Parking slot " + slot.getSlotNumber()
                        + " does not belong to " + station.getName());
            }
        } else if (Boolean.TRUE.equals(request.autoAssignParking())) {
            slot = parkingSlotRepository
                    .findFirstByStationIdAndStatusOrderByIdAsc(station.getId(), SlotStatus.AVAILABLE)
                    .orElseThrow(() -> new ConflictException("No parking slots available at " + station.getName()));
        }

        if (slot != null && bookingRepository.hasParkingConflict(slot.getId(), request.bookingDate(),
                request.startTime(), request.endTime(), LIVE_STATUSES)) {
            throw new ConflictException("Parking slot " + slot.getSlotNumber()
                    + " is already reserved for that time");
        }

        return slot;
    }

    /**
     * Energy needed = charger output over the booked window, capped at the vehicle's
     * battery size so the demo numbers stay believable. Parking adds a flat fee.
     */
    private BigDecimal calculateAmount(Charger charger, Vehicle vehicle, BookingRequest request, boolean withParking) {
        double hours = Duration.between(request.startTime(), request.endTime()).toMinutes() / 60.0;
        double energyKwh = charger.getPower() * hours;

        if (vehicle.getBatteryCapacity() != null && vehicle.getBatteryCapacity() > 0) {
            energyKwh = Math.min(energyKwh, vehicle.getBatteryCapacity());
        }

        BigDecimal amount = charger.getPricePerKwh()
                .multiply(BigDecimal.valueOf(energyKwh))
                .setScale(2, RoundingMode.HALF_UP);

        if (withParking) {
            amount = amount.add(PARKING_FEE);
        }
        return amount;
    }

    private String nextReference() {
        for (int attempt = 0; attempt < 5; attempt++) {
            String reference = "FLX-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
            if (bookingRepository.findByReference(reference).isEmpty()) {
                return reference;
            }
        }
        throw new ConflictException("Could not allocate a booking reference, please retry");
    }
}
