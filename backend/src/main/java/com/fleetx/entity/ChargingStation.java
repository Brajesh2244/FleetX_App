package com.fleetx.entity;

import com.fleetx.entity.enums.AvailabilityStatus;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "charging_stations")
@Getter
@Setter
@NoArgsConstructor
public class ChargingStation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false, length = 255)
    private String address;

    private Double latitude;

    private Double longitude;

    /** Pre-computed demo distance from the user in km (no live geolocation in the prototype). */
    private Double distance;

    private Double rating;

    @Column(name = "operating_hours", length = 60)
    private String operatingHours;

    /**
     * Cached availability, recalculated whenever charger state changes.
     * Green = AVAILABLE, Yellow = LIMITED, Red = FULL in the mobile app.
     */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AvailabilityStatus status = AvailabilityStatus.AVAILABLE;

    @OneToMany(mappedBy = "station", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Charger> chargers = new ArrayList<>();

    @OneToMany(mappedBy = "station", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ParkingSlot> parkingSlots = new ArrayList<>();

    public void addCharger(Charger charger) {
        charger.setStation(this);
        this.chargers.add(charger);
    }

    public void addParkingSlot(ParkingSlot slot) {
        slot.setStation(this);
        this.parkingSlots.add(slot);
    }
}
