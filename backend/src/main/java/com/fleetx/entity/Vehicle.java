package com.fleetx.entity;

import com.fleetx.entity.enums.VehicleStatus;
import com.fleetx.entity.enums.VehicleType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "vehicles")
@Getter
@Setter
@NoArgsConstructor
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "vehicle_number", nullable = false, unique = true, length = 20)
    private String vehicleNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "vehicle_type", nullable = false, length = 20)
    private VehicleType vehicleType;

    @Column(name = "driver_name", length = 100)
    private String driverName;

    @Column(name = "driver_contact", length = 20)
    private String driverContact;

    /** Battery pack size in kWh. */
    @Column(name = "battery_capacity")
    private Double batteryCapacity;

    /** Remaining range in km. */
    @Column(name = "current_range")
    private Double currentRange;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private VehicleStatus status = VehicleStatus.ACTIVE;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
}
