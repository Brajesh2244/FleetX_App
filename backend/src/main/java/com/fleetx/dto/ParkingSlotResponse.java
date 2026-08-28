package com.fleetx.dto;

import com.fleetx.entity.ParkingSlot;

public record ParkingSlotResponse(
        Long id,
        String slotNumber,
        String status,
        Long stationId,
        String stationName
) {
    public static ParkingSlotResponse from(ParkingSlot slot) {
        return new ParkingSlotResponse(
                slot.getId(),
                slot.getSlotNumber(),
                slot.getStatus().name(),
                slot.getStation().getId(),
                slot.getStation().getName()
        );
    }
}
