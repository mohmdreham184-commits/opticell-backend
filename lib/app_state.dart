import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);
final ValueNotifier<bool> notificationsEnabledNotifier = ValueNotifier<bool>(
  true,
);
final ValueNotifier<bool> autoRefreshNotifier = ValueNotifier<bool>(false);
final ValueNotifier<int> refreshIntervalNotifier = ValueNotifier<int>(5);

/// Get the default API endpoint based on platform
/// Android emulator must use 10.0.2.2 to reach the host machine
String _getDefaultEndpoint() {
  if (kIsWeb) {
    // Web runs in browser, use localhost
    return 'http://localhost:3000/api/reports';
  }

  // Android emulator must use 10.0.2.2 to reach host machine
  if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/reports';

  // Desktop and iOS simulator use localhost
  return 'http://localhost:3000/api/reports';
}

final ValueNotifier<String> apiEndpointNotifier = ValueNotifier<String>(
  _getDefaultEndpoint(),
);

String getApiEndpoint() {
  final endpoint = apiEndpointNotifier.value.trim();
  return endpoint.isNotEmpty ? endpoint : _getDefaultEndpoint();
}

Future<void> loadSavedSettings() async {
  final prefs = await SharedPreferences.getInstance();
  themeModeNotifier.value = prefs.getBool('darkMode') == true
      ? ThemeMode.dark
      : ThemeMode.light;
  notificationsEnabledNotifier.value = prefs.getBool('notifications') ?? true;
  autoRefreshNotifier.value = prefs.getBool('autoRefresh') ?? false;
  refreshIntervalNotifier.value = prefs.getInt('refreshInterval') ?? 5;
  final savedEndpoint = prefs.getString('apiEndpoint')?.trim();
  final defaultEndpoint = _getDefaultEndpoint();
  apiEndpointNotifier.value =
      (savedEndpoint != null && savedEndpoint.isNotEmpty)
      ? savedEndpoint
      : defaultEndpoint;
}

Future<void> saveSetting(String key, dynamic value) async {
  final prefs = await SharedPreferences.getInstance();
  if (value is bool) await prefs.setBool(key, value);
  if (value is int) await prefs.setInt(key, value);
  if (value is String) await prefs.setString(key, value);
}
