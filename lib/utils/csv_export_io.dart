import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveCsv(String csv) async {
  Directory directory;
  if (Platform.isAndroid) {
    final dirs = await getExternalStorageDirectories(
      type: StorageDirectory.downloads,
    );
    directory = dirs?.first ?? await getApplicationDocumentsDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }

  final fileName =
      'opticell_reports_${DateTime.now().millisecondsSinceEpoch}.csv';
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(csv);
  return file.path;
}
