import 'package:latlong2/latlong.dart';
import '../models/bus_stop.dart';
import '../models/bus_route.dart';
import '../models/bus_estimation.dart';

/// Algoritmo central de estimación en tiempo real sin GPS.
///
/// Características:
///  1. Salida y llegada a la Base (22.277880658336834, -97.86559585451916).
///  2. Velocidad mínima de 5 km/h y máxima de 25 km/h (promedio 15 km/h).
///  3. Tiempos de parada: ~2 min en paradas regulares, y 5 a 10 min en Caseta.
///  4. Trayectoria precisa sobre los 30 waypoints exactos de la ruta.
///  5. Actualización continua segundo a segundo para seguimiento en tiempo real.
class BusPositionEstimator {
  static const Distance _distance = Distance();

  /// Distancia Haversine en kilómetros entre dos puntos.
  static double _distanceKm(LatLng a, LatLng b) {
    return _distance(a, b) / 1000.0;
  }

  /// Distancia total en km a lo largo de una lista de waypoints.
  static double _polylineDistanceKm(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      sum += _distanceKm(points[i], points[i + 1]);
    }
    return sum;
  }

  /// Minutos estimados de viaje a lo largo de [points] a [speedKmh].
  static double _travelMinutes(List<LatLng> points, double speedKmh) {
    final d = _polylineDistanceKm(points);
    return (d / (speedKmh <= 0 ? 15.0 : speedKmh)) * 60.0;
  }

  /// Encuentra el subconjunto de waypoints entre dos paradas consecutivas.
  static List<LatLng> _extractSubPolyline(
    LatLng from,
    LatLng to,
    List<LatLng> allWaypoints,
  ) {
    if (allWaypoints.isEmpty) return [from, to];

    int fromIdx = _closestWaypointIndex(from, allWaypoints);
    int toIdx = _closestWaypointIndex(to, allWaypoints);

    if (fromIdx == toIdx) return [from, to];

    final List<LatLng> result = [from];
    if (fromIdx < toIdx) {
      for (int i = fromIdx + 1; i < toIdx; i++) {
        result.add(allWaypoints[i]);
      }
    } else {
      // Si la ruta da la vuelta al inicio del arreglo
      for (int i = fromIdx + 1; i < allWaypoints.length; i++) {
        result.add(allWaypoints[i]);
      }
      for (int i = 0; i < toIdx; i++) {
        result.add(allWaypoints[i]);
      }
    }
    result.add(to);
    return result;
  }

  static int _closestWaypointIndex(LatLng target, List<LatLng> waypoints) {
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < waypoints.length; i++) {
      final d = _distanceKm(target, waypoints[i]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  /// Interpola a lo largo de una polilínea dado una fracción de distancia [progress] (0.0 a 1.0).
  static LatLng _interpolateAlongPolyline(List<LatLng> points, double progress) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1 || progress <= 0.0) return points.first;
    if (progress >= 1.0) return points.last;

    final totalDist = _polylineDistanceKm(points);
    final targetDist = totalDist * progress;

    double accumulated = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      final segDist = _distanceKm(points[i], points[i + 1]);
      if (accumulated + segDist >= targetDist && segDist > 0) {
        final t = (targetDist - accumulated) / segDist;
        return LatLng(
          points[i].latitude + (points[i + 1].latitude - points[i].latitude) * t,
          points[i].longitude + (points[i + 1].longitude - points[i].longitude) * t,
        );
      }
      accumulated += segDist;
    }
    return points.last;
  }

  /// Método principal de estimación con soporte de paradas y waypoints.
  static BusEstimation estimate({
    required BusRoute route,
    required DateTime departureTime,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (departureTime.isAfter(currentTime)) {
      // Aún no ha salido de la Base
      return BusEstimation(
        position: route.basePosition,
        currentSegmentIndex: 0,
        nextStop: route.stops.isNotEmpty ? route.stops.first : null,
        minutesToNextStop: 0,
        hasCompleted: false,
        notYetDeparted: true,
        errorMarginMinutes: 0,
        currentSpeedKmh: 0.0,
        statusMessage: 'En Base · Esperando próxima salida',
      );
    }

    final elapsedSeconds =
        currentTime.difference(departureTime).inSeconds;
    final elapsedMinutes = elapsedSeconds / 60.0;
    final effectiveSpeed = route.effectiveSpeedKmh(currentTime);

    // Lista de paradas cerrada que termina de vuelta en la base
    final List<BusStop> stopsSequence = [...route.stops];
    if (route.stops.isNotEmpty &&
        route.stops.last.position != route.basePosition) {
      stopsSequence.add(BusStop(
        id: 'base_fin',
        name: 'Base',
        description: 'Fin de recorrido',
        position: route.basePosition,
        isTerminal: true,
        icon: 'place',
        dwellMinutes: 0.0,
      ));
    }

    double accumulatedMinutes = 0.0;

    for (int i = 0; i < stopsSequence.length - 1; i++) {
      final fromStop = stopsSequence[i];
      final toStop = stopsSequence[i + 1];

      final subPolyline = _extractSubPolyline(
        fromStop.position,
        toStop.position,
        route.waypoints,
      );

      final drivingMinutes = _travelMinutes(subPolyline, effectiveSpeed);
      final dwellMinutes = toStop.dwellMinutes;

      // Fase 1: El autobús está en movimiento hacia toStop
      if (elapsedMinutes < accumulatedMinutes + drivingMinutes) {
        final progressInSegment =
            ((elapsedMinutes - accumulatedMinutes) / drivingMinutes)
                .clamp(0.0, 1.0);
        final currentPos =
            _interpolateAlongPolyline(subPolyline, progressInSegment);
        final remainingDriveMin =
            (accumulatedMinutes + drivingMinutes) - elapsedMinutes;

        // Margen de error considerando rango de 5 a 25 km/h
        final slowDrive = _travelMinutes(subPolyline, route.minSpeedKmh);
        final fastDrive = _travelMinutes(subPolyline, route.maxSpeedKmh);
        final margin = ((slowDrive - fastDrive) / 2.0).clamp(0.5, 6.0);

        final remSeconds = (remainingDriveMin * 60).round();
        final remText = remSeconds < 60
            ? '$remSeconds seg'
            : '${remainingDriveMin.ceil()} min';

        return BusEstimation(
          position: currentPos,
          currentSegmentIndex: i,
          nextStop: toStop,
          currentDwellStop: null,
          minutesToNextStop: remainingDriveMin,
          isStoppedAtStop: false,
          stoppedRemainingSeconds: 0,
          currentSpeedKmh: effectiveSpeed,
          hasCompleted: false,
          notYetDeparted: false,
          errorMarginMinutes: margin,
          statusMessage: 'En camino a ${toStop.name} (~$remText · ${effectiveSpeed.round()} km/h)',
        );
      }

      accumulatedMinutes += drivingMinutes;

      // Fase 2: El autobús está detenido en toStop esperando ascenso/descenso
      if (dwellMinutes > 0.0 &&
          elapsedMinutes < accumulatedMinutes + dwellMinutes) {
        final remainingDwellSec =
            (((accumulatedMinutes + dwellMinutes) - elapsedMinutes) * 60)
                .round()
                .clamp(0, 3600);

        final mins = remainingDwellSec ~/ 60;
        final secs = remainingDwellSec % 60;
        final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

        final isCaseta = toStop.id == 'caseta';
        final detailMsg = isCaseta
            ? 'Detenido en Caseta (Espera 5-10 min · Quedan $timeStr)'
            : 'Detenido en ${toStop.name} (Espera ~2 min · Quedan $timeStr)';

        return BusEstimation(
          position: toStop.position,
          currentSegmentIndex: i,
          nextStop: (i + 2 < stopsSequence.length)
              ? stopsSequence[i + 2]
              : null,
          currentDwellStop: toStop,
          minutesToNextStop: 0.0,
          isStoppedAtStop: true,
          stoppedRemainingSeconds: remainingDwellSec,
          currentSpeedKmh: 0.0,
          hasCompleted: false,
          notYetDeparted: false,
          errorMarginMinutes: 1.0,
          statusMessage: detailMsg,
        );
      }

      accumulatedMinutes += dwellMinutes;
    }

    // Ruta completada: en base
    return BusEstimation(
      position: route.basePosition,
      currentSegmentIndex: stopsSequence.length - 1,
      nextStop: null,
      currentDwellStop: null,
      minutesToNextStop: 0,
      isStoppedAtStop: true,
      stoppedRemainingSeconds: 0,
      currentSpeedKmh: 0.0,
      hasCompleted: true,
      notYetDeparted: false,
      errorMarginMinutes: 0,
      statusMessage: 'Recorrido completado · En Base UAT',
    );
  }

  /// Calcula las estimaciones de llegada a cada parada incluyendo tiempos de espera.
  static List<StopEta> computeAllEtas({
    required BusRoute route,
    required DateTime departureTime,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final elapsedMinutes =
        currentTime.difference(departureTime).inSeconds / 60.0;
    final effectiveSpeed = route.effectiveSpeedKmh(currentTime);

    double accumulatedMinutes = 0.0;
    final List<StopEta> etas = [];

    final stopsSequence = route.stops;

    for (int i = 0; i < stopsSequence.length; i++) {
      if (i == 0) {
        // Primera parada (salida de Base)
        etas.add(StopEta(
          stop: stopsSequence[0],
          etaMinutes: -elapsedMinutes,
          hasPassed: elapsedMinutes > 0,
        ));
        continue;
      }

      final prevStop = stopsSequence[i - 1];
      final currStop = stopsSequence[i];

      final subPolyline = _extractSubPolyline(
        prevStop.position,
        currStop.position,
        route.waypoints,
      );

      final drivingMinutes = _travelMinutes(subPolyline, effectiveSpeed);
      accumulatedMinutes += drivingMinutes;

      final etaMinutes = accumulatedMinutes - elapsedMinutes;
      etas.add(StopEta(
        stop: currStop,
        etaMinutes: etaMinutes,
        hasPassed: etaMinutes < 0,
      ));

      // Agregar el tiempo de espera de esta parada para el cálculo de las siguientes
      accumulatedMinutes += currStop.dwellMinutes;
    }

    return etas;
  }
}

class StopEta {
  final BusStop stop;
  final double etaMinutes;
  final bool hasPassed;

  const StopEta({
    required this.stop,
    required this.etaMinutes,
    required this.hasPassed,
  });
}
