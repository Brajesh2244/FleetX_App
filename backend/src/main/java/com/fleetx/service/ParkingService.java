package com.fleetx.service;

import com.fleetx.dto.ParkingReserveRequest;
import com.fleetx.dto.ParkingSlotResponse;
import com.fleetx.entity.ParkingSlot;
import com.fleetx.entity.enums.SlotStatus;
import com.fleetx.exception.ConflictException;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.ParkingSlotRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Deliberately simple parking availability. There is no pricing engine or
 * long running hold - a slot is either free, reserved or occupied.
 */
@Service
public class ParkingService {

    private final ParkingSlotRepository parkingSlotRepository;

    public ParkingService(ParkingSlotRepository parkingSlotRepository) {
        this.parkingSlotRepository = parkingSlotRepository;
    }

    @Transactional(readOnly = true)
    public List<ParkingSlotResponse> listSlots(Long stationId) {
        List<ParkingSlot> slots = (stationId == null)
                ? parkingSlotRepository.findAll()
                : parkingSlotRepository.findByStationIdOrderByIdAsc(stationId);

        return slots.stream().map(ParkingSlotResponse::from).toList();
    }

    @Transactional
    public ParkingSlotResponse reserve(ParkingReserveRequest request) {
        ParkingSlot slot = (request.slotId() != null)
                ? parkingSlotRepository.findById(request.slotId())
                        .orElseThrow(() -> new ResourceNotFoundException("Parking slot", request.slotId()))
                : parkingSlotRepository
                        .findFirstByStationIdAndStatusOrderByIdAsc(request.stationId(), SlotStatus.AVAILABLE)
                        .orElseThrow(() -> new ConflictException("No parking slots available at this station"));

        if (slot.getStatus() != SlotStatus.AVAILABLE) {
            throw new ConflictException("Parking slot " + slot.getSlotNumber() + " is not available");
        }

        slot.setStatus(SlotStatus.RESERVED);
        return ParkingSlotResponse.from(parkingSlotRepository.save(slot));
    }

    @Transactional
    public ParkingSlotResponse release(Long slotId) {
        ParkingSlot slot = parkingSlotRepository.findById(slotId)
                .orElseThrow(() -> new ResourceNotFoundException("Parking slot", slotId));
        slot.setStatus(SlotStatus.AVAILABLE);
        return ParkingSlotResponse.from(parkingSlotRepository.save(slot));
    }

    @Transactional(readOnly = true)
    public long countAvailable() {
        return parkingSlotRepository.countByStatus(SlotStatus.AVAILABLE);
    }
}
