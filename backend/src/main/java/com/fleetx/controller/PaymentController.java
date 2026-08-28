package com.fleetx.controller;

import com.fleetx.dto.PaymentRequest;
import com.fleetx.dto.PaymentResponse;
import com.fleetx.security.UserPrincipal;
import com.fleetx.service.PaymentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    /** Simulated payment - confirms the booking and returns "Payment Successful". */
    @PostMapping
    public ResponseEntity<PaymentResponse> pay(@Valid @RequestBody PaymentRequest request,
                                               @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(paymentService.pay(request, principal.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PaymentResponse> get(@PathVariable Long id,
                                               @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(paymentService.getPayment(id, principal.getId()));
    }
}
