package com.fleetx.service;

import com.fleetx.dto.ChargerResponse;
import com.fleetx.dto.StationRequest;
import com.fleetx.dto.StationResponse;
import com.fleetx.entity.Charger;
import com.fleetx.entity.ChargingStation;
import com.fleetx.entity.ParkingSlot;
import com.fleetx.entity.enums.AvailabilityStatus;
import com.fleetx.entity.enums.ChargerStatus;
import com.fleetx.entity.enums.SlotStatus;
import com.fleetx.exception.ResourceNotFoundException;
import com.fleetx.repository.ChargerRepository;
import com.fleetx.repository.ChargingStationRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
public class StationService {

    private final ChargingStationRepository stationRepository;
    private final ChargerRepository chargerRepository;

    public StationService(ChargingStationRepository stationRepository, ChargerRepository chargerRepository) {
        this.stationRepository = stationRepository;
        this.chargerRepository = chargerRepository;
    }

    /** Station list for the map / list screen, nearest first. Chargers are omitted here. */
    @Transactional(readOnly = true)
    public List<StationResponse> listStations(String search) {
        List<ChargingStation> stations = (search == null || search.isBlank())
                ? stationRepository.findAllByOrderByDistanceAsc()
                : stationRepository.findByNameContainingIgnoreCaseOrAddressContainingIgnoreCase(search, search);

        return stations.stream()
                .sorted(Comparator.comparing(ChargingStation::getDistance,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .map(s -> toResponse(s, false))
                .toList();
    }

    /** Station detail screen - includes the charger list. */
    @Transactional(readOnly = true)
    public StationResponse getStation(Long id) {
        return toResponse(requireStation(id), true);
    }

    @Transactional(readOnly = true)
    public List<ChargerResponse> listChargers(Long stationId) {
        requireStation(stationId);
        return chargerRepository.findByStationIdOrderByIdAsc(stationId).stream()
                .map(ChargerResponse::from)
                .toList();
    }

    @Transactional
    public StationResponse create(StationRequest request) {
        ChargingStation station = new ChargingStation();
        apply(request, station);
        return toResponse(stationRepository.save(station), true);
    }

    @Transactional
    public StationResponse update(Long id, StationRequest request) {
        ChargingStation station = requireStation(id);
        apply(request, station);
        return toResponse(stationRepository.save(station), true);
    }

    @Transactional
    public void delete(Long id) {
        stationRepository.delete(requireStation(id));
    }

    /**
     * Recalculates and persists the cached station status after charger or booking changes.
     * Called by BookingService so the green / yellow / red badge stays in sync.
     */
    @Transactional
    public void refreshStatus(ChargingStation station) {
        station.setStatus(computeStatus(station.getChargers()));
        stationRepository.save(station);
    }

    public ChargingStation requireStation(Long id) {
        return stationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Charging station", id));
    }

    static AvailabilityStatus computeStatus(List<Charger> chargers) {
        if (chargers == null || chargers.isEmpty()) {
            return AvailabilityStatus.FULL;
        }
        long available = chargers.stream()
                .filter(c -> c.getStatus() == ChargerStatus.AVAILABLE)
                .count();

        if (available == 0) {
            return AvailabilityStatus.FULL;
        }
        // Half or fewer free chargers reads as "limited" in the app.
        return available * 2 <= chargers.size() ? AvailabilityStatus.LIMITED : AvailabilityStatus.AVAILABLE;
    }

    StationResponse toResponse(ChargingStation s, boolean includeChargers) {
        List<Charger> chargers = s.getChargers();
        List<ParkingSlot> slots = s.getParkingSlots();

        int availableChargers = (int) chargers.stream()
                .filter(c -> c.getStatus() == ChargerStatus.AVAILABLE)
                .count();
        int availableSlots = (int) slots.stream()
                .filter(p -> p.getStatus() == SlotStatus.AVAILABLE)
                .count();

        return new StationResponse(
                s.getId(),
                s.getName(),
                s.getAddress(),
                s.getLatitude(),
                s.getLongitude(),
                s.getDistance(),
                s.getRating(),
                s.getOperatingHours(),
                s.getStatus().name(),
                chargers.size(),
                availableChargers,
                slots.size(),
                availableSlots,
                includeChargers ? chargers.stream().map(ChargerResponse::from).toList() : null
        );
    }

    private void apply(StationRequest request, ChargingStation station) {
        station.setName(request.name());
        station.setAddress(request.address());
        station.setLatitude(request.latitude());
        station.setLongitude(request.longitude());
        station.setDistance(request.distance());
        station.setRating(request.rating());
        station.setOperatingHours(request.operatingHours());
        station.setStatus(computeStatus(station.getChargers()));
    }
}
