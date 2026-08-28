package com.fleetx.entity;

import com.fleetx.entity.enums.ChargerStatus;
import com.fleetx.entity.enums.ChargerType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "chargers")
@Getter
@Setter
@NoArgsConstructor
public class Charger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Human readable label shown in the app, e.g. "C1". */
    @Column(nullable = false, length = 20)
    private String code;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ChargerType type;

    /** Output in kW. */
    @Column(nullable = false)
    private Double power;

    @Column(name = "price_per_kwh", nullable = false, precision = 10, scale = 2)
    private BigDecimal pricePerKwh;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ChargerStatus status = ChargerStatus.AVAILABLE;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "station_id", nullable = false)
    private ChargingStation station;
}
