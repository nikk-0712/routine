# 🚀 Routine Assistant

A modern, offline-first personal productivity app built with Flutter. Manage tasks, track hydration, and gain insights into your daily habits.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

### 📋 Task Management
- Create, edit, and complete tasks
- **Subtasks & Checklists** for breaking down complex items
- Priority levels (Low, Medium, High, Urgent)
- Category organization (Personal, Study, Work, Health)
- Due date tracking with overdue indicators
- Delete confirmation safety
- Search and filtering (coming soon)

### ❤️ Health & Wellness
- **Hydration**: Track daily water intake (with quick-add)
- **Exercise**: Log workout type, duration, and intensity
- **Sleep**: Record sleep duration and quality
- **Progress Rings**: Visual daily goals for all metrics

### 📊 Insights & Analytics
- Weekly task completion bar chart
- Category distribution pie chart
- Dynamic productivity tips
- Real-time statistics

### ⚙️ Settings
- Customizable water goal
- Clear completed tasks
- Notification preferences
- App information

### 🏠 Smart Dashboard
- Today's focus preview
- Live task statistics
- Hydration quick-add widget
- Weekly streak tracking

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter 3.x** | Cross-platform UI framework |
| **Riverpod** | State management |
| **Drift (SQLite)** | Local database |
| **GoRouter** | Navigation |
| **FL Chart** | Data visualization |
| **SharedPreferences** | Settings persistence |

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+

### Installation

```bash
# Clone the repository
git clone https://github.com/nikk-0712/routine.git
cd routine

# Install dependencies
flutter pub get

# Generate database code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Platforms
- ✅ Windows
- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Linux
- ✅ Web

## 📁 Project Structure

```
lib/
├── core/
│   ├── database/          # Drift database & tables
│   ├── providers/         # Riverpod providers
│   ├── router/            # GoRouter configuration
│   ├── settings/          # SharedPreferences
│   └── theme/             # App theming
├── features/
│   ├── home/              # Dashboard screen
│   ├── tasks/             # Task management
│   ├── health/            # Hydration tracking
│   ├── insights/          # Analytics & charts
│   └── settings/          # App settings
└── main.dart
```

## 🎨 Design

- **Dark-first theme** with neon accents
- **Material 3** design system
- **Glassmorphism** elements
- **Responsive** layouts

## 📝 Roadmap

- [x] Task CRUD operations
- [x] Hydration tracking
- [x] Insights dashboard
- [x] Settings screen
- [x] Exercise tracking
- [x] Sleep tracking
- [x] Push notifications
- [ ] Supabase cloud sync
- [ ] Widget support

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

---

Built with ❤️ using Flutter
