// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

Future<String> saveCsv(String csv) async {
  final bytes = utf8.encode(csv);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute(
      'download',
      'opticell_reports_${DateTime.now().millisecondsSinceEpoch}.csv',
    )
    ..click();
  html.Url.revokeObjectUrl(url);
  return 'web';
}
