package com.fleetx.repository;

import com.fleetx.entity.ChargingStation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChargingStationRepository extends JpaRepository<ChargingStation, Long> {

    List<ChargingStation> findAllByOrderByDistanceAsc();

    List<ChargingStation> findByNameContainingIgnoreCaseOrAddressContainingIgnoreCase(String name, String address);
}
