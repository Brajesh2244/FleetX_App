package com.fleetx.exception;

/** Thrown when an entity does not exist, or is not visible to the caller. Maps to 404. */
public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public ResourceNotFoundException(String entity, Object id) {
        super(entity + " not found with id " + id);
    }
}
