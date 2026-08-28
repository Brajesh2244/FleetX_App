package com.fleetx.exception;

/** Duplicate email, double booked charger, insufficient wallet balance. Maps to 409. */
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}
