package com.fleetx.service;

import com.fleetx.dto.RechargeRequest;
import com.fleetx.dto.TransactionResponse;
import com.fleetx.dto.WalletResponse;
import com.fleetx.entity.Transaction;
import com.fleetx.entity.User;
import com.fleetx.entity.Wallet;
import com.fleetx.entity.enums.TransactionType;
import com.fleetx.exception.ConflictException;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.TransactionRepository;
import com.fleetx.repository.UserRepository;
import com.fleetx.repository.WalletRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

/** Simulated wallet - recharges are instant and no payment gateway is involved. */
@Service
public class WalletService {

    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;

    public WalletService(WalletRepository walletRepository,
                         TransactionRepository transactionRepository,
                         UserRepository userRepository) {
        this.walletRepository = walletRepository;
        this.transactionRepository = transactionRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public WalletResponse getWallet(Long userId) {
        Wallet wallet = requireWallet(userId);
        return new WalletResponse(wallet.getId(), userId, wallet.getBalance());
    }

    @Transactional
    public WalletResponse recharge(Long userId, RechargeRequest request) {
        Wallet wallet = requireWallet(userId);
        wallet.setBalance(wallet.getBalance().add(request.amount()));
        walletRepository.save(wallet);

        transactionRepository.save(new Transaction(wallet, TransactionType.CREDIT, request.amount(),
                "Wallet recharge (simulated)"));

        return new WalletResponse(wallet.getId(), userId, wallet.getBalance());
    }

    @Transactional(readOnly = true)
    public List<TransactionResponse> listTransactions(Long userId) {
        Wallet wallet = walletRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Wallet for user " + userId + " not found"));
        return transactionRepository.findByWalletIdOrderByCreatedAtDesc(wallet.getId()).stream()
                .map(TransactionResponse::from)
                .toList();
    }

    /** Used by the payment simulation when the driver pays from the wallet. */
    @Transactional
    public void debit(Long userId, BigDecimal amount, String description) {
        Wallet wallet = requireWallet(userId);

        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new ConflictException("Insufficient wallet balance. Available: " + wallet.getBalance());
        }

        wallet.setBalance(wallet.getBalance().subtract(amount));
        walletRepository.save(wallet);
        transactionRepository.save(new Transaction(wallet, TransactionType.DEBIT, amount, description));
    }

    /** Refund path used when a paid booking is cancelled. */
    @Transactional
    public void credit(Long userId, BigDecimal amount, String description) {
        Wallet wallet = requireWallet(userId);
        wallet.setBalance(wallet.getBalance().add(amount));
        walletRepository.save(wallet);
        transactionRepository.save(new Transaction(wallet, TransactionType.CREDIT, amount, description));
    }

    /** Creates the wallet on first use so older demo accounts never 404. */
    private Wallet requireWallet(Long userId) {
        return walletRepository.findByUserId(userId).orElseGet(() -> {
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new ResourceNotFoundException("User", userId));
            return walletRepository.save(new Wallet(user, BigDecimal.ZERO));
        });
    }
}
