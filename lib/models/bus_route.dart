import 'bus_stop.dart';

class PeakHour {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final double speedFactor;

  const PeakHour({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.speedFactor,
  });

  factory PeakHour.fromJson(Map<String, dynamic> json) {
    final startParts = (json['start'] as String).split(':');
    final endParts = (json['end'] as String).split(':');
    return PeakHour(
      startHour: int.parse(startParts[0]),
      startMinute: int.parse(startParts[1]),
      endHour: int.parse(endParts[0]),
      endMinute: int.parse(endParts[1]),
      speedFactor: (json['speed_factor'] as num).toDouble(),
    );
  }

  bool isActive(DateTime time) {
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;
    final currentTotal = time.hour * 60 + time.minute;
    return currentTotal >= startTotal && currentTotal <= endTotal;
  }
}

class BusRoute {
  final String routeName;
  final String routeShort;
  final String color;
  final double averageSpeedKmh;
  final double minSpeedKmh;
  final double maxSpeedKmh;
  final int departureIntervalMinutes;
  final int firstDepartureHour;
  final int firstDepartureMinute;
  final int lastDepartureHour;
  final int lastDepartureMinute;
  final List<BusStop> stops;
  final List<PeakHour> peakHours;

  const BusRoute({
    required this.routeName,
    required this.routeShort,
    required this.color,
    required this.averageSpeedKmh,
    required this.minSpeedKmh,
    required this.maxSpeedKmh,
    required this.departureIntervalMinutes,
    required this.firstDepartureHour,
    required this.firstDepartureMinute,
    required this.lastDepartureHour,
    required this.lastDepartureMinute,
    required this.stops,
    required this.peakHours,
  });

  factory BusRoute.fromJson(Map<String, dynamic> json) {
    final firstParts = (json['first_departure'] as String).split(':');
    final lastParts = (json['last_departure'] as String).split(':');

    return BusRoute(
      routeName: json['route_name'] as String,
      routeShort: json['route_short'] as String,
      color: json['color'] as String,
      averageSpeedKmh: (json['average_speed_kmh'] as num).toDouble(),
      minSpeedKmh: (json['min_speed_kmh'] as num).toDouble(),
      maxSpeedKmh: (json['max_speed_kmh'] as num).toDouble(),
      departureIntervalMinutes: json['departure_interval_minutes'] as int,
      firstDepartureHour: int.parse(firstParts[0]),
      firstDepartureMinute: int.parse(firstParts[1]),
      lastDepartureHour: int.parse(lastParts[0]),
      lastDepartureMinute: int.parse(lastParts[1]),
      stops: (json['stops'] as List<dynamic>)
          .map((s) => BusStop.fromJson(s as Map<String, dynamic>))
          .toList(),
      peakHours: (json['peak_hours'] as List<dynamic>)
          .map((p) => PeakHour.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  double effectiveSpeedKmh(DateTime at) {
    for (final peak in peakHours) {
      if (peak.isActive(at)) {
        return averageSpeedKmh * peak.speedFactor;
      }
    }
    return averageSpeedKmh;
  }
}
