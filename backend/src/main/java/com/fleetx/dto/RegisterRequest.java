package com.fleetx.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(

        @NotBlank(message = "Name is required")
        @Size(max = 100)
        String name,

        @NotBlank(message = "Email is required")
        @Email(message = "Email is not valid")
        String email,

        @Size(max = 20)
        String phone,

        @NotBlank(message = "Password is required")
        @Size(min = 6, message = "Password must be at least 6 characters")
        String password
) {
}
