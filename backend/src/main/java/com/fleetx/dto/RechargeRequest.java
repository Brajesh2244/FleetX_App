package com.fleetx.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record RechargeRequest(

        @NotNull(message = "Amount is required")
        @DecimalMin(value = "1.00", message = "Minimum recharge is 1")
        BigDecimal amount
) {
}
