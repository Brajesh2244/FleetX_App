import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/station.dart';

/// Schematic map drawn from the stations' sample coordinates.
///
/// Deliberately dependency-free: swapping in `google_maps_flutter` later means
/// replacing this one widget, nothing else in the app touches map code.
class MapPreview extends StatelessWidget {
  const MapPreview({
    super.key,
    required this.stations,
    this.selectedId,
    this.onSelect,
    this.height = 230,
  });

  final List<Station> stations;
  final int? selectedId;
  final void Function(Station station)? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    final plotted =
        stations.where((s) => s.latitude != null && s.longitude != null).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),
            if (plotted.isEmpty)
              const Center(
                child: Text(
                  'No station coordinates to plot',
                  style: TextStyle(color: AppTheme.neutral, fontSize: 13),
                ),
              )
            else
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bounds = _Bounds.of(plotted);
                    return Stack(
                      children: [
                        for (final station in plotted)
                          _Pin(
                            station: station,
                            offset: bounds.project(
                              station,
                              Size(constraints.maxWidth, constraints.maxHeight),
                            ),
                            selected: station.id == selectedId,
                            onTap: onSelect == null
                                ? null
                                : () => onSelect!(station),
                          ),
                      ],
                    );
                  },
                ),
              ),
            const Positioned(
              left: 10,
              top: 10,
              child: _Badge(text: 'Prototype map · sample coordinates'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bounds {
  _Bounds(this.minLat, this.maxLat, this.minLng, this.maxLng);

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  factory _Bounds.of(List<Station> stations) {
    var minLat = stations.first.latitude!;
    var maxLat = minLat;
    var minLng = stations.first.longitude!;
    var maxLng = minLng;
    for (final s in stations) {
      minLat = s.latitude! < minLat ? s.latitude! : minLat;
      maxLat = s.latitude! > maxLat ? s.latitude! : maxLat;
      minLng = s.longitude! < minLng ? s.longitude! : minLng;
      maxLng = s.longitude! > maxLng ? s.longitude! : maxLng;
    }
    return _Bounds(minLat, maxLat, minLng, maxLng);
  }

  /// Maps a station's lat/lng into the widget's pixel box, inset so pins at the
  /// extremes are not clipped. Latitude is flipped because north is up.
  Offset project(Station station, Size size) {
    const inset = 34.0;
    final usableWidth = (size.width - inset * 2).clamp(1.0, double.infinity);
    final usableHeight = (size.height - inset * 2).clamp(1.0, double.infinity);

    final lngSpan = maxLng - minLng;
    final latSpan = maxLat - minLat;

    final x = lngSpan == 0 ? 0.5 : (station.longitude! - minLng) / lngSpan;
    final y = latSpan == 0 ? 0.5 : (maxLat - station.latitude!) / latSpan;

    return Offset(inset + x * usableWidth, inset + y * usableHeight);
  }
}

class _Pin extends StatelessWidget {
  const _Pin({
    required this.station,
    required this.offset,
    required this.selected,
    this.onTap,
  });

  final Station station;
  final Offset offset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(station.status);
    final size = selected ? 34.0 : 28.0;

    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: Tooltip(
        message: '${station.name}\n${station.availableChargers} chargers free',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.4),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: selected ? 12 : 5,
                  spreadRadius: selected ? 2 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${station.availableChargers}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: selected ? 14 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          color: AppTheme.neutral,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFF6F2),
    );

    final line = Paint()
      ..color = const Color(0xFFDCE7E1)
      ..strokeWidth = 1;

    const step = 32.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    // A couple of thicker strokes to read as arterial roads.
    final road = Paint()
      ..color = const Color(0xFFCBDAD2)
      ..strokeWidth = 7;
    canvas.drawLine(
      Offset(0, size.height * 0.62),
      Offset(size.width, size.height * 0.44),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.34, 0),
      Offset(size.width * 0.52, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
