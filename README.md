# Tabsla — Tesla-style tablet car dashboard

**3D viewer (web):** https://hwkim3330.github.io/tabsla/ · **Drive view:** https://hwkim3330.github.io/tabsla/drive.html

A Flutter app that turns an Android tablet into a Tesla-style in-car display. It uses the tablet's own sensors, GPS and cameras, plus free web services, so it runs without a car connection.

## Features (widgets in `lib/widgets/`)

- **Map & navigation** — `flutter_map` + OpenStreetMap, routing through the public OSRM server.
- **3D vehicle viewer** — GLB car models (`model_viewer_plus`, `flutter_3d_controller`, and the WebView pages in `docs/`).
- **Speedometer, power meter, energy graph, trip info, battery gauge.**
- **Sensor HUD** — accelerometer/gyro (`sensors_plus`), device temperature, noise level (`noise_meter`).
- **Camera surround view and dashcam** (`camera`).
- **Weather** from Open-Meteo; climate, vehicle controls, media player, sketchpad, mini game, settings.

## Run

```bash
flutter pub get
flutter run            # Android tablet recommended (camera, GPS, sensors)
```

`docs/` holds the static 3D viewer pages and GLB models published on GitHub Pages.

**Tech:** Flutter / Dart, flutter_map, geolocator, sensors_plus, camera, webview_flutter, model-viewer, Three.js.

**Status:** personal prototype.
