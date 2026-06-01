import 'package:flutter/material.dart';
import 'common.dart';
import 'header_widgets.dart';
import 'chat_screen.dart';

class HelpScreen extends StatefulWidget {
  final UserModel user;
  final Future<void> Function() onSignOut;

  const HelpScreen({super.key, required this.user, required this.onSignOut});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<FaqItem> _faqs = [
    FaqItem(
      q: 'What does "Critical" status mean?',
      a: 'Critical means one or more parameters (temperature or pressure) have exceeded safe operating limits. Immediate action is recommended.',
    ),
    FaqItem(
      q: 'How often is data refreshed?',
      a: 'Data is fetched on app launch and whenever you pull down to refresh. You can enable auto-refresh in Settings.',
    ),
    FaqItem(
      q: 'How do I export reports?',
      a: 'Go to the Reports tab, optionally apply filters, then press the Export button. You\'ll see the CSV data which you can copy.',
    ),
    FaqItem(
      q: 'Can I filter by multiple statuses?',
      a: 'Currently you can filter by one status at a time. Multi-select filtering is coming in a future update.',
    ),
    FaqItem(
      q: 'How do I change the API endpoint?',
      a: 'Go to Settings → Account → API Endpoint and enter your server URL.',
    ),
  ];

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
                      'Help & FAQ',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF155DFC), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need support?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Contact our team for technical assistance',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChatScreen(
                            endpoint:
                                'https://opticell.vercel.app/api/chat-external',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF155DFC),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Chat', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ..._faqs.map((faq) => FaqTile(item: faq)),
          ],
        ),
      ),
    );
  }
}

class FaqItem {
  final String q;
  final String a;

  FaqItem({required this.q, required this.a});
}

class FaqTile extends StatefulWidget {
  final FaqItem item;
  const FaqTile({super.key, required this.item});

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _open
              ? const Color(0xFF155DFC)
              : Theme.of(context).colorScheme.outlineVariant,
          width: 0.65,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.item.q,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _open
                            ? const Color(0xFF155DFC)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.item.a,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
