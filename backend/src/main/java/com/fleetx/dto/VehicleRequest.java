package com.fleetx.dto;

import com.fleetx.entity.enums.VehicleStatus;
import com.fleetx.entity.enums.VehicleType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record VehicleRequest(

        @NotBlank(message = "Vehicle number is required")
        String vehicleNumber,

        @NotNull(message = "Vehicle type is required")
        VehicleType vehicleType,

        String driverName,

        String driverContact,

        @Positive(message = "Battery capacity must be positive")
        Double batteryCapacity,

        Double currentRange,

        VehicleStatus status
) {
}
