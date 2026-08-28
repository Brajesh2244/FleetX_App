package com.fleetx.dto;

import java.util.List;

/** Station payload. chargers is populated on the detail endpoint, omitted from the list endpoint. */
public record StationResponse(
        Long id,
        String name,
        String address,
        Double latitude,
        Double longitude,
        Double distance,
        Double rating,
        String operatingHours,
        String status,
        int totalChargers,
        int availableChargers,
        int totalParkingSlots,
        int availableParkingSlots,
        List<ChargerResponse> chargers
) {
}
