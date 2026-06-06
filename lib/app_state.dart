import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// =====================
/// THEME + SETTINGS STATE
/// =====================

final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.light);

final ValueNotifier<bool> notificationsEnabledNotifier =
    ValueNotifier(true);

final ValueNotifier<bool> autoRefreshNotifier =
    ValueNotifier(false);

final ValueNotifier<int> refreshIntervalNotifier =
    ValueNotifier(5);

/// =====================
/// API ENDPOINT (FIXED - NO OVERRIDE)
/// =====================

String getApiEndpoint() {
  return 'https://opticell-backend-production.up.railway.app/api/reports';
}

/// (اختياري فقط للـ UI لو محتاج notifier)
final ValueNotifier<String> apiEndpointNotifier =
    ValueNotifier(getApiEndpoint());

/// =====================
/// LOAD SETTINGS
/// =====================

Future<void> loadSavedSettings() async {
  final prefs = await SharedPreferences.getInstance();

  themeModeNotifier.value =
      prefs.getBool('darkMode') == true
          ? ThemeMode.dark
          : ThemeMode.light;

  notificationsEnabledNotifier.value =
      prefs.getBool('notifications') ?? true;

  autoRefreshNotifier.value =
      prefs.getBool('autoRefresh') ?? false;

  refreshIntervalNotifier.value =
      prefs.getInt('refreshInterval') ?? 5;

  // ❌ تم حذف apiEndpoint تمامًا
}

/// =====================
/// SAVE SETTINGS
/// =====================

Future<void> saveSetting(String key, dynamic value) async {
  final prefs = await SharedPreferences.getInstance();

  if (value is bool) await prefs.setBool(key, value);
  if (value is int) await prefs.setInt(key, value);
  if (value is String) await prefs.setString(key, value);
}