package com.fleetx.controller;

import com.fleetx.dto.DashboardResponse;
import com.fleetx.dto.MessageResponse;
import com.fleetx.security.UserPrincipal;
import com.fleetx.service.DashboardService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class DashboardController {

    private final DashboardService dashboardService;

    public DashboardController(DashboardService dashboardService) {
        this.dashboardService = dashboardService;
    }

    /** One call that fills the whole home screen. */
    @GetMapping("/dashboard")
    public ResponseEntity<DashboardResponse> dashboard(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(dashboardService.getDashboard(principal.getId()));
    }

    /** Public - lets the app verify the backend URL before login. */
    @GetMapping("/health")
    public ResponseEntity<MessageResponse> health() {
        return ResponseEntity.ok(new MessageResponse("FleetX backend is running"));
    }
}
