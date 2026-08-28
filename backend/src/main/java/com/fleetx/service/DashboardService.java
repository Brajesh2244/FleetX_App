package com.fleetx.service;

import com.fleetx.dto.*;
import com.fleetx.entity.User;
import com.fleetx.entity.Vehicle;
import com.fleetx.entity.enums.ChargerStatus;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.ChargerRepository;
import com.fleetx.repository.UserRepository;
import com.fleetx.repository.VehicleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Aggregates everything the home screen shows into a single call. */
@Service
public class DashboardService {

    private static final int NEARBY_LIMIT = 3;

    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;
    private final ChargerRepository chargerRepository;
    private final StationService stationService;
    private final ParkingService parkingService;
    private final BookingService bookingService;
    private final WalletService walletService;

    public DashboardService(UserRepository userRepository,
                            VehicleRepository vehicleRepository,
                            ChargerRepository chargerRepository,
                            StationService stationService,
                            ParkingService parkingService,
                            BookingService bookingService,
                            WalletService walletService) {
        this.userRepository = userRepository;
        this.vehicleRepository = vehicleRepository;
        this.chargerRepository = chargerRepository;
        this.stationService = stationService;
        this.parkingService = parkingService;
        this.bookingService = bookingService;
        this.walletService = walletService;
    }

    @Transactional
    public DashboardResponse getDashboard(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        List<Vehicle> vehicles = vehicleRepository.findByUserIdOrderByIdAsc(userId);
        VehicleResponse primaryVehicle = vehicles.isEmpty() ? null : VehicleResponse.from(vehicles.get(0));

        List<StationResponse> nearby = stationService.listStations(null).stream()
                .limit(NEARBY_LIMIT)
                .toList();

        return new DashboardResponse(
                user.getName(),
                walletService.getWallet(userId).balance(),
                primaryVehicle,
                vehicles.size(),
                nearby,
                (int) chargerRepository.countByStatus(ChargerStatus.AVAILABLE),
                (int) parkingService.countAvailable(),
                bookingService.findActiveBooking(userId)
        );
    }
}
