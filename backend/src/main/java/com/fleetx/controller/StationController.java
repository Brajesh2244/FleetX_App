package com.fleetx.controller;

import com.fleetx.dto.ChargerResponse;
import com.fleetx.dto.StationRequest;
import com.fleetx.dto.StationResponse;
import com.fleetx.service.StationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/stations")
public class StationController {

    private final StationService stationService;

    public StationController(StationService stationService) {
        this.stationService = stationService;
    }

    @GetMapping
    public ResponseEntity<List<StationResponse>> list(@RequestParam(required = false) String search) {
        return ResponseEntity.ok(stationService.listStations(search));
    }

    @GetMapping("/{id}")
    public ResponseEntity<StationResponse> get(@PathVariable Long id) {
        return ResponseEntity.ok(stationService.getStation(id));
    }

    @GetMapping("/{id}/chargers")
    public ResponseEntity<List<ChargerResponse>> chargers(@PathVariable Long id) {
        return ResponseEntity.ok(stationService.listChargers(id));
    }

    /** Admin only - enforced in SecurityConfig. */
    @PostMapping
    public ResponseEntity<StationResponse> create(@Valid @RequestBody StationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(stationService.create(request));
    }

    /** Admin only - enforced in SecurityConfig. */
    @PutMapping("/{id}")
    public ResponseEntity<StationResponse> update(@PathVariable Long id,
                                                  @Valid @RequestBody StationRequest request) {
        return ResponseEntity.ok(stationService.update(id, request));
    }
}
