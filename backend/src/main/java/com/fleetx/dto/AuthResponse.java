package com.fleetx.dto;

/** Returned by register + login. The mobile app stores the token and sends it as a Bearer header. */
public record AuthResponse(
        String token,
        String tokenType,
        Long userId,
        String name,
        String email,
        String phone,
        String role
) {
    public AuthResponse(String token, Long userId, String name, String email, String phone, String role) {
        this(token, "Bearer", userId, name, email, phone, role);
    }
}
