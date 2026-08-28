package com.fleetx.repository;

import com.fleetx.entity.Charger;
import com.fleetx.entity.enums.ChargerStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChargerRepository extends JpaRepository<Charger, Long> {

    List<Charger> findByStationIdOrderByIdAsc(Long stationId);

    long countByStatus(ChargerStatus status);
}
