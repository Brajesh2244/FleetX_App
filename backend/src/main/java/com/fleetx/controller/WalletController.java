package com.fleetx.controller;

import com.fleetx.dto.RechargeRequest;
import com.fleetx.dto.TransactionResponse;
import com.fleetx.dto.WalletResponse;
import com.fleetx.security.UserPrincipal;
import com.fleetx.service.WalletService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/wallet")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    @GetMapping
    public ResponseEntity<WalletResponse> wallet(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(walletService.getWallet(principal.getId()));
    }

    /** Simulated top up - the balance goes up immediately. */
    @PostMapping("/recharge")
    public ResponseEntity<WalletResponse> recharge(@Valid @RequestBody RechargeRequest request,
                                                   @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(walletService.recharge(principal.getId(), request));
    }

    @GetMapping("/transactions")
    public ResponseEntity<List<TransactionResponse>> transactions(
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(walletService.listTransactions(principal.getId()));
    }
}
