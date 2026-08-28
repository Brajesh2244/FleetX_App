package com.fleetx.dto;

import com.fleetx.entity.Vehicle;

public record VehicleResponse(
        Long id,
        String vehicleNumber,
        String vehicleType,
        String driverName,
        String driverContact,
        Double batteryCapacity,
        Double currentRange,
        String status,
        Long ownerId,
        String ownerName
) {
    public static VehicleResponse from(Vehicle v) {
        return new VehicleResponse(
                v.getId(),
                v.getVehicleNumber(),
                v.getVehicleType().name(),
                v.getDriverName(),
                v.getDriverContact(),
                v.getBatteryCapacity(),
                v.getCurrentRange(),
                v.getStatus().name(),
                v.getUser().getId(),
                v.getUser().getName()
        );
    }
}
