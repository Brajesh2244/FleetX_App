package com.fleetx.dto;

import java.time.LocalDateTime;

/** Standard error body returned for every handled failure. */
public record ApiError(
        int status,
        String error,
        String message,
        String path,
        LocalDateTime timestamp
) {
    public ApiError(int status, String error, String message, String path) {
        this(status, error, message, path, LocalDateTime.now());
    }
}
