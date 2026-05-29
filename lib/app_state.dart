import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);
final ValueNotifier<bool> notificationsEnabledNotifier = ValueNotifier<bool>(
  true,
);
final ValueNotifier<bool> autoRefreshNotifier = ValueNotifier<bool>(false);
final ValueNotifier<int> refreshIntervalNotifier = ValueNotifier<int>(5);
final ValueNotifier<String> apiEndpointNotifier = ValueNotifier<String>(
  'http://localhost:3000/api/reports',
);

Future<void> loadSavedSettings() async {
  final prefs = await SharedPreferences.getInstance();
  themeModeNotifier.value = prefs.getBool('darkMode') == true
      ? ThemeMode.dark
      : ThemeMode.light;
  notificationsEnabledNotifier.value = prefs.getBool('notifications') ?? true;
  autoRefreshNotifier.value = prefs.getBool('autoRefresh') ?? false;
  refreshIntervalNotifier.value = prefs.getInt('refreshInterval') ?? 5;
  apiEndpointNotifier.value =
      prefs.getString('apiEndpoint') ?? 'http://localhost:3000/api/reports';
}

Future<void> saveSetting(String key, dynamic value) async {
  final prefs = await SharedPreferences.getInstance();
  if (value is bool) await prefs.setBool(key, value);
  if (value is int) await prefs.setInt(key, value);
  if (value is String) await prefs.setString(key, value);
}
