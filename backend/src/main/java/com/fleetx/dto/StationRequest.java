package com.fleetx.dto;

import jakarta.validation.constraints.NotBlank;

public record StationRequest(

        @NotBlank(message = "Station name is required")
        String name,

        @NotBlank(message = "Address is required")
        String address,

        Double latitude,

        Double longitude,

        Double distance,

        Double rating,

        String operatingHours
) {
}
