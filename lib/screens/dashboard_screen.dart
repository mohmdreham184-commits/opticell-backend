import 'package:flutter/material.dart';
import 'common.dart';
import 'header_widgets.dart';
import 'shared_widgets.dart' as widgets;

class DashboardScreen extends StatefulWidget {
  final List<BatchReport> reports;
  final bool loading;
  final UserModel user;
  final Future<void> Function() onSignOut;

  const DashboardScreen({
    super.key,
    required this.reports,
    required this.loading,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BatchReport> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.reports;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void didUpdateWidget(DashboardScreen old) {
    super.didUpdateWidget(old);
    if (old.reports != widget.reports) _onSearch();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.reports.where((r) {
        return q.isEmpty ||
            r.id.toLowerCase().contains(q) ||
            r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            _statusLabel(r.status).toLowerCase().contains(q);
      }).toList();
    });
  }

  String _statusLabel(BatchStatus s) {
    switch (s) {
      case BatchStatus.normal:
        return 'Normal';
      case BatchStatus.warning:
        return 'Warning';
      case BatchStatus.critical:
        return 'Critical';
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<BatchReport> recentReports = _searchCtrl.text.isEmpty
        ? widget.reports
        : _filtered;
    final int total = widget.reports.length;
    final int normal = widget.reports
        .where((r) => r.status == BatchStatus.normal)
        .length;
    final int warning = widget.reports
        .where((r) => r.status == BatchStatus.warning)
        .length;
    final int critical = widget.reports
        .where((r) => r.status == BatchStatus.critical)
        .length;
    final double avgTemp = total == 0
        ? 0.0
        : widget.reports.map((r) => r.temperature).reduce((a, b) => a + b) /
              total;
    final double avgPressure = total == 0
        ? 0.0
        : widget.reports.map((r) => r.pressure).reduce((a, b) => a + b) / total;

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
                      'Dashboard',
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
            const SizedBox(height: 16),
            widgets.SearchBar(controller: _searchCtrl),
            const SizedBox(height: 16),
            if (widget.loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Text(
                'Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Batches',
                      value: '$total',
                      color: const Color(0xFF155DFC),
                      bgColor: const Color(0xFFEEF3FF),
                      icon: Icons.science_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Normal',
                      value: '$normal',
                      color: const Color(0xFF008236),
                      bgColor: const Color(0xFFDCFCE7),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Warnings',
                      value: '$warning',
                      color: const Color(0xFFA65F00),
                      bgColor: const Color(0xFFFEF9C2),
                      icon: Icons.warning_amber_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Critical',
                      value: '$critical',
                      color: const Color(0xFFC10007),
                      bgColor: const Color(0xFFFFE2E2),
                      icon: Icons.error_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Averages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.65,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AverageItem(
                        label: 'Avg Temperature',
                        value: '${avgTemp.toStringAsFixed(1)}°C',
                        icon: Icons.thermostat_outlined,
                        color: const Color(0xFFC10007),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: AverageItem(
                        label: 'Avg Pressure',
                        value: '${avgPressure.toStringAsFixed(1)} psi',
                        icon: Icons.compress_outlined,
                        color: const Color(0xFF155DFC),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Status Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              StatusBar(
                total: total,
                normal: normal,
                warning: warning,
                critical: critical,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchCtrl.text.isEmpty
                        ? 'Recent Batches'
                        : '${recentReports.length} result${recentReports.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    TextButton(
                      onPressed: () => _searchCtrl.clear(),
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF155DFC),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (recentReports.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No batches found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...recentReports
                    .take(_searchCtrl.text.isEmpty ? 3 : recentReports.length)
                    .map((r) => widgets.ReportCard(report: r))
                    .toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.65,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
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
      ),
    );
  }
}

class AverageItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AverageItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class StatusBar extends StatelessWidget {
  final int total;
  final int normal;
  final int warning;
  final int critical;

  const StatusBar({
    super.key,
    required this.total,
    required this.normal,
    required this.warning,
    required this.critical,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.65,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (normal > 0)
                  Expanded(
                    flex: normal,
                    child: Container(
                      height: 12,
                      color: const Color(0xFF008236),
                    ),
                  ),
                if (warning > 0)
                  Expanded(
                    flex: warning,
                    child: Container(
                      height: 12,
                      color: const Color(0xFFA65F00),
                    ),
                  ),
                if (critical > 0)
                  Expanded(
                    flex: critical,
                    child: Container(
                      height: 12,
                      color: const Color(0xFFC10007),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              LegendItem(
                color: const Color(0xFF008236),
                label: 'Normal',
                pct: (normal / total * 100).round(),
              ),
              LegendItem(
                color: const Color(0xFFA65F00),
                label: 'Warning',
                pct: (warning / total * 100).round(),
              ),
              LegendItem(
                color: const Color(0xFFC10007),
                label: 'Critical',
                pct: (critical / total * 100).round(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int pct;

  const LegendItem({
    super.key,
    required this.color,
    required this.label,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label $pct%',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
