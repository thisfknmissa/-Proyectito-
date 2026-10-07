# 🚌 Bus Tracker UAT Campus Sur

App Flutter para rastrear el autobús interno del Campus Sur de la Universidad Autónoma de Tamaulipas (Tampico) **sin necesidad de GPS físico ni conexión a internet/backend**, con **funcionamiento 100% offline**, **animación de carga fluida**, **mapas ESRI sin bloqueos** y **actualización continua en tiempo real (1s)**.

---

## 📥 Descargas de APK

Puedes descargar e instalar directamente el archivo APK en tu dispositivo Android:

| Versión | Archivo APK | Descripción |
|---|---|---|
| **v2.2.1 (Más reciente)** | [Bus_UAT_Campus_Sur_v2.2.1.apk](releases/Bus_UAT_Campus_Sur_v2.2.1.apk) | **Solución definitiva al bloqueo 403**: Migración completa de la vista normal a **ESRI World_Street_Map** (mosaicos limpios de alta resolución sin bloqueos ni marcas de agua). Mapa offline integrado (Zoom 13 a 18), ruta oficial de 85 waypoints, animación de carga y paradas calibradas. |
| **v2.2.0** | [Bus_UAT_Campus_Sur_v2.2.0.apk](releases/Bus_UAT_Campus_Sur_v2.2.0.apk) | Versión con ruta corregida y pantalla de carga animada. |
| **v2.0.0** | [Bus_UAT_Campus_Sur_v2.0.0.apk](releases/Bus_UAT_Campus_Sur_v2.0.0.apk) | Versión con tema azul y nuevo orden de paradas. |
| **v1.0.0** | [Bus_UAT_Campus_Sur_v1.0.0.apk](releases/Bus_UAT_Campus_Sur_v1.0.0.apk) | Versión inicial con mapa estándar OSM y tema naranja. |

> 💡 El archivo [Bus_UAT_Campus_Sur.apk](Bus_UAT_Campus_Sur.apk) en la raíz del repositorio siempre corresponde a la **versión más reciente compilada (v2.2.1)**.

---

## ✨ Novedades en v2.2.1

- 🗺️ **Solución al error 403 en Vista Normal**:
  - OpenStreetMap bloqueaba el acceso de aplicaciones móviles con una imagen de *"403 Access blocked"*.
  - Se sustituyó completamente el proveedor de la vista normal por **ESRI World_Street_Map** (la misma infraestructura CDN empresarial de alta disponibilidad que utiliza la vista satelital).
  - Todos los mosaicos empaquetados en el APK fueron reemplazados por mosaicos nítidos de ESRI, garantizando visualización limpia tanto online como offline.
- 📶 **100% OFFLINE (Zoom 13 a 18)**:
  - Se incluyeron **93 mosaicos de mapa de alta resolución** (ahora abarcando desde zoom 13 hasta zoom 18).
  - La app y las calles cargan de forma instantánea sin requerir señal celular ni datos.
- 🛣️ **Ruta Exacta al Mapa de Referencia (85 waypoints)**:
  - Salida y cierre de jornada en la **Base** (`22.277880, -97.865596`).
  - Circuito: Base ➔ FIT ➔ FADYCS ➔ FADU ➔ FCAT ➔ GYM ➔ Libros ➔ Caseta (5-10 min) ➔ Comida ➔ Base.
- 🎬 **Pantalla de Carga Animada (Splash Screen)**:
  - Radar concéntrico con pulso sonar, barra de progreso y mensajes de inicialización.
- ⏱️ **Tiempos de Espera y Velocidad Realista**:
  - Espera en **Caseta: 5 a 10 min**; paradas intermedias: **~2 min**.
  - Velocidad calibrada entre **5 y 25 km/h** con ajuste en horas pico.

---

## 📍 Paradas de la Ruta (Circuito Oficial Campus Sur)

| # | Parada | Tiempo de Espera | Latitud | Longitud |
|---|---|---|---|---|
| 0 | **Base (Salida/Fin)** | Salida de jornada | `22.277881` | `-97.865596` |
| 1 | **FIT** | ~2 min | `22.277021` | `-97.865473` |
| 2 | **FADYCS** | ~2 min | `22.275560` | `-97.865483` |
| 3 | **FADU** | ~2 min | `22.275011` | `-97.864104` |
| 4 | **FCAT** | ~2 min | `22.274985` | `-97.862748` |
| 5 | **GYM** | ~2 min | `22.275853` | `-97.859407` |
| 6 | **Libros (Frente a GYM)** | ~2 min | `22.276427` | `-97.859229` |
| 7 | **Caseta Principal** | **5 a 10 min** | `22.278889` | `-97.861007` |
| 8 | **Comida** | ~2 min | `22.278312` | `-97.865283` |

---

## 🚀 Compilación desde código fuente

```powershell
# Clonar el repositorio
git clone https://github.com/thisfknmissa/-Proyectito-.git
cd -Proyectito-

# Obtener dependencias
flutter pub get

# Ejecutar pruebas unitarias y de widgets
flutter test

# Compilar APK de producción
flutter build apk --release
```

El APK resultante se encontrará en `build/app/outputs/flutter-apk/app-release.apk`.
