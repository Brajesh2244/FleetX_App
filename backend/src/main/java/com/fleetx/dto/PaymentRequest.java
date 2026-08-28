package com.fleetx.dto;

import com.fleetx.entity.enums.PaymentMethod;
import jakarta.validation.constraints.NotNull;

public record PaymentRequest(

        @NotNull(message = "Booking id is required")
        Long bookingId,

        @NotNull(message = "Payment method is required")
        PaymentMethod method
) {
}
