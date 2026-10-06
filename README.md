# 🚌 Bus Tracker UAT Campus Sur

App Flutter para rastrear el autobús interno del Campus Sur de la Universidad Autónoma de Tamaulipas (Tampico) **sin necesidad de GPS físico ni conexión a internet/backend**.

---

## 📥 Descargas de APK

Puedes descargar e instalar directamente el archivo APK en tu dispositivo Android:

| Versión | Archivo APK | Descripción |
|---|---|---|
| **v2.0.0 (Actual)** | [Bus_UAT_Campus_Sur_v2.0.0.apk](releases/Bus_UAT_Campus_Sur_v2.0.0.apk) | Mapa delimitado, calles y facultades 100% visibles (OpenStreetMap & Satélite ESRI sin requerir claves de API), ruta perimetral precisa con waypoints, tema oscuro y nuevos iconos. |
| **v1.0.0 (Inicial)** | [Bus_UAT_Campus_Sur_v1.0.0.apk](releases/Bus_UAT_Campus_Sur_v1.0.0.apk) | Versión inicial con mapa estándar OSM y tema naranja. |

> 💡 El archivo [Bus_UAT_Campus_Sur.apk](Bus_UAT_Campus_Sur.apk) en la raíz siempre corresponde a la **versión más reciente**.

---

## ✨ Novedades en v2.0.0

- 🗺️ **Calles y facultades 100% visibles sin claves de API**: Se utiliza OpenStreetMap nativo (con nombres de todas las calles, facultades y edificios del campus) y vista alternativa satelital (ESRI World Imagery), eliminando cualquier error o marca de agua de API.
- 🛰️ **Selector de vista (Calles / Satélite)**: Botón flotante para alternar entre el mapa de calles y la vista fotográfica aérea de la universidad.
- 🔒 **Mapa delimitado al Campus Sur**: Bounding box optimizado (`22.2710, -97.8700` a `22.2840, -97.8550`) que impide desplazarse fuera de la zona universitaria.
- 🛣️ **Ruta perimetral con waypoints**: La línea de trayectoria ahora sigue los caminos reales del campus (trayectoria rectangular limpia) en lugar de trazos rectos entre paradas.
- 🎨 **Paleta de colores moderna & Tema oscuro**:
  - Fondo: Navy oscuro `#0D1B2A`
  - Línea de ruta: Azul eléctrico `#1E88E5` / `#42A5F5` con efecto glow
  - Paradas: Naranja institucional UAT `#E65100`
  - Tarjetas y superficies: Azul pizarra `#1A2942` / `#1E3350`
- 🏷️ **Marcadores tipo Escudo (Badge)**: Iconos estilizados en forma de escudo con indicador de punta triangular orientada al suelo.
- 🚌 **Marcador del autobús**: Círculo azul vibrante con halo de resplandor (glow) exterior.
- 📱 **Pantalla de Paradas con Timeline**: Vista tipo línea de tiempo con colores por estado (ya pasó, cerca, próxima).
- 🖼️ **Nuevo icono de la aplicación**: Icono de autobús con diseño moderno sobre fondo navy con siglas UAT.
- 🔍 **Botón "Ver campus completo"**: Centra y ajusta la cámara al perímetro total del campus.

---

## ⚙️ ¿Cómo funciona sin GPS físico?

La aplicación calcula la posición estimada del autobús en tiempo real mediante **interpolación geoespacial basada en tiempo transcurrido y velocidad promedio**:

$$\text{progreso} = \frac{\text{tiempo transcurrido}}{\text{tiempo estimado del segmento}}$$
$$\text{posición} = \text{parada}_A + \text{progreso} \times (\text{parada}_B - \text{parada}_A)$$

- **Velocidad promedio**: 25 km/h (rango 15–35 km/h)
- **Horas pico** (7:00–8:00 h y 13:00–15:00 h): La velocidad se ajusta automáticamente al 75% para reflejar mayor afluencia y tiempos de ascenso/descenso.
- **Margen de error dinámico**: Muestra en pantalla el margen de variación esperado ($\pm N\text{ min}$).
- **Frecuencia de salidas**: Cada 15 minutos de 6:00 a 21:00 h (modo automático o configurable manualmente).
- **Actualización**: Cada 15 segundos.

---

## 📍 Paradas de la Ruta

| # | Parada | Descripción | Latitud | Longitud |
|---|---|---|---|---|
| 1 | **GYM (Terminal)** | Gimnasio Campus Sur | 22.275853 | -97.859407 |
| 2 | **Libros** | Frente al Gimnasio | 22.276427 | -97.859229 |
| 3 | **Caseta** | Entrada / Caseta principal | 22.278889 | -97.861007 |
| 4 | **Comida** | Área gastronómica | 22.278312 | -97.865283 |
| 5 | **FIT** | Fac. de Ingeniería Tampico | 22.277021 | -97.865473 |
| 6 | **FADYCS** | Fac. de Derecho y Ciencias Sociales | 22.275560 | -97.865483 |
| 7 | **FADU** | Fac. de Arquitectura, Diseño y Urbanismo | 22.275011 | -97.864104 |
| 8 | **FCAT** | Fac. de Comercio, Administración y Cs. Aplicadas | 22.274985 | -97.862748 |

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

El APK compilado se genera en:
`build/app/outputs/flutter-apk/app-release.apk`
