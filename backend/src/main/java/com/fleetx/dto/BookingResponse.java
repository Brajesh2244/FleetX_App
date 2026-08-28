package com.fleetx.dto;

import com.fleetx.entity.Booking;
import com.fleetx.entity.Payment;
import com.fleetx.entity.ParkingSlot;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

/**
 * Flattened booking view - everything the mobile booking / QR / history screens need
 * without triggering lazy loads during JSON serialization.
 */
public record BookingResponse(
        Long id,
        String reference,
        Long userId,
        String userName,
        Long vehicleId,
        String vehicleNumber,
        Long stationId,
        String stationName,
        String stationAddress,
        Long chargerId,
        String chargerCode,
        String chargerType,
        Double chargerPower,
        Long parkingSlotId,
        String parkingSlotNumber,
        LocalDate bookingDate,
        LocalTime startTime,
        LocalTime endTime,
        BigDecimal amount,
        String status,
        LocalDateTime createdAt,
        /** Payload encoded into the QR code on the success screen. */
        String qrData,
        String paymentStatus,
        String transactionRef
) {

    /** Must be called inside a transaction - it walks the lazy associations. */
    public static BookingResponse from(Booking b) {
        ParkingSlot slot = b.getParkingSlot();
        Payment payment = b.getPayment();

        return new BookingResponse(
                b.getId(),
                b.getReference(),
                b.getUser().getId(),
                b.getUser().getName(),
                b.getVehicle().getId(),
                b.getVehicle().getVehicleNumber(),
                b.getStation().getId(),
                b.getStation().getName(),
                b.getStation().getAddress(),
                b.getCharger().getId(),
                b.getCharger().getCode(),
                b.getCharger().getType().name(),
                b.getCharger().getPower(),
                slot == null ? null : slot.getId(),
                slot == null ? null : slot.getSlotNumber(),
                b.getBookingDate(),
                b.getStartTime(),
                b.getEndTime(),
                b.getAmount(),
                b.getStatus().name(),
                b.getCreatedAt(),
                b.getReference(),
                payment == null ? null : payment.getStatus().name(),
                payment == null ? null : payment.getTransactionRef()
        );
    }
}
