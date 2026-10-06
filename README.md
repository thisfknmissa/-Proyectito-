# 🚌 Bus Tracker UAT Campus Sur

App Flutter para rastrear el autobús interno del Campus Sur de la UAT (Tampico) **sin GPS físico ni backend**.

## ¿Cómo funciona?

La app estima la posición del bus usando **interpolación geoespacial basada en tiempo y velocidad promedio**:

```
progreso = tiempo_transcurrido / tiempo_estimado_del_segmento
posición = parada_A + progreso × (parada_B - parada_A)
```

- Velocidad promedio: 25 km/h (ajustable en `assets/route.json`)
- Hora pico 7–8h y 13–15h: velocidad reducida al 75%
- Margen de error: ±N minutos mostrado en pantalla
- Frecuencia de salidas: cada 15 minutos, 6:00–21:00
- Auto-refresh: cada 15 segundos

## Paradas (en orden de ruta)

| # | Nombre | Lat | Lng |
|---|--------|-----|-----|
| 1 | GYM (Terminal) | 22.275853 | -97.859407 |
| 2 | Libros | 22.276427 | -97.859229 |
| 3 | Caseta | 22.278889 | -97.861007 |
| 4 | Comida | 22.278312 | -97.865283 |
| 5 | FIT | 22.277021 | -97.865473 |
| 6 | FADYCS | 22.275560 | -97.865483 |
| 7 | FADU | 22.275011 | -97.864104 |
| 8 | FCAT | 22.274985 | -97.862748 |

---

## 📦 Cómo compilar el APK

### Requisitos previos

1. **Instalar Flutter SDK** (si no lo tienes):
   - Descarga desde: https://docs.flutter.dev/get-started/install/windows/mobile
   - Extrae a `C:\src\flutter`
   - Agrega `C:\src\flutter\bin` al PATH del sistema
   - Reinicia la terminal

2. **Instalar Android Studio** (para el SDK de Android):
   - Descarga desde: https://developer.android.com/studio
   - Durante la instalación, instala el Android SDK (API 33 o superior)

3. **Verificar instalación**:
   ```powershell
   flutter doctor
   ```

### Compilar el APK

```powershell
# Navegar al proyecto
cd C:\Users\jmisa\.gemini\antigravity\scratch\bus_tracker_uat

# Instalar dependencias
flutter pub get

# Ejecutar tests
flutter test

# Compilar APK de debug (más rápido)
flutter build apk --debug

# Compilar APK de release (para instalar en celular)
flutter build apk --release
```

El APK estará en:
- Debug: `build\app\outputs\flutter-apk\app-debug.apk`
- Release: `build\app\outputs\flutter-apk\app-release.apk`

### Instalar en dispositivo Android

```powershell
# Con el celular conectado por USB (depuración USB activada)
flutter install

# O copia el APK al celular manualmente
```

---

## 📁 Estructura del proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── models/
│   ├── bus_stop.dart            # Modelo de parada
│   ├── bus_route.dart           # Modelo de ruta (con horas pico)
│   └── bus_estimation.dart      # Resultado de la estimación
├── services/
│   ├── route_service.dart       # Carga el JSON y calcula salidas
│   └── bus_estimator.dart       # Algoritmo de interpolación geoespacial
├── providers/
│   └── bus_tracker_provider.dart # State management + auto-refresh
└── screens/
    ├── home_screen.dart         # Mapa principal
    └── stops_screen.dart        # Lista de paradas con ETA
assets/
└── route.json                   # Datos de la ruta (editable)
```

---

## ✏️ Personalizar la ruta

Edita `assets/route.json` para cambiar:
- `average_speed_kmh`: velocidad promedio estimada
- `departure_interval_minutes`: cada cuántos minutos sale el bus
- `first_departure` / `last_departure`: horario de servicio
- `peak_hours`: franjas donde el bus va más lento
- `stops`: añadir/quitar paradas con coordenadas reales
