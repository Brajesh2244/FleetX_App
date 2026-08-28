package com.fleetx.exception;

/** Invalid input that validation annotations cannot express. Maps to 400. */
public class BadRequestException extends RuntimeException {

    public BadRequestException(String message) {
        super(message);
    }
}
