package com.fleetx.dto;

import com.fleetx.entity.Payment;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record PaymentResponse(
        Long id,
        Long bookingId,
        String bookingReference,
        BigDecimal amount,
        String method,
        String status,
        String transactionRef,
        LocalDateTime paidAt,
        String message
) {
    public static PaymentResponse from(Payment p, String message) {
        return new PaymentResponse(
                p.getId(),
                p.getBooking().getId(),
                p.getBooking().getReference(),
                p.getAmount(),
                p.getMethod().name(),
                p.getStatus().name(),
                p.getTransactionRef(),
                p.getPaidAt(),
                message
        );
    }
}
