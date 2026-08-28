package com.fleetx.dto;

import jakarta.validation.constraints.NotNull;

public record ParkingReserveRequest(

        @NotNull(message = "Station id is required")
        Long stationId,

        /** Optional - when omitted the first free slot at the station is picked. */
        Long slotId
) {
}
