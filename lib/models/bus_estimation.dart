import 'package:latlong2/latlong.dart';
import 'bus_stop.dart';

/// Result of the bus position estimation algorithm
class BusEstimation {
  /// Estimated geographic position of the bus
  final LatLng position;

  /// Index of the segment (between stops[i] and stops[i+1])
  final int currentSegmentIndex;

  /// Next stop the bus will reach (null if completed)
  final BusStop? nextStop;

  /// Estimated minutes until the next stop
  final double minutesToNextStop;

  /// True when the bus has finished the full route cycle
  final bool hasCompleted;

  /// True when the bus hasn't departed yet (before first departure of the day)
  final bool notYetDeparted;

  /// Approximate margin of error in minutes (due to speed variability)
  final double errorMarginMinutes;

  /// Human-readable status message
  final String statusMessage;

  const BusEstimation({
    required this.position,
    required this.currentSegmentIndex,
    required this.nextStop,
    required this.minutesToNextStop,
    required this.hasCompleted,
    required this.notYetDeparted,
    required this.errorMarginMinutes,
    required this.statusMessage,
  });
}
