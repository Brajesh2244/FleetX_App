package com.fleetx.repository;

import com.fleetx.entity.Vehicle;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

    List<Vehicle> findByUserIdOrderByIdAsc(Long userId);

    Optional<Vehicle> findByIdAndUserId(Long id, Long userId);

    boolean existsByVehicleNumber(String vehicleNumber);

    boolean existsByVehicleNumberAndIdNot(String vehicleNumber, Long id);
}
