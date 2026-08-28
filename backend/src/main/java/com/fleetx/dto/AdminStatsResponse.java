package com.fleetx.dto;

import java.math.BigDecimal;

public record AdminStatsResponse(
        long totalUsers,
        long totalVehicles,
        long totalStations,
        long totalChargers,
        long totalBookings,
        long activeBookings,
        BigDecimal revenue
) {
}
