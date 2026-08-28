package com.fleetx.service;

import com.fleetx.dto.PaymentRequest;
import com.fleetx.dto.PaymentResponse;
import com.fleetx.entity.Booking;
import com.fleetx.entity.Payment;
import com.fleetx.entity.enums.BookingStatus;
import com.fleetx.entity.enums.PaymentMethod;
import com.fleetx.entity.enums.PaymentStatus;
import com.fleetx.exception.ConflictException;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.BookingRepository;
import com.fleetx.repository.PaymentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Payment simulation. No gateway is contacted - pressing Pay always succeeds,
 * except for a wallet payment with insufficient balance.
 */
@Service
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final BookingRepository bookingRepository;
    private final WalletService walletService;

    public PaymentService(PaymentRepository paymentRepository,
                          BookingRepository bookingRepository,
                          WalletService walletService) {
        this.paymentRepository = paymentRepository;
        this.bookingRepository = bookingRepository;
        this.walletService = walletService;
    }

    @Transactional
    public PaymentResponse pay(PaymentRequest request, Long userId) {
        Booking booking = bookingRepository.findByIdAndUserId(request.bookingId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Booking", request.bookingId()));

        if (booking.getStatus() == BookingStatus.CANCELLED) {
            throw new ConflictException("This booking was cancelled and cannot be paid for");
        }

        Payment existing = paymentRepository.findByBookingId(booking.getId()).orElse(null);
        if (existing != null && existing.getStatus() == PaymentStatus.SUCCESS) {
            throw new ConflictException("Booking " + booking.getReference() + " is already paid");
        }

        // Wallet is the only method that can fail, and only when the balance is short.
        if (request.method() == PaymentMethod.WALLET) {
            walletService.debit(userId, booking.getAmount(),
                    "Charging booking " + booking.getReference());
        }

        Payment payment = existing == null ? new Payment() : existing;
        payment.setBooking(booking);
        payment.setAmount(booking.getAmount());
        payment.setMethod(request.method());
        payment.setStatus(PaymentStatus.SUCCESS);
        payment.setTransactionRef("TXN-" + UUID.randomUUID().toString().substring(0, 10).toUpperCase());
        payment.setPaidAt(LocalDateTime.now());
        paymentRepository.save(payment);

        // A paid booking is a confirmed booking - this is what unlocks the QR screen.
        booking.setStatus(BookingStatus.CONFIRMED);
        booking.setPayment(payment);
        bookingRepository.save(booking);

        return PaymentResponse.from(payment, "Payment Successful");
    }

    @Transactional(readOnly = true)
    public PaymentResponse getPayment(Long id, Long userId) {
        Payment payment = paymentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Payment", id));

        if (!payment.getBooking().getUser().getId().equals(userId)) {
            throw new ResourceNotFoundException("Payment", id);
        }

        return PaymentResponse.from(payment, "Payment " + payment.getStatus().name().toLowerCase());
    }
}
