import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app_state.dart';
import 'common.dart';
import 'dashboard_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _showNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'opticell_channel',
    'Opticell Alerts',
    channelDescription: 'Batch status alerts',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  const details = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  final id = DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

  await _notificationsPlugin.show(id, title, body, details);
}

Future<void> _notifyOnStatusChanges(List<BatchReport> statusReports) async {
  if (statusReports.isEmpty) return;

  final criticals =
      statusReports.where((r) => r.status == BatchStatus.critical).length;

  final warnings =
      statusReports.where((r) => r.status == BatchStatus.warning).length;

  if (criticals > 0) {
    await _showNotification(
      _notificationTitleForStatus(BatchStatus.critical),
      _notificationBodyForCounts(criticals, warnings),
    );
  } else if (warnings > 0) {
    await _showNotification(
      _notificationTitleForStatus(BatchStatus.warning),
      _notificationBodyForCounts(criticals, warnings),
    );
  }
}

String _notificationTitleForStatus(BatchStatus status) {
  switch (status) {
    case BatchStatus.normal:
      return 'Batch Back to Normal';
    case BatchStatus.warning:
      return 'Warning Batch Detected';
    case BatchStatus.critical:
      return 'Critical Batch Alert';
  }
}

String _notificationBodyForCounts(int criticalCount, int warningCount) {
  if (criticalCount > 0 && warningCount > 0) {
    return '$criticalCount critical and $warningCount warning batch(es) detected.';
  }
  if (criticalCount > 0) {
    return '$criticalCount critical batch(es) need immediate attention.';
  }
  return '$warningCount warning batch(es) detected.';
}

class RootScreen extends StatefulWidget {
  final UserModel user;

  const RootScreen({super.key, required this.user});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  List<BatchReport> _allReports = [];
  bool _loading = true;

  Timer? _refreshTimer;
  StreamSubscription<List<BatchReport>>? _sseSub;

  final Map<String, BatchStatus> _seenBatchStatus = {};
  bool _hasSyncedStatuses = false;

  @override
  void initState() {
    super.initState();

    _loadData();

    autoRefreshNotifier.addListener(_onAutoRefreshChanged);
    refreshIntervalNotifier.addListener(_onAutoRefreshChanged);

    if (autoRefreshNotifier.value) {
      _startTimer();
    }

    _startSse();
  }

  void _onAutoRefreshChanged() {
    if (autoRefreshNotifier.value) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();

    final minutes = refreshIntervalNotifier.value;

    _refreshTimer = Timer.periodic(
      Duration(minutes: minutes),
      (_) => _loadData(),
    );
  }

  void _stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  List<BatchReport> _collectChangedReports(List<BatchReport> reports) {
    final changed = <BatchReport>[];

    for (final r in reports) {
      final previous = _seenBatchStatus[r.id];

      if (previous == null) {
        if (_hasSyncedStatuses && r.status != BatchStatus.normal) {
          changed.add(r);
        }
      } else if (previous != r.status) {
        changed.add(r);
      }

      _seenBatchStatus[r.id] = r.status;
    }

    _hasSyncedStatuses = true;
    return changed;
  }

  void _startSse() {
    _stopSse();

    final endpoint = getApiEndpoint();

    debugPrint('SSE connecting to: $endpoint');

    try {
      _sseSub = ApiService.streamReports(endpoint).listen(
        (reports) async {
          if (!mounted) return;

          setState(() {
            _allReports = reports;
            _loading = false;
          });

          if (!notificationsEnabledNotifier.value) return;

          final changes = _collectChangedReports(reports);

          if (changes.isNotEmpty) {
            await _notifyOnStatusChanges(changes);
          }
        },
        onError: (e) {
          debugPrint('SSE error: $e');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('SSE failed: $e');
    }
  }

  void _stopSse() {
    _sseSub?.cancel();
    _sseSub = null;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final reports = await ApiService.fetchReports();

      if (!mounted) return;

      setState(() {
        _allReports = reports;
        _loading = false;
      });

      if (notificationsEnabledNotifier.value) {
        final changes = _collectChangedReports(reports);

        if (changes.isNotEmpty) {
          await _notifyOnStatusChanges(changes);
        }
      }
    } catch (e) {
      debugPrint('Load failed: $e');

      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  void dispose() {
    _stopTimer();
    _stopSse();

    autoRefreshNotifier.removeListener(_onAutoRefreshChanged);
    refreshIntervalNotifier.removeListener(_onAutoRefreshChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        reports: _allReports,
        loading: _loading,
        user: widget.user,
        onSignOut: _handleSignOut,
      ),
      ReportsScreen(
        reports: _allReports,
        loading: _loading,
        onRefresh: _loadData,
        user: widget.user,
        onSignOut: _handleSignOut,
      ),
      SettingsScreen(user: widget.user, onSignOut: _handleSignOut),
      HelpScreen(user: widget.user, onSignOut: _handleSignOut),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}