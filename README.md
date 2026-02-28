# Project Plan 🕐

> Visual clock-based time blocking + long-term consistency tracking app.
> Built with Flutter + Firebase.

---

## Prerequisites

| Tool | Version | Link |
|---|---|---|
| Flutter SDK | ≥ 3.19 | [Install Guide](https://docs.flutter.dev/get-started/install/windows/mobile) |
| Dart SDK | ≥ 3.3 | Bundled with Flutter |
| Android Studio | Latest | For emulator/device |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| FlutterFire CLI | Latest | `dart pub global activate flutterfire_cli` |

---

## Quick Start

### 1. Install Flutter & Run Setup Script

```powershell
# After installing Flutter and adding to PATH:
cd d:\Project_02\project_plan
.\setup.ps1
```

### 2. Configure Firebase

```bash
# Login to Firebase
firebase login

# Configure FlutterFire (generates firebase_options.dart)
flutterfire configure
```

Then manually:
- Copy `google-services.json` → `android/app/`
- Copy `GoogleService-Info.plist` → `ios/Runner/`

### 3. Run the App

```bash
flutter run
```

---

## Project Structure

```
lib/
├── core/
│   ├── theme/           # Color tokens, typography, ThemeData
│   ├── router/          # Go Router configuration (12 screens)
│   └── firebase/        # Firebase initialization
├── features/
│   ├── auth/            # Google Sign-In, profile screen
│   ├── quote/           # Daily motivational quote splash
│   ├── tasks/           # Task CRUD, daily list view
│   ├── clock/           # CustomPainter clock face (Sprint 3)
│   ├── checklist/       # Things to Remember
│   ├── calendar/        # Monthly calendar + streak (Sprint 5)
│   └── feedback/        # In-app feedback form (Sprint 5)
├── data/
│   ├── models/          # Task, User, Checklist Firestore models
│   ├── repositories/    # Firestore + Hive repositories
│   └── providers/       # Riverpod data layer providers
└── main.dart
```

---

## Sprint Status

| Sprint | Feature Area | Status |
|---|---|---|
| 0 | Project Setup + Design System | ✅ Complete |
| 1 | Auth + Daily Quote | ✅ Complete |
| 2 | Task CRUD + Checklist | 🔲 Pending |
| 3 | Clock Interface | 🔲 Pending |
| 4 | Task Lifecycle + Notifications | 🔲 Pending |
| 5 | Calendar + History + Polish | 🔲 Pending |

---

## Tech Stack

- **Framework:** Flutter (Dart)
- **State:** Riverpod 2
- **Navigation:** Go Router
- **Backend:** Firebase (Auth, Firestore, FCM, Analytics, Crashlytics)
- **Local Cache:** Hive
- **Notifications:** `flutter_local_notifications` + FCM
