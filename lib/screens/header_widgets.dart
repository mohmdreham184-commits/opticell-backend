import 'package:flutter/material.dart';
import '../app_state.dart';
import 'common.dart';

class HeaderActions extends StatelessWidget {
  final UserModel user;
  final Future<void> Function() onSignOut;

  const HeaderActions({super.key, required this.user, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: notificationsEnabledNotifier,
          builder: (_, enabled, __) {
            return GestureDetector(
              onTap: enabled
                  ? () async {
                      await showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => const NotificationsSheet(),
                      );
                      hasUnreadNotifier.value = false;
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications are disabled'),
                        ),
                      );
                    },
              child: ValueListenableBuilder<bool>(
                valueListenable: hasUnreadNotifier,
                builder: (_, hasUnread, __) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 0.65,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: enabled
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.35),
                        ),
                      ),
                      if (enabled && hasUnread)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC10007),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => ProfileSheet(user: user, onSignOut: onSignOut),
          ),
          child: ValueListenableBuilder<String>(
            valueListenable: userDisplayNameNotifier,
            builder: (_, __, ___) =>
                AvatarCircle(user: user, radius: 20, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class AvatarCircle extends StatelessWidget {
  final UserModel user;
  final double radius;
  final double fontSize;

  const AvatarCircle({
    super.key,
    required this.user,
    required this.radius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final nameVal = userDisplayNameNotifier.value.trim();
    final initial = nameVal.isEmpty ? user.initials : nameVal[0].toUpperCase();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        color: Color(0xFF155DFC),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final List<NotifItem> _notifs = [
    NotifItem(
      title: 'Critical Alert',
      body: 'Batch 003 temperature exceeds safe limit.',
      time: '2 min ago',
      icon: Icons.error_outline,
      color: const Color(0xFFC10007),
      bg: const Color(0xFFFFE2E2),
      read: false,
    ),
    NotifItem(
      title: 'Warning',
      body: 'Batch 002 pressure slightly above threshold.',
      time: '14 min ago',
      icon: Icons.warning_amber_outlined,
      color: const Color(0xFFA65F00),
      bg: const Color(0xFFFEF9C2),
      read: false,
    ),
    NotifItem(
      title: 'Batch Completed',
      body: 'Batch 001 finished successfully.',
      time: '1 hr ago',
      icon: Icons.check_circle_outline,
      color: const Color(0xFF008236),
      bg: const Color(0xFFDCFCE7),
      read: true,
    ),
    NotifItem(
      title: 'Batch Completed',
      body: 'Batch 004 finished with optimal conditions.',
      time: '2 days ago',
      icon: Icons.check_circle_outline,
      color: const Color(0xFF008236),
      bg: const Color(0xFFDCFCE7),
      read: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.read).length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE2E2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFC10007),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (final n in _notifs) {
                            n.read = true;
                          }
                        });
                      },
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF155DFC),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifs.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                indent: 72,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (_, i) {
                final n = _notifs[i];
                return InkWell(
                  onTap: () => setState(() => n.read = true),
                  child: Container(
                    color: n.read
                        ? Colors.transparent
                        : Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: n.bg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(n.icon, color: n.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    n.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: n.read
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    n.time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.body,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!n.read)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF155DFC),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NotifItem {
  String title;
  String body;
  String time;
  IconData icon;
  Color color;
  Color bg;
  bool read;

  NotifItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    required this.bg,
    required this.read,
  });
}

class ProfileSheet extends StatefulWidget {
  final UserModel user;
  final Future<void> Function() onSignOut;

  const ProfileSheet({super.key, required this.user, required this.onSignOut});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _roleCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _emailCtrl = TextEditingController(text: widget.user.email);
    _roleCtrl = TextEditingController(text: widget.user.role);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF155DFC),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.user.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ProfileField(
              label: 'Full Name',
              ctrl: _nameCtrl,
              icon: Icons.person_outline,
              enabled: false,
            ),
            const SizedBox(height: 12),
            ProfileField(
              label: 'Email',
              ctrl: _emailCtrl,
              icon: Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: 12),
            ProfileField(
              label: 'Role',
              ctrl: _roleCtrl,
              icon: Icons.badge_outlined,
              enabled: false,
            ),
            const SizedBox(height: 24),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ProfileStat(label: 'Reports', value: '5'),
                ProfileStat(label: 'Alerts', value: '2'),
                ProfileStat(label: 'Days Active', value: '12'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  widget.onSignOut();
                },
                icon: const Icon(
                  Icons.logout,
                  size: 16,
                  color: Color(0xFFC10007),
                ),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Color(0xFFC10007), fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFE2E2), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final bool enabled;

  const ProfileField({
    super.key,
    required this.label,
    required this.ctrl,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.65,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF155DFC), width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.65,
          ),
        ),
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const ProfileStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF155DFC),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
