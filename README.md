# Vayu — Personal Air Health Intelligence System

> *Real-time air quality monitoring, personalized exposure tracking, and AI-powered health coaching — built with Flutter.*

---

## What is Vayu?

Vayu is a cross-platform Flutter application (iOS & Android) that goes beyond simple AQI readings. It tracks your **personal pollution exposure** based on where you are, how long you've been there, and your health profile — then uses AI to help you breathe better.

### Core Features

- **Real-time AQI Dashboard** — Live air quality from 12,000+ monitoring stations worldwide via the WAQI API, with a Google Air Quality fallback
- **Personal Exposure Tracking** — Calculates your actual exposure score accounting for your environment (indoor/outdoor/transit) and health sensitivity
- **Low-Pollution Route Planning** — Compares multiple routes and recommends the one with the least pollution exposure, not just the fastest
- **Netra Vision (Camera Detection)** — On-device ML detects smoke, haze, and traffic congestion through your camera using TensorFlow Lite models
- **AI Coach** — Generates personalized recovery plans when your daily exposure crosses unhealthy thresholds, powered by Vertex AI (Gemini)
- **96-Hour AQI Forecast** — Hourly predictions with confidence intervals so you can plan outdoor activities in advance
- **What-If Simulator** — Model how behavior changes (different commute time, travel mode, mask usage) would affect your daily exposure

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.19+, Dart 3.3+ |
| **State Management** | Riverpod 2.x with code generation |
| **Navigation** | go_router |
| **Maps** | Google Maps Flutter, flutter_map |
| **Location** | flutter_background_geolocation, geolocator |
| **ML / Vision** | TensorFlow Lite (tflite_flutter), on-device inference via Dart Isolates |
| **Local Storage** | Hive (cache), Drift/SQLite (exposure history), SharedPreferences |
| **Backend** | Firebase (Auth, Firestore, Cloud Functions v2, FCM, Remote Config, Storage, Crashlytics) |
| **AQI Data** | WAQI API (primary), Google Air Quality API (secondary + heatmap tiles) |
| **Routing** | Google Routes API |
| **AI / Forecasting** | Vertex AI (Gemini 2.0 Flash for coaching, time-series model for forecasts) |

---

## Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── domain/
│   ├── models/          # Pure Dart models (AqiReading, ExposureEntry, ScoredRoute, ...)
│   ├── engines/         # Business logic (ExposureEngine, NavigationEngine, NetraVisionEngine, ...)
│   └── interfaces/      # Repository interfaces (IAqiRepository, ILocationRepository, ...)
├── data/
│   ├── repositories/    # Concrete implementations (WAQI, Google AQ, Firestore, Hive, ...)
│   ├── datasources/
│   │   ├── remote/      # HTTP clients (WAQI, Google AQ, Google Routes, Firebase Functions)
│   │   └── local/       # Hive, Drift, SharedPreferences
│   └── dto/             # API response models
├── providers/           # Riverpod providers (aqi/, location/, exposure/, navigation/, vision/, coach/)
├── ml/
│   ├── inference_engine.dart       # Isolate-based TFLite interpreter pool
│   ├── image_preprocessor.dart
│   ├── detection_postprocessor.dart
│   ├── model_registry.dart
│   └── camera_frame_pipeline.dart
└── presentation/
    ├── screens/         # Dashboard, Map/Routes, Netra Vision, Insights, Simulation, Profile
    └── widgets/         # Shared UI components

assets/
├── models/              # TFLite model files (.tflite)
│   ├── smoke_detector_v3.tflite
│   ├── haze_density_v2.tflite
│   ├── traffic_congestion_v1.tflite
│   └── labels/
├── images/
└── animations/

firebase/                # Firebase Cloud Functions (Node.js)
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.19 or higher
- Dart SDK 3.3 or higher
- Android Studio or Xcode (for device deployment)
- A Firebase project with the following services enabled:
  - Authentication (Email, Google, Apple)
  - Firestore
  - Cloud Functions
  - Cloud Messaging
  - Remote Config
  - Cloud Storage
  - Crashlytics
- API keys for:
  - [WAQI API](https://aqicn.org/api/) (free)
  - [Google Maps Platform](https://developers.google.com/maps) (Maps SDK, Routes API, Air Quality API, Geocoding API)
  - Google Vertex AI (for forecasting and AI coach)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/harshchhabraa/Vayu.git
   cd Vayu
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Place your `google-services.json` in `android/app/`
   - Place your `GoogleService-Info.plist` in `ios/Runner/`
   - The `firebase_options.dart` file is already generated — update it if you use a different Firebase project

4. **Set up API keys**

   Create a `.env` file or configure your keys via the project's secrets management. The app uses envified to keep keys out of source control. At minimum, set:
   ```
   WAQI_API_TOKEN=your_waqi_token
   GOOGLE_MAPS_API_KEY=your_google_maps_key
   GOOGLE_AQ_API_KEY=your_google_aq_key
   ```

5. **Run code generation** (for Riverpod, Freezed, Drift, Retrofit)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests

```bash
flutter test
```

---

## Deployment

### Web (via Render)

The app includes a `Dockerfile` and `render.yaml` for deploying the Flutter web build to [Render](https://render.com).

```bash
# Build locally to verify
flutter build web --release
```

Render will automatically run `flutter build web --release` inside the Docker container and serve the output via nginx. See `Dockerfile` and `render.yaml` at the project root.

### Android & iOS

Follow the standard Flutter deployment guides:
- [Android — Build and release](https://docs.flutter.dev/deployment/android)
- [iOS — Build and release](https://docs.flutter.dev/deployment/ios)

---

## Exposure Calculation

Vayu calculates your personal exposure using:

```
Exposure = AQI × duration_hours × environment_factor × health_sensitivity
```

| Environment | Factor |
|---|---|
| Outdoor | 1.0 |
| Transit | 0.6 |
| Vehicle (windows closed) | 0.5 |
| Indoor | 0.3 |

| Health Profile | Sensitivity |
|---|---|
| Healthy adult | 1.0 |
| Child (< 12) | 1.4 |
| Elderly (> 65) | 1.3 |
| Asthma / COPD | 1.6 |
| Pregnant | 1.5 |
| Cardiovascular disease | 1.4 |

Daily cumulative scores are categorized as Good → Moderate → Unhealthy → Very Unhealthy → Hazardous, with the AI Coach activating at the Unhealthy tier.

---

## ML Models

All inference is fully on-device — no camera frames ever leave the device.

| Model | Task | Size | Input | Inference Time |
|---|---|---|---|---|
| `smoke_detector_v3.tflite` | Smoke / emission detection (YOLOv8-nano, INT8) | ~6MB | 640×640 | ~18ms |
| `haze_density_v2.tflite` | Haze density regression (custom CNN) | ~2MB | 224×224 | ~8ms |
| `traffic_congestion_v1.tflite` | Traffic congestion classification | ~6MB | 640×640 | ~18ms |

Models are updated over-the-air via Firebase Remote Config + Cloud Storage without requiring an app update.

---

## Privacy

- **Camera frames** are processed entirely in-memory and never stored or transmitted
- **Location data** is stored at full precision on-device; cloud sync uses reduced precision (~1.1km)
- **Health conditions** are stored locally only; only a numeric sensitivity factor is synced to the cloud
- **Crowd-sourced vision events** are stored with no user-identifiable data
- Full account deletion cascades across all user data within 30 days

---

## Architecture Overview

The app follows a clean layered architecture:

```
Presentation (Flutter UI)
    ↓
State (Riverpod Providers)
    ↓
Domain (Engines + Interfaces — zero Flutter/Firebase imports)
    ↓
Data (Repository implementations + local/remote datasources)
    ↓
Backend (Firebase + GCP Cloud Functions + Vertex AI)
```

For full architecture documentation including data flow diagrams, scaling plan, failure handling, and security model, see `implementation_plan.md`.

---

## License

Private — all rights reserved.
