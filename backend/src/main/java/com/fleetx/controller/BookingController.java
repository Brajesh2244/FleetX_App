package com.fleetx.controller;

import com.fleetx.dto.BookingRequest;
import com.fleetx.dto.BookingResponse;
import com.fleetx.security.UserPrincipal;
import com.fleetx.service.BookingService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bookings")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @PostMapping
    public ResponseEntity<BookingResponse> create(@Valid @RequestBody BookingRequest request,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(bookingService.create(request, principal.getId()));
    }

    /** Booking history for the signed in driver, newest first. */
    @GetMapping
    public ResponseEntity<List<BookingResponse>> list(@AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(bookingService.listMyBookings(principal.getId()));
    }

    @GetMapping("/active")
    public ResponseEntity<BookingResponse> active(@AuthenticationPrincipal UserPrincipal principal) {
        BookingResponse active = bookingService.findActiveBooking(principal.getId());
        return active == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(active);
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookingResponse> get(@PathVariable Long id,
                                               @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(bookingService.getMyBooking(id, principal.getId()));
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<BookingResponse> cancel(@PathVariable Long id,
                                                  @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(bookingService.cancel(id, principal.getId()));
    }
}
