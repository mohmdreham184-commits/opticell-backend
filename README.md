# Opticell

Opticell is a real-time industrial monitoring and predictive maintenance system built using Flutter, Firebase, and Server-Sent Events (SSE). It enables engineers to monitor machine batches in real time, detect anomalies, and receive instant alerts for critical conditions.

## Project Overview

This application simulates an industrial monitoring platform that tracks sensor data such as temperature and pressure. It provides real-time insights, alerts, and reporting tools to help prevent system failures.

## Features

- Real-time monitoring using SSE live streams
- Smart alert system for normal, warning, and critical conditions
- Push notifications for critical events
- Auto refresh and reconnect logic
- Firebase Authentication and Firestore integration
- Export batch reports to CSV
- Offline fallback support

## How to run

1. Install Flutter and required tools
2. Run `flutter pub get`
3. Run `flutter run`

## Notes

This repository includes the Flutter app, platform folders, and CI workflow configuration. Generated build artifacts and dependency caches are ignored by `.gitignore`.
