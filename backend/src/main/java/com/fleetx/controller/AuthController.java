package com.fleetx.controller;

import com.fleetx.dto.*;
import com.fleetx.security.UserPrincipal;
import com.fleetx.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    /** Requires a valid token - used by the app on startup to restore the session. */
    @GetMapping("/me")
    public ResponseEntity<UserResponse> me(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(authService.currentUser(principal.getId()));
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<MessageResponse> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        return ResponseEntity.ok(authService.forgotPassword(request));
    }

    /** Simulated OTP send - always succeeds. */
    @PostMapping("/otp/send")
    public ResponseEntity<MessageResponse> sendOtp(@RequestBody Map<String, String> body) {
        return ResponseEntity.ok(authService.sendOtp(body.getOrDefault("phone", "your number")));
    }

    /** Simulated OTP verify - the demo code is 123456. */
    @PostMapping("/otp/verify")
    public ResponseEntity<MessageResponse> verifyOtp(@RequestBody Map<String, String> body) {
        return ResponseEntity.ok(authService.verifyOtp(body.get("otp")));
    }
}
