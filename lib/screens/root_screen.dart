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
    channelDescription: 'Critical batch alerts',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  const details = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );
  await _notificationsPlugin.show(0, title, body, details);
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

  @override
  void initState() {
    super.initState();
    _loadData();
    autoRefreshNotifier.addListener(_onAutoRefreshChanged);
    refreshIntervalNotifier.addListener(_onAutoRefreshChanged);
    apiEndpointNotifier.addListener(_loadData);
    apiEndpointNotifier.addListener(_startSse);
    if (autoRefreshNotifier.value) _startTimer();
    // attempt SSE immediately
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

  final Set<String> _seenCriticalIds = <String>{};

  void _startSse() {
    _stopSse();
    final endpoint = apiEndpointNotifier.value.trim();
    if (endpoint.isEmpty) return;

    try {
      _sseSub = ApiService.streamReports(endpoint).listen(
        (reports) async {
          if (!mounted) return;
          setState(() {
            _allReports = reports;
            _loading = false;
          });

          if (!notificationsEnabledNotifier.value) return;

          // Find new criticals that we haven't notified about
          final newCriticals = reports
              .where(
                (r) =>
                    r.status == BatchStatus.critical &&
                    !_seenCriticalIds.contains(r.id),
              )
              .toList();
          if (newCriticals.isNotEmpty) {
            _seenCriticalIds.addAll(newCriticals.map((r) => r.id));
            await _showNotification(
              'Critical Alert',
              '${newCriticals.length} new critical batch(es) need attention',
            );
          }
        },
        onError: (e) {
          // log errors; stream implements its own reconnection/backoff
          debugPrint('SSE listener error: $e');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Failed starting SSE: $e');
    }
  }

  void _stopSse() {
    _sseSub?.cancel();
    _sseSub = null;
  }

  @override
  void dispose() {
    _stopTimer();
    autoRefreshNotifier.removeListener(_onAutoRefreshChanged);
    refreshIntervalNotifier.removeListener(_onAutoRefreshChanged);
    apiEndpointNotifier.removeListener(_loadData);
    apiEndpointNotifier.removeListener(_startSse);
    _stopSse();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final reports = await ApiService.fetchReports();
      setState(() {
        _allReports = reports;
        _loading = false;
      });
      // Show user-friendly warning if the ApiService recorded an error
      if (ApiService.lastError != null && mounted) {
        final msg = ApiService.lastError!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Data load warning: $msg')));
        ApiService.lastError = null;
      }
      if (notificationsEnabledNotifier.value) {
        final criticals = reports
            .where((r) => r.status == BatchStatus.critical)
            .toList();
        if (criticals.isNotEmpty) {
          await _showNotification(
            'Critical Alert',
            '${criticals.length} batch(es) need immediate attention',
          );
        }
      }
    } catch (_) {
      setState(() {
        _allReports = dummyReports;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load data — using local fallback'),
          ),
        );
      }
    }
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
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
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
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF374151)
                : Theme.of(context).colorScheme.outlineVariant,
            width: 0.65,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                isActive: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Reports',
                isActive: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                isActive: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
              NavItem(
                icon: Icons.help_outline,
                activeIcon: Icons.help,
                label: 'Help',
                isActive: selectedIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? const Color(0xFF155DFC)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFF155DFC).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
