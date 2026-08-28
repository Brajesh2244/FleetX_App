package com.fleetx.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** Prototype only - no email or SMS is actually sent. */
public record ForgotPasswordRequest(

        @NotBlank(message = "Email is required")
        @Email(message = "Email is not valid")
        String email
) {
}
