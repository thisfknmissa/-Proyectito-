import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/bus_tracker_provider.dart';
import '../models/bus_stop.dart';
import '../models/bus_route.dart';
import 'stops_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _followBus = true;

  static const LatLng _campusCenter = LatLng(22.277, -97.8624);
  static const double _defaultZoom = 16.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusTrackerProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BusTrackerProvider>(
        builder: (context, tracker, _) {
          if (tracker.isLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE65100)),
                  SizedBox(height: 16),
                  Text('Cargando ruta...'),
                ],
              ),
            );
          }
          if (tracker.error != null) {
            return Center(child: Text(tracker.error!));
          }

          final route = tracker.route!;
          final estimation = tracker.estimation;

          // Auto-follow the bus
          if (_followBus && estimation != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _mapController.move(estimation.position, _defaultZoom);
              } catch (_) {}
            });
          }

          // Build route polyline points
          final routePoints =
              route.stops.map((s) => s.position).toList()
                ..add(route.stops.first.position); // close the loop

          return Stack(
            children: [
              // ── MAP ──────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _campusCenter,
                  initialZoom: _defaultZoom,
                  onMapEvent: (_) {
                    // If user moves the map, stop following
                    setState(() => _followBus = false);
                  },
                ),
                children: [
                  // OSM tile layer
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.uat.bus_tracker_uat',
                    maxZoom: 19,
                  ),

                  // Route polyline
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        color: const Color(0xFFE65100),
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),

                  // Stop markers
                  MarkerLayer(
                    markers: [
                      // Bus stops
                      ...route.stops.map((stop) => _buildStopMarker(stop)),
                      // Bus position
                      if (estimation != null && !estimation.notYetDeparted)
                        _buildBusMarker(estimation.position),
                    ],
                  ),
                ],
              ),

              // ── TOP APP BAR ───────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_bus,
                                  color: Color(0xFFE65100)),
                              const SizedBox(width: 8),
                              Text(
                                route.routeName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _iconButton(
                        icon: Icons.tune,
                        tooltip: 'Configurar salida',
                        onTap: () => _showDepartureDialog(context, tracker),
                      ),
                    ],
                  ),
                ),
              ),

              // ── CENTER BUS BUTTON ─────────────────────────────────
              Positioned(
                right: 12,
                bottom: 180,
                child: FloatingActionButton.small(
                  heroTag: 'centerBus',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE65100),
                  tooltip: 'Centrar en el bus',
                  onPressed: () {
                    if (estimation != null) {
                      setState(() => _followBus = true);
                      _mapController.move(estimation.position, _defaultZoom);
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),

              // ── STOPS LIST BUTTON ─────────────────────────────────
              Positioned(
                right: 12,
                bottom: 130,
                child: FloatingActionButton.small(
                  heroTag: 'stopsList',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE65100),
                  tooltip: 'Lista de paradas',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StopsScreen()),
                  ),
                  child: const Icon(Icons.format_list_bulleted),
                ),
              ),

              // ── BOTTOM STATUS CARD ────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildStatusCard(tracker),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BusTrackerProvider tracker) {
    final estimation = tracker.estimation;
    final route = tracker.route;
    final departure = tracker.activeDepartureTime;

    final String title;
    final String subtitle;
    final Color accentColor;

    if (route == null) {
      title = 'Sin datos de ruta';
      subtitle = '';
      accentColor = Colors.grey;
    } else if (departure == null) {
      title = 'Fuera de horario';
      final next = tracker.route != null
          ? _nextDepartureStr(route)
          : '';
      subtitle = next.isNotEmpty ? 'Próxima salida: $next' : '';
      accentColor = Colors.grey;
    } else if (estimation == null) {
      title = 'Calculando...';
      subtitle = '';
      accentColor = const Color(0xFFE65100);
    } else if (estimation.notYetDeparted) {
      title = 'El bus no ha salido aún';
      subtitle = 'Salida desde ${route.stops.first.name}';
      accentColor = Colors.orange;
    } else if (estimation.hasCompleted) {
      title = 'Ruta completada';
      subtitle = estimation.statusMessage;
      accentColor = Colors.green;
    } else {
      title = estimation.statusMessage;
      final mins = estimation.minutesToNextStop.round();
      final margin = estimation.errorMarginMinutes.round();
      subtitle = mins <= 0
          ? 'Llegando ahora'
          : '~$mins min ± $margin min';
      accentColor = const Color(0xFFE65100);
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_bus, color: accentColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              // Mode chip
              _modeBadge(tracker),
            ],
          ),
          const SizedBox(height: 8),
          // Refresh indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.refresh, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('Actualiza cada 15 seg',
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeBadge(BusTrackerProvider tracker) {
    final isManual = tracker.useManualDeparture;
    return GestureDetector(
      onTap: () => _showDepartureDialog(context, tracker),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isManual
              ? Colors.blue.shade50
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isManual ? Colors.blue.shade200 : Colors.orange.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isManual ? Icons.edit_calendar : Icons.schedule,
              size: 12,
              color: isManual ? Colors.blue : Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              isManual ? 'Manual' : 'Auto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isManual ? Colors.blue : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextDepartureStr(BusRoute route) {
    final next = _parseTime(route.firstDepartureHour, route.firstDepartureMinute);
    if (next == null) return '';
    final h = next.hour.toString().padLeft(2, '0');
    final m = next.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime? _parseTime(int hour, int minute) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  Marker _buildStopMarker(BusStop stop) {
    return Marker(
      point: stop.position,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _showStopInfo(stop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: stop.isTerminal
                    ? const Color(0xFFE65100)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE65100),
                  width: 2.5,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
              ),
              child: Icon(
                _stopIcon(stop.icon),
                size: 18,
                color: stop.isTerminal ? Colors.white : const Color(0xFFE65100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildBusMarker(LatLng position) {
    return Marker(
      point: position,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE65100),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.directions_bus, color: Colors.white, size: 26),
      ),
    );
  }

  IconData _stopIcon(String icon) {
    switch (icon) {
      case 'gym':
        return Icons.fitness_center;
      case 'books':
        return Icons.menu_book;
      case 'booth':
        return Icons.local_police;
      case 'food':
        return Icons.restaurant;
      case 'fit':
        return Icons.engineering;
      case 'fadycs':
        return Icons.gavel;
      case 'fadu':
        return Icons.architecture;
      case 'fcat':
        return Icons.biotech;
      default:
        return Icons.place;
    }
  }

  void _showStopInfo(BusStop stop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_stopIcon(stop.icon), color: const Color(0xFFE65100)),
                const SizedBox(width: 12),
                Text(stop.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(stop.description,
                style: TextStyle(color: Colors.grey.shade600)),
            if (stop.isTerminal) ...[
              const SizedBox(height: 8),
              const Chip(
                label: Text('Terminal'),
                backgroundColor: Color(0xFFE65100),
                labelStyle: TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDepartureDialog(
      BuildContext context, BusTrackerProvider tracker) async {
    final result = await showDialog<_DepartureDialogResult>(
      context: context,
      builder: (ctx) => _DepartureDialog(tracker: tracker),
    );
    if (result == null) return;
    if (result.useAuto) {
      tracker.setAutoMode();
    } else if (result.time != null) {
      final now = DateTime.now();
      final departure = DateTime(
          now.year, now.month, now.day, result.time!.hour, result.time!.minute);
      tracker.setManualDeparture(departure);
    }
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Icon(icon, color: const Color(0xFFE65100), size: 20),
      ),
    );
  }
}

class _DepartureDialogResult {
  final bool useAuto;
  final TimeOfDay? time;
  const _DepartureDialogResult({required this.useAuto, this.time});
}

class _DepartureDialog extends StatefulWidget {
  final BusTrackerProvider tracker;
  const _DepartureDialog({required this.tracker});

  @override
  State<_DepartureDialog> createState() => _DepartureDialogState();
}

class _DepartureDialogState extends State<_DepartureDialog> {
  bool _useAuto = true;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _useAuto = !widget.tracker.useManualDeparture;
    final dep = widget.tracker.manualDepartureTime;
    if (dep != null) {
      _selectedTime = TimeOfDay(hour: dep.hour, minute: dep.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.schedule, color: Color(0xFFE65100)),
          SizedBox(width: 8),
          Text('Configurar salida'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¿Cuándo salió el autobús de la terminal (GYM)?',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            value: true,
            groupValue: _useAuto,
            activeColor: const Color(0xFFE65100),
            title: const Text('Automático (cada 15 min desde 6:00)'),
            subtitle: const Text('El app calcula la última salida'),
            onChanged: (v) => setState(() => _useAuto = v!),
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: _useAuto,
            activeColor: const Color(0xFFE65100),
            title: const Text('Manual'),
            subtitle: Text('Última salida: ${_selectedTime.format(context)}'),
            onChanged: (v) => setState(() => _useAuto = v!),
          ),
          if (!_useAuto)
            TextButton.icon(
              icon: const Icon(Icons.access_time, color: Color(0xFFE65100)),
              label: const Text('Cambiar hora',
                  style: TextStyle(color: Color(0xFFE65100))),
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (t != null) setState(() => _selectedTime = t);
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE65100),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(
            context,
            _useAuto
                ? const _DepartureDialogResult(useAuto: true)
                : _DepartureDialogResult(useAuto: false, time: _selectedTime),
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
