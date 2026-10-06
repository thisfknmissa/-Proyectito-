import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:bus_tracker_uat/models/bus_stop.dart';
import 'package:bus_tracker_uat/models/bus_route.dart';
import 'package:bus_tracker_uat/services/bus_estimator.dart';

// Minimal test route using real UAT coordinates
BusRoute _buildTestRoute() {
  final stops = [
    BusStop(
      id: 'gym',
      name: 'GYM',
      description: 'Terminal',
      position: const LatLng(22.275853028486324, -97.85940668629185),
      isTerminal: true,
      icon: 'gym',
    ),
    BusStop(
      id: 'libros',
      name: 'Libros',
      description: 'Frente al GYM',
      position: const LatLng(22.276426514209717, -97.85922936740606),
      isTerminal: false,
      icon: 'books',
    ),
    BusStop(
      id: 'caseta',
      name: 'Caseta',
      description: 'Cerca de la caseta',
      position: const LatLng(22.278889352203937, -97.86100667958786),
      isTerminal: false,
      icon: 'booth',
    ),
    BusStop(
      id: 'comida',
      name: 'Comida',
      description: 'Área de comida',
      position: const LatLng(22.278311838890346, -97.86528318714124),
      isTerminal: false,
      icon: 'food',
    ),
    BusStop(
      id: 'fit',
      name: 'FIT',
      description: 'Facultad de Ingeniería',
      position: const LatLng(22.277020718164042, -97.86547252196516),
      isTerminal: false,
      icon: 'fit',
    ),
    BusStop(
      id: 'fadycs',
      name: 'FADYCS',
      description: 'Fac. de Derecho',
      position: const LatLng(22.275559712981224, -97.86548278289342),
      isTerminal: false,
      icon: 'fadycs',
    ),
    BusStop(
      id: 'fadu',
      name: 'FADU',
      description: 'Fac. de Arquitectura',
      position: const LatLng(22.275010733293268, -97.86410361180192),
      isTerminal: false,
      icon: 'fadu',
    ),
    BusStop(
      id: 'fcat',
      name: 'FCAT',
      description: 'Fac. de Comercio',
      position: const LatLng(22.2749850134443, -97.86274795233082),
      isTerminal: false,
      icon: 'fcat',
    ),
  ];

  return BusRoute(
    routeName: 'Test Route',
    routeShort: 'Test',
    color: '#E65100',
    averageSpeedKmh: 25.0,
    minSpeedKmh: 15.0,
    maxSpeedKmh: 35.0,
    departureIntervalMinutes: 15,
    firstDepartureHour: 6,
    firstDepartureMinute: 0,
    lastDepartureHour: 21,
    lastDepartureMinute: 0,
    stops: stops,
    peakHours: [],
  );
}

void main() {
  final route = _buildTestRoute();
  final now = DateTime(2024, 1, 15, 10, 0, 0); // 10:00 AM test time

  group('BusPositionEstimator', () {
    test('returns notYetDeparted when departure is in the future', () {
      final futureDeparture = now.add(const Duration(minutes: 5));
      final result = BusPositionEstimator.estimate(
        route: route,
        departureTime: futureDeparture,
        now: now,
      );
      expect(result.notYetDeparted, isTrue);
      expect(result.position, equals(route.stops.first.position));
    });

    test('returns first segment position just after departure', () {
      // Bus departed 5 seconds ago - should be between GYM and Libros
      final recentDeparture = now.subtract(const Duration(seconds: 5));
      final result = BusPositionEstimator.estimate(
        route: route,
        departureTime: recentDeparture,
        now: now,
      );
      expect(result.notYetDeparted, isFalse);
      expect(result.hasCompleted, isFalse);
      expect(result.currentSegmentIndex, equals(0));
      expect(result.nextStop?.id, equals('libros'));
    });

    test('bus completes route when enough time has elapsed', () {
      // Route is ~2km, at 25km/h takes ~4.8 min. After 30 min it must be done.
      final oldDeparture = now.subtract(const Duration(minutes: 30));
      final result = BusPositionEstimator.estimate(
        route: route,
        departureTime: oldDeparture,
        now: now,
      );
      expect(result.hasCompleted, isTrue);
    });

    test('ETAs list has same length as stops', () {
      final departure = now.subtract(const Duration(minutes: 2));
      final etas = BusPositionEstimator.computeAllEtas(
        route: route,
        departureTime: departure,
        now: now,
      );
      expect(etas.length, equals(route.stops.length));
    });

    test('first stop ETA is always negative (terminal already passed)', () {
      final departure = now.subtract(const Duration(minutes: 2));
      final etas = BusPositionEstimator.computeAllEtas(
        route: route,
        departureTime: departure,
        now: now,
      );
      expect(etas.first.etaMinutes, lessThan(0));
      expect(etas.first.hasPassed, isTrue);
    });

    test('estimated position is within the route bounding box', () {
      final departure = now.subtract(const Duration(minutes: 3));
      final result = BusPositionEstimator.estimate(
        route: route,
        departureTime: departure,
        now: now,
      );
      final lat = result.position.latitude;
      final lng = result.position.longitude;

      // Bounding box of the campus
      expect(lat, greaterThan(22.274));
      expect(lat, lessThan(22.280));
      expect(lng, greaterThan(-97.867));
      expect(lng, lessThan(-97.858));
    });

    test('error margin is positive when bus is in a segment', () {
      final departure = now.subtract(const Duration(minutes: 2));
      final result = BusPositionEstimator.estimate(
        route: route,
        departureTime: departure,
        now: now,
      );
      expect(result.errorMarginMinutes, greaterThan(0));
    });
  });
}
