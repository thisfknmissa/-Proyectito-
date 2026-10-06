import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/bus_tracker_provider.dart';
import '../models/bus_stop.dart';
import '../models/bus_route.dart';
import 'stops_screen.dart';

enum MapTileType {
  streets,
  satellite,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  bool _followBus = true;
  MapTileType _currentTileType = MapTileType.streets;

  // ── Coordenadas del campus ────────────────────────────────────────────────
  static const LatLng _campusCenter = LatLng(22.2766, -97.8616);
  static const double _defaultZoom = 16.4;
  static const double _minZoom = 15.0;
  static const double _maxZoom = 18.5;

  // Bounding box del campus ajustado exactamente a la nueva ruta
  static final LatLngBounds _campusBounds = LatLngBounds(
    const LatLng(22.2730, -97.8675), // SW
    const LatLng(22.2805, -97.8560), // NE
  );

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
      backgroundColor: AppColors.background,
      body: Consumer<BusTrackerProvider>(
        builder: (context, tracker, _) {
          if (tracker.isLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.routeBlue),
                  const SizedBox(height: 20),
                  Text(
                    'Cargando ruta...',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }
          if (tracker.error != null) {
            return Center(
              child: Text(
                tracker.error!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final route = tracker.route!;
          final estimation = tracker.estimation;

          // Auto-seguir el bus si está activo
          if (_followBus && estimation != null && !estimation.notYetDeparted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                _mapController.move(estimation.position, _mapController.camera.zoom);
              } catch (_) {}
            });
          }

          // Polilínea con los 30 waypoints exactos de la ruta
          final List<LatLng> routePolyline = _buildRoutePolyline(route);

          return Stack(
            children: [
              // ── MAPA ──────────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _campusCenter,
                  initialZoom: _defaultZoom,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  cameraConstraint: CameraConstraint.containCenter(
                    bounds: _campusBounds,
                  ),
                  onMapEvent: (event) {
                    if (event is MapEventMove &&
                        event.source != MapEventSource.mapController) {
                      setState(() => _followBus = false);
                    }
                  },
                ),
                children: [
                  // Capa de mosaicos sin necesidad de API key
                  if (_currentTileType == MapTileType.streets)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.uat.bus_tracker_uat',
                      maxZoom: 19,
                      maxNativeZoom: 19,
                    )
                  else
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'com.uat.bus_tracker_uat',
                      maxZoom: 19,
                      maxNativeZoom: 19,
                    ),

                  // Resplandor exterior de la ruta (glow azul)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePolyline,
                        color: const Color(0xFF0288D1).withOpacity(0.35),
                        strokeWidth: 15.0,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),

                  // Borde exterior contrastante blanco
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePolyline,
                        color: Colors.white.withOpacity(0.9),
                        strokeWidth: 7.0,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),

                  // Línea de ruta principal (azul eléctrico nítido)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePolyline,
                        color: const Color(0xFF0288D1),
                        strokeWidth: 5.0,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),

                  // Marcadores de paradas y bus
                  MarkerLayer(
                    markers: [
                      ...route.stops.map((stop) => _buildStopMarker(stop)),
                      if (estimation != null)
                        _buildBusMarker(
                          estimation.position,
                          estimation.isStoppedAtStop,
                        ),
                    ],
                  ),
                ],
              ),

              // ── BARRA SUPERIOR ────────────────────────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.routeBlue.withOpacity(0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0288D1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      route.routeName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Campus Sur · UAT (5-25 km/h)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _iconButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Configurar salida',
                        onTap: () =>
                            _showDepartureDialog(context, tracker),
                      ),
                    ],
                  ),
                ),
              ),

              // ── BOTONES FLOTANTES (derecha) ────────────────────────────────
              Positioned(
                right: 12,
                bottom: 205,
                child: Column(
                  children: [
                    // Cambiar tipo de mapa (Calles / Satélite)
                    _mapFab(
                      icon: _currentTileType == MapTileType.streets
                          ? Icons.satellite_alt_rounded
                          : Icons.map_rounded,
                      tooltip: _currentTileType == MapTileType.streets
                          ? 'Cambiar a Satélite'
                          : 'Cambiar a Calles',
                      onPressed: () {
                        setState(() {
                          _currentTileType = _currentTileType == MapTileType.streets
                              ? MapTileType.satellite
                              : MapTileType.streets;
                        });
                      },
                      active: _currentTileType == MapTileType.satellite,
                    ),
                    const SizedBox(height: 8),
                    _mapFab(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Centrar en el bus',
                      onPressed: () {
                        if (estimation != null) {
                          setState(() => _followBus = true);
                          _mapController.move(
                              estimation.position, _defaultZoom);
                        } else {
                          _mapController.move(_campusCenter, _defaultZoom);
                        }
                      },
                      active: _followBus,
                    ),
                    const SizedBox(height: 8),
                    _mapFab(
                      icon: Icons.format_list_bulleted_rounded,
                      tooltip: 'Lista de paradas',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StopsScreen()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _mapFab(
                      icon: Icons.crop_free_rounded,
                      tooltip: 'Ver campus completo',
                      onPressed: () {
                        setState(() => _followBus = false);
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: _campusBounds,
                            padding: const EdgeInsets.all(24),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── TARJETA DE ESTADO (inferior) ───────────────────────────────
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

  // ── Construir polilínea con waypoints del JSON ─────────────────────────────
  List<LatLng> _buildRoutePolyline(BusRoute route) {
    if (route.waypoints.isNotEmpty) {
      return route.waypoints;
    }
    return route.stops.map((s) => s.position).toList()
      ..add(route.stops.first.position);
  }

  // ── TARJETA DE ESTADO CON SOPORTE EN TIEMPO REAL ──────────────────────────
  Widget _buildStatusCard(BusTrackerProvider tracker) {
    final estimation = tracker.estimation;
    final route = tracker.route;
    final departure = tracker.activeDepartureTime;

    final String title;
    final String subtitle;
    final Color accentColor;
    final IconData statusIcon;

    if (route == null) {
      title = 'Sin datos de ruta';
      subtitle = '';
      accentColor = AppColors.textMuted;
      statusIcon = Icons.error_outline;
    } else if (departure == null) {
      title = 'Fuera de horario';
      final next = _nextDepartureStr(route);
      subtitle = next.isNotEmpty
          ? 'Próxima salida a las $next desde Base'
          : 'Servicio concluido por hoy';
      accentColor = AppColors.textMuted;
      statusIcon = Icons.nightlife_rounded;
    } else if (estimation == null) {
      title = 'Calculando posición en tiempo real...';
      subtitle = '';
      accentColor = AppColors.routeBlue;
      statusIcon = Icons.sync_rounded;
    } else if (estimation.notYetDeparted) {
      title = 'En Base · Listo para salir';
      subtitle = 'Salida de jornada programada';
      accentColor = AppColors.warning;
      statusIcon = Icons.garage_rounded;
    } else if (estimation.hasCompleted) {
      title = 'Recorrido completado';
      subtitle = 'En Base UAT · Esperando siguiente salida';
      accentColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (estimation.isStoppedAtStop) {
      // ── AUTOBÚS DETENIDO EN PARADA (ESPERA PROGRAMADA) ───────────────────
      final stopName = estimation.currentDwellStop?.name ?? 'Parada';
      final sec = estimation.stoppedRemainingSeconds;
      final m = sec ~/ 60;
      final s = sec % 60;
      final timeStr = m > 0 ? '${m}m ${s}s' : '${s}s';
      final isCaseta = estimation.currentDwellStop?.id == 'caseta';

      title = 'Detenido en $stopName';
      subtitle = isCaseta
          ? 'Espera en Caseta (5-10 min) · Restan $timeStr'
          : 'Espera en parada (~2 min) · Restan $timeStr';
      accentColor = AppColors.uatOrange;
      statusIcon = Icons.pause_circle_filled_rounded;
    } else {
      // ── AUTOBÚS EN MOVIMIENTO ─────────────────────────────────────────────
      title = estimation.statusMessage;
      final remSec = (estimation.minutesToNextStop * 60).round();
      final m = remSec ~/ 60;
      final s = remSec % 60;
      final timeStr = m > 0 ? '${m}m ${s}s' : '${s}s';
      final speed = estimation.currentSpeedKmh.round();

      subtitle = 'Llegada en ~$timeStr · Vel: ~$speed km/h (rango 5-25 km/h)';
      accentColor = const Color(0xFF0288D1);
      statusIcon = Icons.directions_bus_filled_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Icon(statusIcon,
                          color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _modeBadge(tracker),
                  ],
                ),
                const SizedBox(height: 10),
                // Indicador de tiempo real (parpadeo en verde)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'EN VIVO · Actualización continua cada 1s',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBadge(BusTrackerProvider tracker) {
    final isManual = tracker.useManualDeparture;
    final color = isManual ? AppColors.uatOrange : AppColors.routeBlue;
    return GestureDetector(
      onTap: () => _showDepartureDialog(context, tracker),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isManual
                  ? Icons.edit_calendar_rounded
                  : Icons.schedule_rounded,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isManual ? 'Manual' : 'Auto',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextDepartureStr(BusRoute route) {
    final h = route.firstDepartureHour.toString().padLeft(2, '0');
    final m = route.firstDepartureMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── MARCADOR DE PARADA (Estilo Escudo + Nombre Elegante) ──────────────────
  Marker _buildStopMarker(BusStop stop) {
    final isBase = stop.id == 'base';
    final isCaseta = stop.id == 'caseta';
    final badgeColor = isBase
        ? const Color(0xFF1565C0)
        : (isCaseta ? const Color(0xFFD84315) : AppColors.uatOrange);
    const badgeWidth = 44.0;
    const badgeHeight = 44.0;

    return Marker(
      point: stop.position,
      width: 70,
      height: 72,
      alignment: const Alignment(0, -0.7),
      child: GestureDetector(
        onTap: () => _showStopInfo(stop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Escudo con icono
            Container(
              width: badgeWidth,
              height: badgeHeight,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBase
                      ? Colors.lightBlueAccent
                      : (isCaseta ? Colors.amberAccent : Colors.white),
                  width: (isBase || isCaseta) ? 2.2 : 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _stopIcon(stop.icon),
                color: Colors.white,
                size: 24,
              ),
            ),
            // Punta inferior
            CustomPaint(
              size: const Size(10, 6),
              painter: _BadgePointerPainter(color: badgeColor),
            ),
            const SizedBox(height: 2),
            // Etiqueta con el nombre de la facultad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 0.5,
                ),
              ),
              child: Text(
                stop.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MARCADOR DEL BUS EN TIEMPO REAL ───────────────────────────────────────
  Marker _buildBusMarker(LatLng position, bool isStopped) {
    final color = isStopped ? AppColors.uatOrange : const Color(0xFF0288D1);
    return Marker(
      point: position,
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Resplandor exterior
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
            ),
          ),
          // Círculo principal
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isStopped
                  ? Icons.pause_circle_filled_rounded
                  : Icons.directions_bus_filled_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  IconData _stopIcon(String icon) {
    switch (icon) {
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'books':
        return Icons.menu_book_rounded;
      case 'booth':
        return Icons.security_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'fit':
        return Icons.engineering_rounded;
      case 'fadycs':
        return Icons.balance_rounded;
      case 'fadu':
        return Icons.architecture_rounded;
      case 'fcat':
        return Icons.show_chart_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  void _showStopInfo(BusStop stop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.uatOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_stopIcon(stop.icon),
                      color: AppColors.uatOrange, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.uatOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          stop.id == 'caseta'
                              ? 'Espera: 5 - 10 min'
                              : 'Espera: ~2 min',
                          style: const TextStyle(
                            color: AppColors.uatOrange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              stop.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
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
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: AppColors.routeBlue.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.routeBlue, size: 20),
      ),
    );
  }

  Widget _mapFab({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0288D1)
                : AppColors.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active
                  ? const Color(0xFF0288D1)
                  : AppColors.routeBlue.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : AppColors.routeBlue,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Painter: Punta triangular inferior del badge ──────────────────────────────
class _BadgePointerPainter extends CustomPainter {
  final Color color;
  const _BadgePointerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BadgePointerPainter old) => old.color != color;
}

// ── Diálogo de configuración de salida ────────────────────────────────────────
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
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.routeBlue),
          SizedBox(width: 10),
          Text(
            'Configurar salida',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¿Cuándo salió el autobús de la Base?',
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            value: true,
            groupValue: _useAuto,
            activeColor: AppColors.routeBlue,
            title: const Text(
              'Automático (cada 15 min desde 6:00)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            subtitle: const Text(
              'La app calcula la última salida',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
            onChanged: (v) => setState(() => _useAuto = v!),
          ),
          RadioListTile<bool>(
            value: false,
            groupValue: _useAuto,
            activeColor: AppColors.uatOrange,
            title: const Text(
              'Manual',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
            subtitle: Text(
              'Última salida: ${_selectedTime.format(context)}',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
            onChanged: (v) => setState(() => _useAuto = v!),
          ),
          if (!_useAuto)
            TextButton.icon(
              icon: const Icon(Icons.access_time_rounded,
                  color: AppColors.uatOrange),
              label: const Text(
                'Cambiar hora',
                style: TextStyle(color: AppColors.uatOrange),
              ),
              onPressed: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.uatOrange,
                        surface: AppColors.card,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (t != null) setState(() => _selectedTime = t);
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.routeBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.pop(
            context,
            _useAuto
                ? const _DepartureDialogResult(useAuto: true)
                : _DepartureDialogResult(
                    useAuto: false, time: _selectedTime),
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
