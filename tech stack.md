# Ultra-Low-Cost Tech Stack Design Document

## Project

Adaptive AI Personal Assistant App (Prototype / Early MVP)

## Objective

Design and operate a fully functional prototype of the Adaptive AI Personal Assistant app using a **free or near-zero cost tech stack**, while preserving all core features, UX quality, offline-first behavior, and AI-driven adaptability.

The goal is to **minimize monthly operational cost (₹0–₹300)** without compromising the product vision.

---

## 1. Core Strategy

The system follows a **device-first, server-light architecture**:

* Maximum logic runs on the client (Flutter)
* Cloud is used only for sync, auth, and backup
* AI intelligence is rule-based and on-device
* Free-tier, open-source, or serverless tools are preferred

This ensures:

* Very low operating cost
* Fast iteration
* Strong offline support
* Reduced infrastructure complexity

---

## 2. Frontend / Client Stack

### UI Framework

* **Flutter** (single codebase)

  * Android
  * iOS
  * Windows
  * macOS

**Why Flutter**

* Free and open source
* High-performance UI and animations
* Ideal for futuristic, dashboard-heavy design
* Excellent offline support

**Cost:** ₹0

---

### State Management & UI

* State management: Riverpod or Bloc
* Routing: GoRouter
* Charts: FL Chart / Syncfusion (free tier)
* Animations: Flutter native + Lottie

**Cost:** ₹0

---

### Offline Storage (Client)

* SQLite (via Drift or Isar)
* Hive for key-value cache

Used for:

* Tasks
* Health logs
* Streaks
* Screen time data
* Offline queue for sync

**Cost:** ₹0

---

## 3. Backend (Free / Serverless)

### Primary Backend Option (Recommended)

**Supabase (Free Tier)**
Provides:

* PostgreSQL database
* Authentication (email, Google, Apple)
* Row Level Security
* File storage
* Realtime sync

Replaces:

* Backend server
* Auth service
* Database server
* Storage service

**Cost:** ₹0

---

### Alternative Backend Option

**Firebase (Free Tier)**

* Firestore database
* Firebase Auth
* Firebase Storage
* Cloud Functions (limited)

**Cost:** ₹0

---

## 4. API & Business Logic Placement

### On-Device (Flutter)

* Task scheduling
* Habit detection
* Reminder timing logic
* Streak tracking
* Free-time detection
* Screen time analysis

### Cloud Functions (Free Tier)

* Weekly/monthly reports
* Cross-device sync
* Backup jobs
* Conflict resolution

**Cost:** ₹0

---

## 5. AI / Intelligence Layer

### AI Strategy

**Phase 1 (Prototype)**

* Rule-based logic
* Heuristic models
* Pattern counters
* Time-series comparisons

Examples:

* Miss hydration reminders → increase reminder frequency
* Skip workouts on weekends → suggest weekday alternatives
* Finish tasks early → suggest productive activities

### Optional Lightweight ML

* TensorFlow Lite (on-device)
* Simple clustering and trend detection

**Cost:** ₹0

---

## 6. Nutrition Tracking (Low-Cost Path)

### Phase 1 (Free)

* Manual food logging
* Open Food Facts API for nutrition data

### Phase 2 (Later)

* On-device food image recognition

**Cost:** ₹0

---

## 7. Notifications & Reminders

* Firebase Cloud Messaging (Android)
* Apple Push Notification Service (iOS/macOS)
* Interactive actions (Yes / No / Snooze)

**Cost:** ₹0

---

## 8. Screen Time & App Blocking

### Android

* UsageStats API
* Accessibility Services

### iOS

* Screen Time API
* Family Controls framework

**Cost:** ₹0

---

## 9. Wearable Integration

* Apple HealthKit
* Google Fit
* Fitbit API (free tier)

Used for:

* Steps
* Sleep
* Activity metrics

**Cost:** ₹0

---

## 10. Analytics & Monitoring

* Firebase Analytics
* Sentry (free tier)
* Custom in-app logging

**Cost:** ₹0

---

## 11. Domain & Miscellaneous

* Domain name: ₹80–₹120 / month
* SSL: Free (Let’s Encrypt)

---

## 12. Monthly Cost Summary

### Ultra-Lean Prototype

* Backend & DB: ₹0
* AI: ₹0
* Notifications: ₹0
* Storage: ₹0
* Analytics: ₹0
* Domain: ~₹100

**Total Monthly Cost:** ~₹100

---

### Safe Buffer Budget

Even with minor overruns:

**₹200–₹300 per month**

---

## 13. Trade-offs (Transparent)

Delayed features:

* Heavy cloud-based AI inference
* Advanced food image recognition
* Large-scale analytics

Preserved features:

* Full task management
* Health & wellness tracking
* Smart reminders
* Offline-first behavior
* Cross-platform support
* Strong UX and performance

---

## 14. Migration Path (Future)

When user base grows:

* Move Supabase → AWS / GCP
* Add dedicated AI services
* Introduce paid plans

No rewrite required.

---

## 15. Final Recommendation

This stack allows you to:

* Build confidently on a tight budget
* Validate the idea with real users
* Avoid infrastructure stress
* Scale only when needed

**This is the most cost-effective and founder-friendly setup for your project.**
