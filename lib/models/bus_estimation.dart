import 'package:latlong2/latlong.dart';
import 'bus_stop.dart';

/// Result of the bus position estimation algorithm
class BusEstimation {
  /// Estimated geographic position of the bus
  final LatLng position;

  /// Index of the current segment or stop
  final int currentSegmentIndex;

  /// Next stop the bus will reach (null if completed)
  final BusStop? nextStop;

  /// Current stop if dwelling/stopped, null otherwise
  final BusStop? currentDwellStop;

  /// Estimated minutes until reaching the next stop
  final double minutesToNextStop;

  /// True when the bus is paused at a stop (dwell time)
  final bool isStoppedAtStop;

  /// Remaining seconds waiting at the current stop (if isStoppedAtStop is true)
  final int stoppedRemainingSeconds;

  /// Current estimated speed in km/h (0 if stopped)
  final double currentSpeedKmh;

  /// True when the bus has finished the full route cycle
  final bool hasCompleted;

  /// True when the bus hasn't departed yet (before shift or next cycle)
  final bool notYetDeparted;

  /// Approximate margin of error in minutes
  final double errorMarginMinutes;

  /// Human-readable status message
  final String statusMessage;

  const BusEstimation({
    required this.position,
    required this.currentSegmentIndex,
    required this.nextStop,
    this.currentDwellStop,
    required this.minutesToNextStop,
    this.isStoppedAtStop = false,
    this.stoppedRemainingSeconds = 0,
    this.currentSpeedKmh = 15.0,
    required this.hasCompleted,
    required this.notYetDeparted,
    required this.errorMarginMinutes,
    required this.statusMessage,
  });
}
