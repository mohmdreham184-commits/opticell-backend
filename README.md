# 🏭 Opticell

Opticell is a real-time industrial monitoring and predictive maintenance system built using Flutter, Firebase, and Server-Sent Events (SSE). It enables engineers to monitor machine batches in real time, detect anomalies, and receive instant alerts for critical conditions.

---

# 🚀 Project Overview

Opticell simulates an industrial monitoring platform that tracks machine sensor data such as temperature and pressure. It provides real-time insights and alerts to help prevent system failures before they occur.

The system uses a **hybrid architecture** combining REST APIs, Firebase Firestore, and Server-Sent Events (SSE) with local fallback data for reliability.

---

# ✨ Features

- 📊 Real-time monitoring using SSE live streams  
- ⚠️ Smart alert system (Normal / Warning / Critical detection)  
- 🔔 Push notifications for critical events  
- 🔄 Auto refresh system with configurable intervals  
- 🔐 Firebase Authentication (login/logout system)  
- ⚙️ User settings (theme, notifications, API endpoint control)  
- 📤 Export batch reports to CSV  
- 💾 Offline fallback with dummy data support  

---

# 🧠 System Architecture

[ External Data Sources ]
   ├── REST API (Primary)
   ├── Firebase Firestore (Fallback)
   └── SSE Real-time Stream
                ↓
          ApiService Layer
                ↓
        BatchReport Model Layer
                ↓
           RootScreen Controller
                ↓
        UI Screens (Dashboard / Reports / Settings / Help)
                ↓
        Notification System (Local + SSE Alerts)

---

# ⚡ Real-time Engine (SSE)

- Live streaming of batch reports
- Automatic reconnection on failure
- Exponential backoff retry strategy
- Stream-based parsing of incoming data
- Real-time UI updates without manual refresh

---

# 🧩 State Management

- ValueNotifier for reactive UI updates  
- SharedPreferences for persistent settings  
- Firebase listeners for authentication state  

---

# 🔔 Notification System

- 📱 Local notifications (Flutter Local Notifications)
- ⚡ SSE real-time alerts
- 🔴 Critical condition detection
- 🚫 Duplicate notification prevention system

---

# 🛠 Tech Stack

- Flutter (Frontend)
- Firebase Authentication
- Cloud Firestore
- HTTP REST APIs
- Server-Sent Events (SSE)
- SharedPreferences
- Flutter Local Notifications

---

# 📱 Application Modules

- 🏠 Dashboard → Live monitoring overview  
- 📊 Reports → Batch history and analytics  
- ⚙️ Settings → App configuration and controls  
- ❓ Help → User guidance section  
- 🔐 Login → Authentication system  

---

# 🔁 Data Flow

Sensors / APIs / Firebase / SSE
        ↓
     ApiService
        ↓
   Data Processing Layer
        ↓
   RootScreen Controller
        ↓
   UI + Notification Engine

---

# 🧪 CI/CD Pipeline

GitHub Actions workflow runs on every push/PR:

- flutter pub get  
- flutter analyze  
- flutter test  
- test coverage report generation  

Ensures code quality and stability.

---

# 🎯 Project Goal

The goal of Opticell is to simulate a real-world industrial monitoring system capable of:

- Detecting machine anomalies in real time  
- Sending instant alerts to engineers  
- Providing live operational dashboards  
- Ensuring system reliability with fallback systems  

---

# 🏆 Highlights

- 🔥 Real-time SSE streaming system  
- 🧠 Hybrid backend architecture  
- ⚙️ Dynamic configuration system  
- 📊 Industrial monitoring simulation  
- 📱 Production-ready Flutter structure  
- 🔔 Smart notification engine with deduplication  

---

# 👨‍💻 Author

Final Year Computer Science Project – Opticell 🚀

---

# 📌 Note

This project is developed for educational purposes to demonstrate real-time system design, mobile architecture, and hybrid backend integration using Flutter and Firebase.
