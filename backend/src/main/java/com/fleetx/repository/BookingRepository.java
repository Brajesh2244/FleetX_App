package com.fleetx.repository;

import com.fleetx.entity.Booking;
import com.fleetx.entity.enums.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface BookingRepository extends JpaRepository<Booking, Long> {

    List<Booking> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<Booking> findByIdAndUserId(Long id, Long userId);

    Optional<Booking> findByReference(String reference);

    List<Booking> findAllByOrderByCreatedAtDesc();

    long countByStatus(BookingStatus status);

    /**
     * True when the charger already has an overlapping live booking on that date.
     * Two ranges overlap when newStart < existingEnd AND newEnd > existingStart.
     */
    @Query("""
            SELECT COUNT(b) > 0 FROM Booking b
            WHERE b.charger.id = :chargerId
              AND b.bookingDate = :date
              AND b.status IN :liveStatuses
              AND b.startTime < :endTime
              AND b.endTime > :startTime
            """)
    boolean hasChargerConflict(@Param("chargerId") Long chargerId,
                               @Param("date") LocalDate date,
                               @Param("startTime") LocalTime startTime,
                               @Param("endTime") LocalTime endTime,
                               @Param("liveStatuses") Collection<BookingStatus> liveStatuses);

    /** Same overlap rule, applied to a parking slot. */
    @Query("""
            SELECT COUNT(b) > 0 FROM Booking b
            WHERE b.parkingSlot.id = :slotId
              AND b.bookingDate = :date
              AND b.status IN :liveStatuses
              AND b.startTime < :endTime
              AND b.endTime > :startTime
            """)
    boolean hasParkingConflict(@Param("slotId") Long slotId,
                               @Param("date") LocalDate date,
                               @Param("startTime") LocalTime startTime,
                               @Param("endTime") LocalTime endTime,
                               @Param("liveStatuses") Collection<BookingStatus> liveStatuses);

    /** Most recent booking that is still upcoming / in progress, used by the dashboard card. */
    @Query("""
            SELECT b FROM Booking b
            WHERE b.user.id = :userId
              AND b.status IN :liveStatuses
            ORDER BY b.bookingDate ASC, b.startTime ASC
            """)
    List<Booking> findActiveBookings(@Param("userId") Long userId,
                                     @Param("liveStatuses") Collection<BookingStatus> liveStatuses);

    @Query("SELECT COALESCE(SUM(b.amount), 0) FROM Booking b WHERE b.status <> com.fleetx.entity.enums.BookingStatus.CANCELLED")
    BigDecimal sumRevenue();
}
