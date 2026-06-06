import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveCsv(String csv) async {
  final fileName =
      'opticell_reports_${DateTime.now().millisecondsSinceEpoch}.csv';

  if (Platform.isAndroid) {
    try {
      const channel = MethodChannel('com.example.opticell/csv_save');
      final String? path = await channel.invokeMethod<String>(
        'saveCsvToDownloads',
        {
          'csvContent': csv,
          'fileName': fileName,
        },
      );
      if (path != null) {
        return path;
      }
    } catch (e) {
      // Fallback if platform channel fails
    }
  }

  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(csv);
  return file.path;
}
