package com.fleetx.dto;

import java.math.BigDecimal;
import java.util.List;

/** One call that fills the whole home screen. */
public record DashboardResponse(
        String userName,
        BigDecimal walletBalance,
        VehicleResponse primaryVehicle,
        int myVehicleCount,
        List<StationResponse> nearbyStations,
        int availableChargers,
        int availableParkingSlots,
        BookingResponse activeBooking
) {
}
