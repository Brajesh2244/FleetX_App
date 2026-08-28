package com.fleetx.controller;

import com.fleetx.dto.*;
import com.fleetx.service.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Admin dashboard. The whole /api/admin tree requires ROLE_ADMIN (see SecurityConfig).
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminService adminService;
    private final VehicleService vehicleService;
    private final StationService stationService;
    private final BookingService bookingService;

    public AdminController(AdminService adminService,
                          VehicleService vehicleService,
                          StationService stationService,
                          BookingService bookingService) {
        this.adminService = adminService;
        this.vehicleService = vehicleService;
        this.stationService = stationService;
        this.bookingService = bookingService;
    }

    @GetMapping("/stats")
    public ResponseEntity<AdminStatsResponse> stats() {
        return ResponseEntity.ok(adminService.stats());
    }

    @GetMapping("/users")
    public ResponseEntity<List<UserResponse>> users() {
        return ResponseEntity.ok(adminService.listUsers());
    }

    @GetMapping("/vehicles")
    public ResponseEntity<List<VehicleResponse>> vehicles() {
        return ResponseEntity.ok(vehicleService.listAll());
    }

    @GetMapping("/stations")
    public ResponseEntity<List<StationResponse>> stations() {
        return ResponseEntity.ok(stationService.listStations(null));
    }

    @GetMapping("/bookings")
    public ResponseEntity<List<BookingResponse>> bookings() {
        return ResponseEntity.ok(bookingService.listAll());
    }
}
