import 'package:flutter_test/flutter_test.dart';
import 'package:opticell/screens/common.dart';

void main() {
  group('BatchReport', () {
    test('parses numeric fields and detects critical status', () {
      final json = {
        'id': 'x',
        'title': 't',
        'temperature': 90,
        'pressure': 50,
        'description': 'd',
        'dateTime': '2023-01-01',
      };
      final r = BatchReport.fromJson(json);
      expect(r.status, BatchStatus.critical);
      expect(r.temperature, 90);
      expect(r.toCsvRow().contains('Critical'), isTrue);
    });

    test('parses warning status when >70', () {
      final json = {
        'id': 'y',
        'title': 't2',
        'temperature': 72,
        'pressure': 60,
        'description': 'd2',
        'dateTime': '2023-01-02',
      };
      final r = BatchReport.fromJson(json);
      expect(r.status, BatchStatus.warning);
    });

    test('defaults for missing numeric fields and csv columns', () {
      final json = {'title': 'noids', 'description': 'empty'};
      final r = BatchReport.fromJson(json);
      expect(r.id, '');
      expect(r.temperature, 0.0);
      // CSV has 7 columns separated by commas (but fields are quoted)
      final cols = r.toCsvRow().split(',');
      expect(cols.length, 7);
    });
  });
}
