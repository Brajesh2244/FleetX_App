package com.fleetx.dto;

import com.fleetx.entity.Charger;

import java.math.BigDecimal;

public record ChargerResponse(
        Long id,
        String code,
        String type,
        Double power,
        BigDecimal pricePerKwh,
        String status,
        Long stationId
) {
    public static ChargerResponse from(Charger c) {
        return new ChargerResponse(
                c.getId(),
                c.getCode(),
                c.getType().name(),
                c.getPower(),
                c.getPricePerKwh(),
                c.getStatus().name(),
                c.getStation().getId()
        );
    }
}
