package com.fleetx.controller;

import com.fleetx.dto.ParkingReserveRequest;
import com.fleetx.dto.ParkingSlotResponse;
import com.fleetx.service.ParkingService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/parking")
public class ParkingController {

    private final ParkingService parkingService;

    public ParkingController(ParkingService parkingService) {
        this.parkingService = parkingService;
    }

    /** Pass ?stationId= to scope the list to one station. */
    @GetMapping
    public ResponseEntity<List<ParkingSlotResponse>> list(@RequestParam(required = false) Long stationId) {
        return ResponseEntity.ok(parkingService.listSlots(stationId));
    }

    @PostMapping("/reserve")
    public ResponseEntity<ParkingSlotResponse> reserve(@Valid @RequestBody ParkingReserveRequest request) {
        return ResponseEntity.ok(parkingService.reserve(request));
    }

    @PostMapping("/{slotId}/release")
    public ResponseEntity<ParkingSlotResponse> release(@PathVariable Long slotId) {
        return ResponseEntity.ok(parkingService.release(slotId));
    }
}
