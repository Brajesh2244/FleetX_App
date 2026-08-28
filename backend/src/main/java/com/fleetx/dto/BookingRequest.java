package com.fleetx.dto;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;

public record BookingRequest(

        @NotNull(message = "Vehicle is required")
        Long vehicleId,

        @NotNull(message = "Station is required")
        Long stationId,

        @NotNull(message = "Charger is required")
        Long chargerId,

        /** Optional - pass a slot id to reserve parking alongside charging. */
        Long parkingSlotId,

        /** Set true to let the backend pick any free slot at the station. */
        Boolean autoAssignParking,

        @NotNull(message = "Booking date is required")
        LocalDate bookingDate,

        @NotNull(message = "Start time is required")
        LocalTime startTime,

        @NotNull(message = "End time is required")
        LocalTime endTime
) {
}
