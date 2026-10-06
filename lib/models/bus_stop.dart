import 'package:latlong2/latlong.dart';

class BusStop {
  final String id;
  final String name;
  final String description;
  final LatLng position;
  final bool isTerminal;
  final String icon;

  const BusStop({
    required this.id,
    required this.name,
    required this.description,
    required this.position,
    required this.isTerminal,
    required this.icon,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      isTerminal: json['is_terminal'] as bool,
      icon: json['icon'] as String,
    );
  }
}
