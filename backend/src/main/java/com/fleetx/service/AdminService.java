package com.fleetx.service;

import com.fleetx.dto.AdminStatsResponse;
import com.fleetx.dto.UserResponse;
import com.fleetx.entity.enums.BookingStatus;
import com.fleetx.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/** Read-mostly aggregates for the admin dashboard. */
@Service
public class AdminService {

    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;
    private final ChargingStationRepository stationRepository;
    private final ChargerRepository chargerRepository;
    private final BookingRepository bookingRepository;

    public AdminService(UserRepository userRepository,
                        VehicleRepository vehicleRepository,
                        ChargingStationRepository stationRepository,
                        ChargerRepository chargerRepository,
                        BookingRepository bookingRepository) {
        this.userRepository = userRepository;
        this.vehicleRepository = vehicleRepository;
        this.stationRepository = stationRepository;
        this.chargerRepository = chargerRepository;
        this.bookingRepository = bookingRepository;
    }

    @Transactional(readOnly = true)
    public AdminStatsResponse stats() {
        BigDecimal revenue = bookingRepository.sumRevenue();

        return new AdminStatsResponse(
                userRepository.count(),
                vehicleRepository.count(),
                stationRepository.count(),
                chargerRepository.count(),
                bookingRepository.count(),
                bookingRepository.countByStatus(BookingStatus.CONFIRMED)
                        + bookingRepository.countByStatus(BookingStatus.PENDING),
                revenue == null ? BigDecimal.ZERO : revenue
        );
    }

    @Transactional(readOnly = true)
    public List<UserResponse> listUsers() {
        return userRepository.findAll().stream()
                .map(u -> new UserResponse(u.getId(), u.getName(), u.getEmail(), u.getPhone(),
                        u.getRole().getName().name(), u.isActive()))
                .toList();
    }
}
