import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_state.dart';
import 'common.dart';
import 'header_widgets.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

class SettingsScreen extends StatefulWidget {
  final UserModel user;
  final Future<void> Function() onSignOut;

  const SettingsScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _autoRefresh = false;
  int _refreshInterval = 5;
  String _tempUnit = '°C';
  late final TextEditingController _endpointController;
  String _apiEndpoint = '';

  final List<int> _intervals = [1, 5, 10, 30];
  final Map<int, String> _intervalLabels = {
    1: '1 min',
    5: '5 min',
    10: '10 min',
    30: '30 min',
  };

  @override
  void initState() {
    super.initState();
    _notifications = notificationsEnabledNotifier.value;
    _darkMode = themeModeNotifier.value == ThemeMode.dark;
    _autoRefresh = autoRefreshNotifier.value;
    _refreshInterval = refreshIntervalNotifier.value;
    _apiEndpoint = apiEndpointNotifier.value;
    _endpointController = TextEditingController(text: _apiEndpoint);
  }

  Future<void> _toggleNotifications(bool v) async {
    setState(() => _notifications = v);
    notificationsEnabledNotifier.value = v;
    if (!v) hasUnreadNotifier.value = false;
    await saveSetting('notifications', v);

    if (v) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Push notifications enabled'),
            backgroundColor: Color(0xFF008236),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Push notifications disabled')),
        );
      }
    }
  }

  Future<void> _toggleDarkMode(bool v) async {
    setState(() => _darkMode = v);
    themeModeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
    await saveSetting('darkMode', v);
  }

  Future<void> _toggleAutoRefresh(bool v) async {
    setState(() => _autoRefresh = v);
    autoRefreshNotifier.value = v;
    await saveSetting('autoRefresh', v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            v
                ? 'Auto refresh enabled every ${_intervalLabels[_refreshInterval]}'
                : 'Auto refresh disabled',
          ),
          backgroundColor: v ? const Color(0xFF008236) : null,
        ),
      );
    }
  }

  Future<void> _changeInterval(int? v) async {
    if (v == null) return;
    setState(() => _refreshInterval = v);
    refreshIntervalNotifier.value = v;
    await saveSetting('refreshInterval', v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refresh interval set to ${_intervalLabels[v]}'),
        ),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Clear Cache',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove all locally stored data. Settings will be kept.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC10007),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final k in keys) {
      if (![
        'darkMode',
        'notifications',
        'autoRefresh',
        'refreshInterval',
      ].contains(k)) {
        await prefs.remove(k);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: Color(0xFF008236),
        ),
      );
    }
  }

  Future<void> _saveApiEndpoint(String value) async {
    final endpoint = value.trim();
    setState(() => _apiEndpoint = endpoint);
    final effectiveEndpoint = endpoint.isNotEmpty ? endpoint : getApiEndpoint();
    apiEndpointNotifier.value = effectiveEndpoint;
    await saveSetting('apiEndpoint', endpoint);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          endpoint.isEmpty
              ? 'API endpoint cleared. Using default endpoint.'
              : 'API endpoint saved.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC10007),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await widget.onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Opticell',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                HeaderActions(user: widget.user, onSignOut: widget.onSignOut),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSection(
              title: 'General',
              children: [
                ToggleTile(
                  title: 'Push Notifications',
                  subtitle: _notifications
                      ? 'Alerts are on for critical batches'
                      : 'No alerts will be sent',
                  icon: _notifications
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  value: _notifications,
                  onChanged: _toggleNotifications,
                ),
                ToggleTile(
                  title: 'Dark Mode',
                  subtitle: _darkMode
                      ? 'Dark theme is on'
                      : 'Light theme is on',
                  icon: _darkMode ? Icons.dark_mode : Icons.light_mode_outlined,
                  value: _darkMode,
                  onChanged: _toggleDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsSection(
              title: 'Data',
              children: [
                ToggleTile(
                  title: 'Auto Refresh',
                  subtitle: _autoRefresh
                      ? 'Refreshing every ${_intervalLabels[_refreshInterval]}'
                      : 'Pull down to refresh manually',
                  icon: Icons.refresh_outlined,
                  value: _autoRefresh,
                  onChanged: _toggleAutoRefresh,
                ),
                if (_autoRefresh)
                  ListTile(
                    leading: Icon(
                      Icons.timer_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    title: const Text(
                      'Refresh Interval',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: DropdownButton<int>(
                      value: _refreshInterval,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF155DFC),
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: _changeInterval,
                      items: _intervals
                          .map(
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(_intervalLabels[i]!),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                DropdownTile(
                  title: 'Temperature Unit',
                  icon: Icons.thermostat_outlined,
                  value: _tempUnit,
                  options: const ['°C', '°F', 'K'],
                  onChanged: (v) => setState(() => _tempUnit = v ?? _tempUnit),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsSection(
              title: 'Account',
              children: [
                ListTile(
                  leading: Icon(
                    Icons.link_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  title: const Text(
                    'API Endpoint',
                    style: TextStyle(fontSize: 14),
                  ),
                  subtitle: TextField(
                    controller: _endpointController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'https://your-server.com/api/reports',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: _saveApiEndpoint,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: () => _saveApiEndpoint(_endpointController.text),
                  ),
                ),
                ActionTile(
                  title: 'Clear Cache',
                  subtitle: 'Remove locally stored data',
                  icon: Icons.delete_outline,
                  onTap: _clearCache,
                ),
                ActionTile(
                  title: 'Sign Out',
                  subtitle: 'Log out of your account',
                  icon: Icons.logout,
                  danger: true,
                  onTap: _signOut,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Opticell v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.65,
            ),
          ),
          child: Column(
            children: children
                .expand(
                  (w) => [
                    w,
                    if (w != children.last)
                      Divider(
                        height: 1,
                        indent: 48,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                  ],
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      value: value,
      activeThumbColor: const Color(0xFF155DFC),
      onChanged: onChanged,
    );
  }
}

class DropdownTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const DropdownTile({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF155DFC),
          fontWeight: FontWeight.w500,
        ),
        onChanged: onChanged,
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const Color(0xFFC10007)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: danger
              ? const Color(0xFFC10007)
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.outline,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
