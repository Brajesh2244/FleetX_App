package com.fleetx.dto;

/** Current user profile, served from the JWT identity. */
public record UserResponse(
        Long id,
        String name,
        String email,
        String phone,
        String role,
        boolean active
) {
}
