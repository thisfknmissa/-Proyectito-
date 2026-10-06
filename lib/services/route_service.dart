import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bus_route.dart';

class RouteService {
  static BusRoute? _cachedRoute;

  /// Loads and parses the route from the bundled JSON asset.
  static Future<BusRoute> loadRoute() async {
    if (_cachedRoute != null) return _cachedRoute!;
    final String jsonStr = await rootBundle.loadString('assets/route.json');
    final Map<String, dynamic> jsonMap =
        jsonDecode(jsonStr) as Map<String, dynamic>;
    _cachedRoute = BusRoute.fromJson(jsonMap);
    return _cachedRoute!;
  }

  /// Returns the most recent departure time before [now].
  /// Returns null if the bus hasn't started service yet today.
  static DateTime? latestDepartureTime(BusRoute route, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final firstDep = today.add(Duration(
      hours: route.firstDepartureHour,
      minutes: route.firstDepartureMinute,
    ));
    final lastDep = today.add(Duration(
      hours: route.lastDepartureHour,
      minutes: route.lastDepartureMinute,
    ));

    if (now.isBefore(firstDep)) return null;

    DateTime departure = firstDep;
    DateTime? latest;

    while (!departure.isAfter(lastDep)) {
      if (!departure.isAfter(now)) {
        latest = departure;
      }
      departure =
          departure.add(Duration(minutes: route.departureIntervalMinutes));
    }

    return latest;
  }

  /// Returns the next upcoming departure after [now], or null if service ended.
  static DateTime? nextDepartureTime(BusRoute route, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final firstDep = today.add(Duration(
      hours: route.firstDepartureHour,
      minutes: route.firstDepartureMinute,
    ));
    final lastDep = today.add(Duration(
      hours: route.lastDepartureHour,
      minutes: route.lastDepartureMinute,
    ));

    DateTime departure = firstDep;
    while (!departure.isAfter(lastDep)) {
      if (departure.isAfter(now)) return departure;
      departure =
          departure.add(Duration(minutes: route.departureIntervalMinutes));
    }
    return null;
  }
}
