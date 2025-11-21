# AI-Fitness-Coach

![Project Banner](./assets/readme-banner.png)

**AI-Fitness-Coach** is a cross-platform Flutter app that provides personalized workout plans, progress tracking, and rep-counting using on-device computer vision. The project focuses on an intuitive dashboard, editable weekly plans, and exercise screens that use the camera to count reps and track form.

---

## Table of Contents

* [Features](#features)
* [Demo / Screenshots](#demo--screenshots)
* [Tech Stack](#tech-stack)
* [Requirements](#requirements)
* [Getting started (development)](#getting-started-development)
* [Build & Release (APK)](#build--release-apk)
* [Project structure](#project-structure)
* [How to use](#how-to-use)
* [Troubleshooting & Tips](#troubleshooting--tips)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)

---

## Features

* Personalized weekly workout plans (editable from the Dashboard)
* Progress tracking and visual progress indicators
* Camera-based rep counting and basic form analysis
* Dark/light theme support and theme color options
* Local persistence (SQLite / Shared Preferences) for offline use
* Export / import plan (JSON)

> ⚠️ Some UI features like theme color picker and progress syncing may be implemented in separate branches or need wiring between screens. Refer to the `TODO` section in code for pointers.

---

## Demo / Screenshots

Add screenshots here (e.g. `assets/screenshots/dashboard.png`) or link to a short demo GIF.

---

## Tech Stack

* **Framework:** Flutter
* **Language:** Dart
* **Machine Vision:** tflite / MediaPipe / custom PoseNet (where applicable)
* **Storage:** sqflite / shared_preferences / local JSON
* **State Management:** Provider / Riverpod / setState (adjust to what the repo uses)

---

## Requirements

* Flutter SDK (stable channel, >= 3.x)
* Android SDK / Xcode (for iOS)
* A physical device or emulator with camera support (for rep-counting)
* Java JDK 11+ (for Android builds)

---

## Getting started (development)

1. **Clone the repo**

```bash
git clone https://github.com/omkarkendreok/AI-Fitness-Coach.git
cd AI-Fitness-Coach
```

2. **Install Flutter packages**

```bash
flutter pub get
```

3. **Run on an emulator or device**

```bash
flutter run
```

4. **Common useful commands**

* Analyze project for issues:

```bash
flutter analyze
```

* Format code:

```bash
flutter format .
```

---

## Build & Release (APK)

To build a release APK for Android:

```bash
# For debug
flutter build apk --debug

# For release
flutter build apk --release
```

The generated APK will be found at `build/app/outputs/flutter-apk/app-release.apk` (or `app-debug.apk` for debug builds).

If you use flavors or custom build types, consult your `android/app/build.gradle`.

---

## Project structure (high level)

```
├─ android/
├─ ios/
├─ lib/
│  ├─ main.dart
│  ├─ screens/
│  │  ├─ dashboard_screen.dart
│  │  ├─ exercise_screen.dart
│  │  └─ ...
│  ├─ utils/
│  │  ├─ rep_counter.dart
│  │  └─ ...
│  ├─ models/
│  └─ widgets/
├─ assets/
└─ pubspec.yaml
```

> Note: Replace the above if your tree differs. The repository already contains `exercise_screen.dart` and `rep_counter.dart` — use those to trace where the camera and rep logic live.

---

## How to use

* Open the Dashboard to view weekly plan and progress.
* Edit weekly plan directly from the dashboard (UI edits will persist locally).
* Start an exercise to open the camera-based rep counter. Ensure camera permissions are allowed.

---

## Troubleshooting & Tips

* **Push rejected (non-fast-forward)**: If `git push` fails with `non-fast-forward`, pull the remote changes and merge first:

```bash
git pull --rebase origin main
# fix merge conflicts if any
git push origin main
```

* **Missing packages / imports**: Run `flutter pub get` and restart your IDE.
* **Camera permission errors**: Confirm AndroidManifest.xml (and Info.plist for iOS) contain camera permission entries and request runtime permissions on the device.
* **RepCounter constructor mismatch**: If you see errors like `No named parameter with the name 'exercise'`, open `lib/utils/rep_counter.dart` and check the constructor signature — update either the class constructor or the calling site in `exercise_screen.dart` so parameters match.

---

## TODO / Known issues

* Dashboard: color theme option not wired to theme provider.
* Progress indicator: migration to a single source-of-truth state (e.g., use Provider or Riverpod) recommended.
* Weekly plan edit: confirm model and persistence code path (where updates are saved).

If you'd like, I can create small focused patches for these (for example: wire theme option, fix RepCounter constructor mismatch, or add progress-sync logic). Tell me which one to start with and I will prepare a patch snippet.

---

## Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/awesome-feature`
3. Commit changes and push
4. Open a Pull Request explaining the change

Please follow the existing code style and run `flutter analyze` before submitting a PR.

---

## License

This project is provided under the MIT License — change to the license you prefer.

---

## Contact

Maintainer: **omkarkendreok** (see GitHub profile)

If you want specific changes to the README (shorter, more technical, or focused on building), tell me which sections to expand or remove.
