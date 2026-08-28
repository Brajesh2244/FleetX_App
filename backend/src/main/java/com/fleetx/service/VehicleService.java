package com.fleetx.service;

import com.fleetx.dto.VehicleRequest;
import com.fleetx.dto.VehicleResponse;
import com.fleetx.entity.User;
import com.fleetx.entity.Vehicle;
import com.fleetx.entity.enums.VehicleStatus;
import com.fleetx.exception.ConflictException;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.UserRepository;
import com.fleetx.repository.VehicleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class VehicleService {

    private final VehicleRepository vehicleRepository;
    private final UserRepository userRepository;

    public VehicleService(VehicleRepository vehicleRepository, UserRepository userRepository) {
        this.vehicleRepository = vehicleRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<VehicleResponse> listMyVehicles(Long userId) {
        return vehicleRepository.findByUserIdOrderByIdAsc(userId).stream()
                .map(VehicleResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public VehicleResponse getMyVehicle(Long id, Long userId) {
        return VehicleResponse.from(requireOwnedVehicle(id, userId));
    }

    @Transactional
    public VehicleResponse create(VehicleRequest request, Long userId) {
        if (vehicleRepository.existsByVehicleNumber(request.vehicleNumber())) {
            throw new ConflictException("Vehicle " + request.vehicleNumber() + " is already registered");
        }

        User owner = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        Vehicle vehicle = new Vehicle();
        vehicle.setUser(owner);
        apply(request, vehicle);
        // Fall back to the account holder when the driver details are left blank.
        if (vehicle.getDriverName() == null || vehicle.getDriverName().isBlank()) {
            vehicle.setDriverName(owner.getName());
        }
        if (vehicle.getDriverContact() == null || vehicle.getDriverContact().isBlank()) {
            vehicle.setDriverContact(owner.getPhone());
        }

        return VehicleResponse.from(vehicleRepository.save(vehicle));
    }

    @Transactional
    public VehicleResponse update(Long id, VehicleRequest request, Long userId) {
        Vehicle vehicle = requireOwnedVehicle(id, userId);

        if (vehicleRepository.existsByVehicleNumberAndIdNot(request.vehicleNumber(), id)) {
            throw new ConflictException("Vehicle " + request.vehicleNumber() + " is already registered");
        }

        apply(request, vehicle);
        return VehicleResponse.from(vehicleRepository.save(vehicle));
    }

    @Transactional
    public void delete(Long id, Long userId) {
        vehicleRepository.delete(requireOwnedVehicle(id, userId));
    }

    /** Admin view - every vehicle in the fleet. */
    @Transactional(readOnly = true)
    public List<VehicleResponse> listAll() {
        return vehicleRepository.findAll().stream()
                .map(VehicleResponse::from)
                .toList();
    }

    private Vehicle requireOwnedVehicle(Long id, Long userId) {
        return vehicleRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle", id));
    }

    private void apply(VehicleRequest request, Vehicle vehicle) {
        vehicle.setVehicleNumber(request.vehicleNumber().trim().toUpperCase());
        vehicle.setVehicleType(request.vehicleType());
        vehicle.setDriverName(request.driverName());
        vehicle.setDriverContact(request.driverContact());
        vehicle.setBatteryCapacity(request.batteryCapacity());
        vehicle.setCurrentRange(request.currentRange());
        vehicle.setStatus(request.status() == null ? VehicleStatus.ACTIVE : request.status());
    }
}
