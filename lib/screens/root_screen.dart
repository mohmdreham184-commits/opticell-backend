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

/// =====================
/// NOTIFICATIONS
/// =====================

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

Future<void> _notifyOnStatusChanges(List<BatchReport> reports) async {
  if (reports.isEmpty) return;

  final critical =
      reports.where((r) => r.status == BatchStatus.critical).length;

  final warning =
      reports.where((r) => r.status == BatchStatus.warning).length;

  if (critical > 0) {
    await _showNotification(
      _title(BatchStatus.critical),
      _body(critical, warning),
    );
  } else if (warning > 0) {
    await _showNotification(
      _title(BatchStatus.warning),
      _body(critical, warning),
    );
  }
}

String _title(BatchStatus status) {
  switch (status) {
    case BatchStatus.normal:
      return 'Batch Back to Normal';
    case BatchStatus.warning:
      return 'Warning Batch Detected';
    case BatchStatus.critical:
      return 'Critical Batch Alert';
  }
}

String _body(int critical, int warning) {
  if (critical > 0 && warning > 0) {
    return '$critical critical and $warning warning batch(es).';
  }
  if (critical > 0) {
    return '$critical critical batch(es) need attention.';
  }
  return '$warning warning batch(es).';
}

/// =====================
/// ROOT SCREEN
/// =====================

class RootScreen extends StatefulWidget {
  final UserModel user;

  const RootScreen({super.key, required this.user});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  List<BatchReport> _reports = [];
  bool _loading = true;

  Timer? _timer;
  StreamSubscription<List<BatchReport>>? _sseSub;

  final Map<String, BatchStatus> _seen = {};
  bool _synced = false;

  @override
  void initState() {
    super.initState();

    _loadData();

    autoRefreshNotifier.addListener(_autoRefreshChanged);
    refreshIntervalNotifier.addListener(_autoRefreshChanged);

    if (autoRefreshNotifier.value) {
      _startTimer();
    }

    // SSE is disabled for now - using polling instead
    // _startSSE();
  }

  /// =====================
  /// AUTO REFRESH
  /// =====================

  void _autoRefreshChanged() {
    if (autoRefreshNotifier.value) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer();

    final minutes = refreshIntervalNotifier.value;

    _timer = Timer.periodic(
      Duration(minutes: minutes),
      (_) => _loadData(),
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// =====================
  /// CHANGE DETECTION
  /// =====================

  List<BatchReport> _detectChanges(List<BatchReport> reports) {
    final changed = <BatchReport>[];

    for (final r in reports) {
      final prev = _seen[r.id];

      if (prev == null) {
        if (_synced && r.status != BatchStatus.normal) {
          changed.add(r);
        }
      } else if (prev != r.status) {
        changed.add(r);
      }

      _seen[r.id] = r.status;
    }

    _synced = true;
    return changed;
  }

  /// =====================
  /// SSE
  /// =====================

  void _startSSE() {
    _stopSSE();

    final endpoint = getApiEndpoint();

    debugPrint('SSE -> $endpoint');

    try {
      _sseSub = ApiService.streamReports(endpoint).listen(
        (reports) async {
          if (!mounted) return;

          setState(() {
            _reports = reports;
            _loading = false;
          });

          if (!notificationsEnabledNotifier.value) return;

          final changes = _detectChanges(reports);

          if (changes.isNotEmpty) {
            await _notifyOnStatusChanges(changes);
          }
        },
        onError: (e) {
          debugPrint('SSE error: $e');
        },
      );
    } catch (e) {
      debugPrint('SSE failed: $e');
    }
  }

  void _stopSSE() {
    _sseSub?.cancel();
    _sseSub = null;
  }

  /// =====================
  /// LOAD DATA
  /// =====================

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final data = await ApiService.fetchReports();

      if (!mounted) return;

      setState(() {
        _reports = data;
        _loading = false;
      });

      final changes = _detectChanges(data);

      if (notificationsEnabledNotifier.value && changes.isNotEmpty) {
        await _notifyOnStatusChanges(changes);
      }
    } catch (e) {
      debugPrint('Load error: $e');

      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  /// =====================
  /// SIGN OUT
  /// =====================

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  void dispose() {
    _stopTimer();
    _stopSSE();

    autoRefreshNotifier.removeListener(_autoRefreshChanged);
    refreshIntervalNotifier.removeListener(_autoRefreshChanged);

    super.dispose();
  }

  /// =====================
  /// UI
  /// =====================

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        reports: _reports,
        loading: _loading,
        user: widget.user,
        onSignOut: _signOut,
      ),
      ReportsScreen(
        reports: _reports,
        loading: _loading,
        onRefresh: _loadData,
        user: widget.user,
        onSignOut: _signOut,
      ),
      SettingsScreen(user: widget.user, onSignOut: _signOut),
      HelpScreen(user: widget.user, onSignOut: _signOut),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

/// =====================
/// BOTTOM NAV
/// =====================

class _AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.6,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(Icons.dashboard, 0, 'Dashboard'),
              _item(Icons.bar_chart, 1, 'Reports'),
              _item(Icons.settings, 2, 'Settings'),
              _item(Icons.help, 3, 'Help'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, int index, String label) {
    final active = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? Colors.blue : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}