package com.fleetx.controller;

import com.fleetx.dto.MessageResponse;
import com.fleetx.dto.VehicleRequest;
import com.fleetx.dto.VehicleResponse;
import com.fleetx.security.UserPrincipal;
import com.fleetx.service.VehicleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vehicles")
public class VehicleController {

    private final VehicleService vehicleService;

    public VehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping
    public ResponseEntity<List<VehicleResponse>> list(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(vehicleService.listMyVehicles(principal.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<VehicleResponse> get(@PathVariable Long id,
                                               @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(vehicleService.getMyVehicle(id, principal.getId()));
    }

    @PostMapping
    public ResponseEntity<VehicleResponse> create(@Valid @RequestBody VehicleRequest request,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(vehicleService.create(request, principal.getId()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<VehicleResponse> update(@PathVariable Long id,
                                                  @Valid @RequestBody VehicleRequest request,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(vehicleService.update(id, request, principal.getId()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<MessageResponse> delete(@PathVariable Long id,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        vehicleService.delete(id, principal.getId());
        return ResponseEntity.ok(new MessageResponse("Vehicle deleted successfully"));
    }
}
