# 🚌 Bus Tracker UAT Campus Sur

App Flutter para rastrear el autobús interno del Campus Sur de la Universidad Autónoma de Tamaulipas (Tampico) **sin necesidad de GPS físico ni conexión a internet/backend**, con **funcionamiento 100% offline**, **animación de carga fluida** y **actualización continua en tiempo real (1s)**.

---

## 📥 Descargas de APK

Puedes descargar e instalar directamente el archivo APK en tu dispositivo Android:

| Versión | Archivo APK | Descripción |
|---|---|---|
| **v2.2.0 (Más reciente)** | [Bus_UAT_Campus_Sur_v2.2.0.apk](releases/Bus_UAT_Campus_Sur_v2.2.0.apk) | **Ruta oficial exacta** con 85 waypoints, **mapa 100% offline integrado** (Zoom 14-18), **pantalla de carga animada** con radar y barra de progreso, velocidad calibrada 5-25 km/h, tiempos de parada (Caseta 5-10 min, otros 2 min) y Base de salida/llegada. |
| **v2.0.0** | [Bus_UAT_Campus_Sur_v2.0.0.apk](releases/Bus_UAT_Campus_Sur_v2.0.0.apk) | Versión con tema azul y nuevo orden de paradas. |
| **v1.0.0** | [Bus_UAT_Campus_Sur_v1.0.0.apk](releases/Bus_UAT_Campus_Sur_v1.0.0.apk) | Versión inicial con mapa estándar OSM y tema naranja. |

> 💡 El archivo [Bus_UAT_Campus_Sur.apk](Bus_UAT_Campus_Sur.apk) en la raíz del repositorio siempre corresponde a la **versión más reciente compilada (v2.2.0)**.

---

## ✨ Novedades en v2.2.0

- 🛣️ **Ruta Exacta al Mapa de Referencia**:
  - Trazado vectorial de **85 waypoints** que replica fielmente el circuito físico del campus:
    - **Salida de la Base** (`22.277880, -97.865596`).
    - Descenso por calle poniente pasando por **FIT** y **FADYCS**.
    - Giro al oriente por calle sur hacia **FADU** y **FCAT**.
    - Quiebre al norte y oriente por avenida central hacia el **GYM** y **Libros**.
    - Subida recta por la avenida oriente hacia la **Caseta**.
    - Retorno por **Calle Universidad de Veracruz** pasando por el área de **Comida** y cerrando el ciclo en la **Base**.
- 📶 **100% OFFLINE (Sin Conexión ni Datos)**:
  - Se incluyeron **91 mosaicos de mapa de alta resolución** (Zoom 14 a 18) empaquetados directamente dentro de la aplicación.
  - La app y el mapa abren y funcionan de manera instantánea en modo avión, sótanos o aulas sin señal celular.
- 🎬 **Pantalla de Carga Animada (Splash Screen)**:
  - Al abrir la app se despliega una pantalla de bienvenida con identidad UAT, anillos concéntricos de radar/sonar emanando del autobús, barra de progreso dinámica y mensajes de estado que transicionan suavemente hacia el mapa.
- ⏱️ **Tiempos de Espera Calibrados**:
  - **Caseta principal**: Espera programada de **5 a 10 minutos** (promedio 7.5 min).
  - **Paradas regulares**: Espera de **~2 minutos**.
  - Visualización en vivo del tiempo restante detenido en cada estación.
- ⚡ **Velocidad Variable (5 a 25 km/h)**:
  - Velocidad promedio de 15 km/h con ajuste en horas pico (07:00–08:00 y 13:00–15:00).
- 🟢 **Seguimiento en Vivo cada 1 Segundo**:
  - Interpolación continua a lo largo de las curvas y calles sin saltos bruscos.

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
