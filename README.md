# Project Plan 🕐

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

> **Visual clock-based time blocking + long-term consistency tracking app.**
> Elevate your productivity with a meticulous daily schedule visualized on a custom-designed interactive clock face.

---

## ✨ Key Features

- 🕒 **Interactive Clock Interface:** Drag and drop tasks directly onto a 24-hour clock face for intuitive scheduling.
- 🔐 **Secure Authentication:** Seamless Google Sign-In and profile management.
- ✅ **Dynamic Task Management:** Full CRUD operations for tasks with real-time Firestore synchronization.
- 📜 **Daily Motivational Quotes:** Start your day inspired with curated quotes on a beautiful splash screen.
- 📅 **Consistency Calendar:** Track your streaks and habits over months with an integrated calendar view.
- 📊 **Deep Insights:** Visualize your productivity trends and task completion history.
- 🔔 **Smart Notifications:** (In Progress) Timely reminders to keep you on track throughout the day.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | [Flutter](https://flutter.dev) (Dart) |
| **State Management** | [Riverpod 2](https://riverpod.dev) |
| **Navigation** | [Go Router](https://pub.dev/packages/go_router) |
| **Backend** | [Firebase](https://firebase.google.com/) (Auth, Firestore, FCM, Analytics, Remote Config) |
| **Local Storage** | [Hive](https://pub.dev/packages/hive) |
| **Styling** | Custom Design System (OLED Dark Mode optimized) |

---

## 🚀 Quick Start

### 1. Prerequisites

Ensure you have the following installed:
- **Flutter SDK** ≥ 3.19
- **Firebase CLI** (`npm install -g firebase-tools`)
- **FlutterFire CLI** (`dart pub global activate flutterfire_cli`)

### 2. Initialization

```powershell
# Clone the repository and navigate to the project
cd project_plan

# Run the automated setup script
.\setup.ps1
```

### 3. Firebase Configuration

```bash
# Login to your Firebase account
firebase login

# Configure FlutterFire (this generates lib/firebase_options.dart)
flutterfire configure
```

### 4. Run the App

```bash
flutter run
```

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── theme/           # Color tokens, typography, custom themes
│   ├── router/          # Comprehensive Go Router configuration
│   └── services/        # Firebase, Notifications, and Core business logic
├── features/
│   ├── auth/            # OAuth flows and user profile
│   ├── home/            # The main interactive clock dashboard
│   ├── tasks/           # Task creation, editing, and list management
│   ├── calendar/        # Monthly habit and streak tracking
│   ├── insights/        # Productivity analytics and history
│   ├── checklist/       # "Things to Remember" utility
│   ├── notes/           # Quick note-taking feature
│   ├── search/          # Global task and history search
│   ├── settings/        # App preferences and user configuration
│   └── quote/           # Daily inspiration engine
├── data/
│   ├── models/          # Strongly typed Firestore entities
│   ├── repositories/    # Data access layer (Firestore + Hive)
│   └── providers/       # Riverpod state providers
└── main.dart            # Application entry point
```

---

## 📈 Roadmap & Sprint Status

| Sprint | Feature Area | Status |
|:---:|---|:---:|
| **0** | Project Foundation & Design System | ✅ |
| **1** | Authentication & Daily Motivation | ✅ |
| **2** | Core Task Management (CRUD) | ✅ |
| **3** | Interactive Clock Interface | ✅ |
| **4** | Task Lifecycle & Push Notifications | 🟡 |
| **5** | Analytics, History & Polish | ✅ |

---

## 🤝 Contributing

We welcome contributions! Please feel free to submit Pull Requests or open issues for bugs and feature requests.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
