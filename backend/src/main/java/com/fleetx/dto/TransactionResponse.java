package com.fleetx.dto;

import com.fleetx.entity.Transaction;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record TransactionResponse(
        Long id,
        String type,
        BigDecimal amount,
        String description,
        LocalDateTime createdAt
) {
    public static TransactionResponse from(Transaction t) {
        return new TransactionResponse(
                t.getId(),
                t.getType().name(),
                t.getAmount(),
                t.getDescription(),
                t.getCreatedAt()
        );
    }
}
