import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bus_route.dart';
import '../models/bus_estimation.dart';
import '../services/route_service.dart';
import '../services/bus_estimator.dart';

/// Key constants for SharedPreferences
const _kManualDepartureKey = 'manual_departure_iso';
const _kUseManualKey = 'use_manual_departure';

class BusTrackerProvider extends ChangeNotifier {
  BusRoute? _route;
  BusEstimation? _estimation;
  List<StopEta> _stopEtas = [];
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _error;

  // Departure mode
  bool _useManualDeparture = false;
  DateTime? _manualDepartureTime;

  BusRoute? get route => _route;
  BusEstimation? get estimation => _estimation;
  List<StopEta> get stopEtas => _stopEtas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useManualDeparture => _useManualDeparture;
  DateTime? get manualDepartureTime => _manualDepartureTime;

  /// The departure time currently in use (manual or automatic)
  DateTime? get activeDepartureTime {
    if (_route == null) return null;
    if (_useManualDeparture && _manualDepartureTime != null) {
      return _manualDepartureTime;
    }
    return RouteService.latestDepartureTime(_route!, DateTime.now());
  }

  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _route = await RouteService.loadRoute();
      await _loadPreferences();
      _refresh();

      // Refresh every 15 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _refresh();
      });
    } catch (e) {
      _error = 'Error al cargar la ruta: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _refresh() {
    if (_route == null) return;
    final departure = activeDepartureTime;
    if (departure == null) {
      _estimation = null;
      _stopEtas = [];
      notifyListeners();
      return;
    }
    _estimation = BusPositionEstimator.estimate(
      route: _route!,
      departureTime: departure,
    );
    _stopEtas = BusPositionEstimator.computeAllEtas(
      route: _route!,
      departureTime: departure,
    );
    notifyListeners();
  }

  /// Force an immediate refresh (e.g., after changing settings)
  void refresh() => _refresh();

  /// Switch to automatic schedule mode
  void setAutoMode() async {
    _useManualDeparture = false;
    _manualDepartureTime = null;
    await _savePreferences();
    _refresh();
  }

  /// Set a manual departure time (user knows when the bus left)
  void setManualDeparture(DateTime departure) async {
    _useManualDeparture = true;
    _manualDepartureTime = departure;
    await _savePreferences();
    _refresh();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseManualKey, _useManualDeparture);
    if (_manualDepartureTime != null) {
      await prefs.setString(
          _kManualDepartureKey, _manualDepartureTime!.toIso8601String());
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _useManualDeparture = prefs.getBool(_kUseManualKey) ?? false;
    final savedStr = prefs.getString(_kManualDepartureKey);
    if (savedStr != null) {
      final saved = DateTime.tryParse(savedStr);
      // Only use today's saved departure if it was from today
      if (saved != null && _isSameDay(saved, DateTime.now())) {
        _manualDepartureTime = saved;
      } else {
        _useManualDeparture = false;
        _manualDepartureTime = null;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
