import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'common.dart';
import 'header_widgets.dart';
import 'shared_widgets.dart' as widgets;
import '../utils/csv_export.dart';

class ReportsScreen extends StatefulWidget {
  final List<BatchReport> reports;
  final bool loading;
  final Future<void> Function() onRefresh;
  final UserModel user;
  final Future<void> Function() onSignOut;

  const ReportsScreen({
    super.key,
    required this.reports,
    required this.loading,
    required this.onRefresh,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<BatchReport> _filtered = [];
  BatchStatus? _activeFilter;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.reports;
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void didUpdateWidget(ReportsScreen old) {
    super.didUpdateWidget(old);
    if (old.reports != widget.reports) _applyFilters();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = widget.reports.where((r) {
        final matchesSearch =
            q.isEmpty ||
            r.id.toLowerCase().contains(q) ||
            r.title.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.dateTime.toLowerCase().contains(q) ||
            _statusLabel(r.status).toLowerCase().contains(q);
        final matchesStatus =
            _activeFilter == null || r.status == _activeFilter;
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showFilterDialog() async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => widgets.FilterSheet(current: _activeFilter),
    );
    if (result is widgets.ClearFilter) {
      setState(() => _activeFilter = null);
    } else if (result != null) {
      setState(() => _activeFilter = result as BatchStatus);
    }
    _applyFilters();
  }

  Future<void> _exportData() async {
    if (widget.reports.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    const header =
        '"ID","Title","DateTime","Status","Temperature","Pressure","Description"';
    final rows = _filtered.map((r) => r.toCsvRow()).join('\n');
    final csv = '$header\n$rows';

    try {
      if (kIsWeb) {
        await saveCsv(csv);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report exported successfully')),
          );
        }
      } else {
        final path = await saveCsv(csv);
        await Share.shareXFiles([XFile(path)], text: 'Opticell reports export');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Report exported: $path')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilter = _activeFilter != null;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Row(
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
                      'Reports',
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
          ),
          if (hasFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(_statusLabel(_activeFilter!)),
                    selected: true,
                    selectedColor: const Color(0xFFEEF3FF),
                    checkmarkColor: const Color(0xFF155DFC),
                    labelStyle: const TextStyle(
                      color: Color(0xFF155DFC),
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() => _activeFilter = null);
                      _applyFilters();
                    },
                    deleteIcon: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFF155DFC),
                    ),
                    onDeleted: () {
                      setState(() => _activeFilter = null);
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: widgets.SearchBar(controller: _searchCtrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFilterDialog,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        if (hasFilter)
                          Positioned(
                            right: -4,
                            top: -4,
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
                    label: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(
                        color: hasFilter
                            ? const Color(0xFF155DFC)
                            : Theme.of(context).colorScheme.outlineVariant,
                        width: 0.65,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(
                      Icons.download,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Export',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: -0.15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF155DFC),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          ApiService.lastError != null
                              ? 'Failed to load reports: ${ApiService.lastError}'
                              : 'No reports found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (ApiService.lastError != null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Please verify the API endpoint and ensure the backend is running.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        if (hasFilter || _searchCtrl.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _activeFilter = null);
                              _applyFilters();
                            },
                            child: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) =>
                          widgets.ReportCard(report: _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
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
}
