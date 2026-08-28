package com.fleetx.repository;

import com.fleetx.entity.ParkingSlot;
import com.fleetx.entity.enums.SlotStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ParkingSlotRepository extends JpaRepository<ParkingSlot, Long> {

    List<ParkingSlot> findByStationIdOrderByIdAsc(Long stationId);

    Optional<ParkingSlot> findFirstByStationIdAndStatusOrderByIdAsc(Long stationId, SlotStatus status);

    long countByStationIdAndStatus(Long stationId, SlotStatus status);

    long countByStatus(SlotStatus status);
}
