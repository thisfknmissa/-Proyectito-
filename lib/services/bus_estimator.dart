import 'package:latlong2/latlong.dart';
import '../models/bus_route.dart';
import '../models/bus_estimation.dart';

/// Core algorithm: estimates the bus position without GPS.
///
/// Strategy:
///  1. Know the departure time from the terminal (GYM stop).
///  2. Compute the travel time for each segment using the Haversine distance
///     and the route's effective speed (adjusted for peak hours).
///  3. Interpolate linearly along the segment where the bus currently is.
///
/// Error margin is derived from speed variability (15–35 km/h vs avg 25 km/h).
class BusPositionEstimator {
  static const Distance _distance = Distance();

  /// Haversine distance in kilometers between two LatLng points.
  static double _distanceKm(LatLng a, LatLng b) {
    return _distance(a, b) / 1000.0;
  }

  /// Estimated minutes to travel from [from] to [to] at [speedKmh].
  static double _segmentMinutes(LatLng from, LatLng to, double speedKmh) {
    final d = _distanceKm(from, to);
    return (d / speedKmh) * 60.0;
  }

  /// Linear interpolation between two LatLng points.
  static LatLng _interpolate(LatLng from, LatLng to, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * clampedT,
      from.longitude + (to.longitude - from.longitude) * clampedT,
    );
  }

  /// Computes the error margin in minutes based on speed variability.
  /// The real speed can be anywhere from minSpeed to maxSpeed.
  /// We compare the segment time at min speed vs max speed.
  static double _computeErrorMargin(
    LatLng from,
    LatLng to,
    double minSpeedKmh,
    double maxSpeedKmh,
  ) {
    final slow = _segmentMinutes(from, to, minSpeedKmh);
    final fast = _segmentMinutes(from, to, maxSpeedKmh);
    return (slow - fast) / 2.0; // half-range as ±margin
  }

  /// Main estimation method.
  ///
  /// [route]         - the full route definition
  /// [departureTime] - when the bus left the terminal (GYM)
  /// [now]           - current time (defaults to DateTime.now())
  static BusEstimation estimate({
    required BusRoute route,
    required DateTime departureTime,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (departureTime.isAfter(currentTime)) {
      // Bus hasn't departed yet
      return BusEstimation(
        position: route.stops.first.position,
        currentSegmentIndex: 0,
        nextStop: route.stops[1],
        minutesToNextStop: 0,
        hasCompleted: false,
        notYetDeparted: true,
        errorMarginMinutes: 0,
        statusMessage: 'El autobús aún no ha salido de ${route.stops.first.name}',
      );
    }

    // Elapsed time in minutes since departure
    final elapsedMinutes =
        currentTime.difference(departureTime).inSeconds / 60.0;

    double accumulatedMinutes = 0.0;

    for (int i = 0; i < route.stops.length - 1; i++) {
      final fromStop = route.stops[i];
      final toStop = route.stops[i + 1];

      final speed = route.effectiveSpeedKmh(currentTime);
      final segmentMinutes =
          _segmentMinutes(fromStop.position, toStop.position, speed);

      if (elapsedMinutes <= accumulatedMinutes + segmentMinutes) {
        // Bus is in this segment
        final progressInSegment =
            (elapsedMinutes - accumulatedMinutes) / segmentMinutes;
        final estimatedPos = _interpolate(
          fromStop.position,
          toStop.position,
          progressInSegment,
        );
        final remainingInSegment =
            segmentMinutes - (elapsedMinutes - accumulatedMinutes);

        // Compute ETA to all remaining stops
        final errorMargin = _computeErrorMargin(
          fromStop.position,
          toStop.position,
          route.minSpeedKmh,
          route.maxSpeedKmh,
        );

        return BusEstimation(
          position: estimatedPos,
          currentSegmentIndex: i,
          nextStop: toStop,
          minutesToNextStop: remainingInSegment.clamp(0.0, double.infinity),
          hasCompleted: false,
          notYetDeparted: false,
          errorMarginMinutes: errorMargin,
          statusMessage:
              'En camino a ${toStop.name}',
        );
      }

      accumulatedMinutes += segmentMinutes;
    }

    // Bus completed the route
    return BusEstimation(
      position: route.stops.last.position,
      currentSegmentIndex: route.stops.length - 2,
      nextStop: null,
      minutesToNextStop: 0,
      hasCompleted: true,
      notYetDeparted: false,
      errorMarginMinutes: 0,
      statusMessage: 'Ruta completada – regresa a ${route.stops.first.name}',
    );
  }

  /// Returns a list of (stop, eta_minutes) for all upcoming stops from now.
  /// Stops that have been passed show negative or zero ETA.
  static List<StopEta> computeAllEtas({
    required BusRoute route,
    required DateTime departureTime,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final elapsedMinutes =
        currentTime.difference(departureTime).inSeconds / 60.0;
    final speed = route.effectiveSpeedKmh(currentTime);

    double accumulatedMinutes = 0.0;
    final List<StopEta> etas = [];

    // First stop (terminal) - already passed
    etas.add(StopEta(
      stop: route.stops.first,
      etaMinutes: -elapsedMinutes,
      hasPassed: elapsedMinutes > 0,
    ));

    for (int i = 0; i < route.stops.length - 1; i++) {
      final segmentMinutes = _segmentMinutes(
        route.stops[i].position,
        route.stops[i + 1].position,
        speed,
      );
      accumulatedMinutes += segmentMinutes;

      final etaMinutes = accumulatedMinutes - elapsedMinutes;
      etas.add(StopEta(
        stop: route.stops[i + 1],
        etaMinutes: etaMinutes,
        hasPassed: etaMinutes < 0,
      ));
    }

    return etas;
  }
}

class StopEta {
  final dynamic stop; // BusStop
  final double etaMinutes;
  final bool hasPassed;

  const StopEta({
    required this.stop,
    required this.etaMinutes,
    required this.hasPassed,
  });
}
