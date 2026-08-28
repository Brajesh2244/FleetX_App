import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/station.dart';
import '../services/station_service.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/map_preview.dart';
import 'station_details_screen.dart';

class StationListScreen extends StatefulWidget {
  const StationListScreen({super.key});

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  final GlobalKey<AsyncViewState<List<Station>>> _viewKey = GlobalKey();
  final TextEditingController _search = TextEditingController();

  String _query = '';
  bool _showMap = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    if (value.trim() == _query) return;
    setState(() => _query = value.trim());
    _viewKey.currentState?.reload();
  }

  Future<void> _openStation(Station station) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StationDetailsScreen(stationId: station.id)),
    );
    await _viewKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EV charging stations'),
        actions: [
          IconButton(
            tooltip: _showMap ? 'Hide map' : 'Show map',
            onPressed: () => setState(() => _showMap = !_showMap),
            icon: Icon(_showMap ? Icons.map_rounded : Icons.map_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: _applySearch,
              onChanged: (v) {
                // Clearing the field restores the full list immediately.
                if (v.isEmpty) _applySearch('');
              },
              decoration: InputDecoration(
                hintText: 'Search by name or area',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          _search.clear();
                          _applySearch('');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      body: AsyncView<List<Station>>(
        key: _viewKey,
        load: () => StationService.list(search: _query),
        builder: (context, stations, reload) {
          if (stations.isEmpty) {
            return ListView(
              children: [
                EmptyState(
                  icon: Icons.ev_station_rounded,
                  title: _query.isEmpty ? 'No stations yet' : 'No matches',
                  message: _query.isEmpty
                      ? 'Stations added by the admin will show up here.'
                      : 'Nothing matched "$_query". Try a different area.',
                  actionLabel: _query.isEmpty ? null : 'Clear search',
                  onAction: _query.isEmpty
                      ? null
                      : () {
                          _search.clear();
                          _applySearch('');
                        },
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              if (_showMap) ...[
                MapPreview(stations: stations, onSelect: _openStation),
                const SizedBox(height: 8),
                const _Legend(),
                const SizedBox(height: 16),
              ],
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${stations.length} station${stations.length == 1 ? '' : 's'} · '
                  'nearest first',
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.neutral),
                ),
              ),
              ...stations.map(
                (station) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StationCard(
                    station: station,
                    onTap: () => _openStation(station),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendDot(color: AppTheme.available, label: 'Available'),
        _LegendDot(color: AppTheme.limited, label: 'Limited'),
        _LegendDot(color: AppTheme.full, label: 'Full'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 9,
          width: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.neutral),
        ),
      ],
    );
  }
}
