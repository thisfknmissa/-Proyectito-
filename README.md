# 🚌 Bus Tracker UAT Campus Sur

App Flutter para rastrear el autobús interno del Campus Sur de la Universidad Autónoma de Tamaulipas (Tampico) **sin necesidad de GPS físico ni conexión a internet/backend**, con **actualización continua en tiempo real (1s)**.

---

## 📥 Descargas de APK

Puedes descargar e instalar directamente el archivo APK en tu dispositivo Android:

| Versión | Archivo APK | Descripción |
|---|---|---|
| **v2.1.0 (Actual)** | [Bus_UAT_Campus_Sur_v2.0.0.apk](releases/Bus_UAT_Campus_Sur_v2.0.0.apk) | Trayectoria exacta con 30 waypoints, velocidad 5-25 km/h, tiempos de espera en paradas (Caseta 5-10 min, otros 2 min), Base de inicio/fin, mapa en tiempo real (1s) y OpenStreetMap sin API keys. |
| **v1.0.0 (Inicial)** | [Bus_UAT_Campus_Sur_v1.0.0.apk](releases/Bus_UAT_Campus_Sur_v1.0.0.apk) | Versión inicial con mapa estándar OSM y tema naranja. |

> 💡 El archivo [Bus_UAT_Campus_Sur.apk](Bus_UAT_Campus_Sur.apk) en la raíz siempre corresponde a la **versión más reciente compilada**.

---

## ✨ Características y Novedades en v2.1.0

- 🛣️ **Trayectoria exacta del campus**: La polilínea sigue fielmente cada calle y curva del circuito:
  - Salida desde la **Base** (`22.277880658336834, -97.86559585451916`).
  - Paso por FADYCS, FIT y Comida.
  - Bajada diagonal hacia **Caseta**.
  - Tramo poniente frente a Medicina y Odontología.
  - Quiebre sur por la calle de **Libros**, rodeo bajo el **GYM**.
  - Subida recta por la avenida central y giro hacia **FCAT** y **FADU**.
  - Retorno y finalización de jornada en la **Base**.
- ⏱️ **Tiempos de espera reales en paradas**:
  - **Caseta principal**: Espera de **5 a 10 minutos** (promedio 7.5 min).
  - **Paradas intermedias**: Espera de **~2 minutos**.
  - El autobús se detiene físicamente en la parada con estado visible y cronómetro en vivo de espera restante.
- ⚡ **Rango de velocidad calibrado**: Mínimo **5 km/h** y máximo **25 km/h** (promedio 15 km/h, con reducción en horas pico 7-8h y 13-15h).
- 🟢 **Actualización en Tiempo Real**: El mapa se actualiza de manera continua cada **1 segundo** sin saltos bruscos.
- 🗺️ **Calles y facultades 100% visibles**: OpenStreetMap nativo + selector de vista **Satélite (ESRI)** sin requerir claves de API.
- 🎨 **Interfaz moderna oscura & Marcadores Badge**: Iconos estilo escudo con nombres claros de cada facultad.

---

## 📍 Paradas de la Ruta (en orden de recorrido)

| # | Parada | Tiempo de Espera | Latitud | Longitud |
|---|---|---|---|---|
| 0 | **Base (Inicio/Fin)** | Salida de jornada | 22.277881 | -97.865596 |
| 1 | **FADYCS** | ~2 min | 22.278500 | -97.865550 |
| 2 | **FIT** | ~2 min | 22.278950 | -97.863500 |
| 3 | **Comida** | ~2 min | 22.278950 | -97.860000 |
| 4 | **Caseta** | **5 a 10 min** | 22.276370 | -97.857640 |
| 5 | **Libros** | ~2 min | 22.275200 | -97.859300 |
| 6 | **GYM** | ~2 min | 22.274900 | -97.860300 |
| 7 | **FCAT** | ~2 min | 22.275000 | -97.865500 |
| 8 | **FADU** | ~2 min | 22.276200 | -97.865550 |

---

## 🚀 Compilación desde código fuente

```powershell
# Clonar el repositorio
git clone https://github.com/thisfknmissa/-Proyectito-.git
cd -Proyectito-

# Descargar dependencias
flutter pub get

# Ejecutar tests
flutter test

# Compilar APK release
flutter build apk --release
```
