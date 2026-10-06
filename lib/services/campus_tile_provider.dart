import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Proveedor de mosaicos de mapa optimizado para el Campus Sur UAT.
/// Carga automáticamente los mosaicos empaquetados en la APK (assets/tiles/)
/// permitiendo funcionamiento 100% offline sin consumir datos ni depender de conexión.
/// Si se navega fuera del área del campus, realiza fallback a OpenStreetMap.
class CampusOfflineTileProvider extends TileProvider {
  CampusOfflineTileProvider({super.headers});

  /// Verifica si el mosaico en las coordenadas dadas está disponible localmente en assets.
  /// Contiene cobertura completa del campus en niveles de zoom 14, 15, 16, 17 y 18.
  static bool hasOfflineAsset(int z, int x, int y) {
    switch (z) {
      case 14:
        return (x == 3737 || x == 3738) && y == 7151;
      case 15:
        return (x >= 7475 && x <= 7476) && (y >= 14302 && y <= 14303);
      case 16:
        return (x >= 14951 && x <= 14953) && (y >= 28605 && y <= 28607);
      case 17:
        return (x >= 29903 && x <= 29907) && (y >= 57211 && y <= 57214);
      case 18:
        return (x >= 59807 && x <= 59814) && (y >= 114422 && y <= 114428);
      default:
        return false;
    }
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z.toInt();
    final x = coordinates.x.toInt();
    final y = coordinates.y.toInt();

    if (hasOfflineAsset(z, x, y)) {
      // Carga inmediata desde los archivos locales de la app (Sin Internet)
      return AssetImage('assets/tiles/${z}_${x}_${y}.png');
    }

    // Respaldo en línea para áreas externas al campus
    return NetworkImage(
      'https://tile.openstreetmap.org/$z/$x/$y.png',
      headers: {
        'User-Agent': 'com.uat.bus_tracker_uat (OfflineCampusTileProvider/2.2.0)',
      },
    );
  }
}
