import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../app_state.dart';

final ValueNotifier<String> userDisplayNameNotifier = ValueNotifier<String>('');
final ValueNotifier<bool> hasUnreadNotifier = ValueNotifier<bool>(true);

class UserModel {
  final String name;
  final String email;
  final String role;

  const UserModel({
    required this.name,
    required this.email,
    required this.role,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    return parts[0][0].toUpperCase();
  }
}

enum BatchStatus { normal, warning, critical }

class BatchReport {
  final String id;
  final String title;
  final String dateTime;
  final BatchStatus status;
  final double temperature;
  final double pressure;
  final String description;

  const BatchReport({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.status,
    required this.temperature,
    required this.pressure,
    required this.description,
  });

  factory BatchReport.fromJson(Map<String, dynamic> json) {
    // Handle Supabase schema
    final double temp = (json['temperature'] as num?)?.toDouble() ?? 0.0;
    final double pressure = (json['pressure'] as num?)?.toDouble() ?? 0.0;

    // Determine status based on thresholds
    BatchStatus status = BatchStatus.normal;
    if (temp > 80 || pressure > 80) {
      status = BatchStatus.critical;
    } else if (temp > 70 || pressure > 70) {
      status = BatchStatus.warning;
    }

    final dynamic dateValue = json['timestamp'] ?? json['dateTime'];
    String dateTime;
    if (dateValue is Timestamp) {
      dateTime = dateValue.toDate().toString();
    } else if (dateValue is DateTime) {
      dateTime = dateValue.toString();
    } else {
      dateTime = dateValue?.toString() ?? '';
    }

    return BatchReport(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Batch ${json['id'] ?? 'Unknown'}',
      dateTime: dateTime,
      status: status,
      temperature: temp,
      pressure: pressure,
      description: json['description'] ?? 'Sensor reading',
    );
  }

  String toCsvRow() =>
      '"$id","$title","$dateTime","${_statusLabel(status)}","$temperature","$pressure","$description"';

  static String _statusLabel(BatchStatus s) {
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

const List<Map<String, dynamic>> _dummyJson = [
  {
    'id': '1',
    'title': 'Batch 001',
    'dateTime': '2023-11-16 10:25:30',
    'status': 'normal',
    'temperature': 68.0,
    'pressure': 76.0,
    'description': 'All parameters within range',
  },
  {
    'id': '2',
    'title': 'Batch 002',
    'dateTime': '2023-11-16 10:16:30',
    'status': 'warning',
    'temperature': 72.0,
    'pressure': 68.0,
    'description': 'Pressure slightly above threshold',
  },
  {
    'id': '3',
    'title': 'Batch 003',
    'dateTime': '2023-11-16 10:03:30',
    'status': 'critical',
    'temperature': 90.0,
    'pressure': 83.0,
    'description': 'Temperature exceeding limit',
  },
  {
    'id': '4',
    'title': 'Batch 004',
    'dateTime': '2023-11-14 23:45:10',
    'status': 'normal',
    'temperature': 65.0,
    'pressure': 74.0,
    'description': 'Optimal conditions',
  },
  {
    'id': '5',
    'title': 'Batch 005',
    'dateTime': '2023-11-14 22:30:05',
    'status': 'normal',
    'temperature': 67.0,
    'pressure': 75.0,
    'description': 'All parameters within range',
  },
];

List<BatchReport> get dummyReports =>
    _dummyJson.map((e) => BatchReport.fromJson(e)).toList();

class ApiService {
  /// Last error message observed while fetching data. Useful for UI feedback.
  static String? lastError;

  static Future<List<BatchReport>> fetchReports() async {
    lastError = null;
    final endpoint = getApiEndpoint();
    debugPrint('📡 Fetching from: $endpoint');
    
    final reports = await fetchReportsFromEndpoint(endpoint);
    
    if (reports.isNotEmpty) {
      debugPrint('✅ Got ${reports.length} reports from API');
      return reports;
    }
    
    debugPrint('⚠️ API empty or failed. Trying Firestore...');
    final firebaseReports = await fetchReportsFromFirestore();
    
    if (firebaseReports.isNotEmpty) {
      debugPrint('✅ Got ${firebaseReports.length} reports from Firestore');
      return firebaseReports;
    }
    
    debugPrint('⚠️ Using dummy data');
    return dummyReports;
  }

  static Future<List<BatchReport>> fetchReportsFromEndpoint(
    String endpoint,
  ) async {
    try {
      final uri = Uri.parse(endpoint);
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Opticell/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📊 Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        lastError = 'HTTP ${response.statusCode}';
        return [];
      }

      if (response.body.isEmpty) {
        lastError = 'Empty response';
        return [];
      }

      final decoded = jsonDecode(response.body);
      final records = decoded is List ? decoded : [];

      return records.map((item) {
        if (item is Map<String, dynamic>) {
          return BatchReport.fromJson(item);
        }
        if (item is Map) {
          return BatchReport.fromJson(Map<String, dynamic>.from(item));
        }
        return BatchReport.fromJson({});
      }).toList();
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ API error: $e');
      return [];
    }
  }

  static Future<List<BatchReport>> fetchReportsFromFirestore() async {
    try {
      debugPrint('🔥 Trying Firestore...');
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('dateTime', descending: true)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs
          .map((doc) => BatchReport.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ Firestore error: $e');
      return [];
    }
  }

  /// Connect to a Server-Sent Events (SSE) endpoint and emit report lists
  /// The [endpoint] should point to the normal reports endpoint (e.g. /api/reports).
  /// This method will try to derive a streaming path by appending '/stream'.
  ///
  /// The returned stream will attempt reconnection with exponential backoff
  /// when the connection fails. Cancellation of the stream stops reconnection.
  static Stream<List<BatchReport>> streamReports(String endpoint) {
    final controller = StreamController<List<BatchReport>>.broadcast();

    bool cancelled = false;

    controller.onListen = () {
      cancelled = false;
      () async {
        int attempt = 0;
        const int maxRetries = 10;
        const baseDelay = Duration(seconds: 2);

        while (!cancelled) {
          attempt++;
          try {
            final uri = Uri.parse(endpoint);
            Uri streamUri;
            if (uri.path.endsWith('/stream')) {
              streamUri = uri;
            } else {
              final newPath = uri.path.endsWith('/')
                  ? '${uri.path}stream'
                  : '${uri.path}/stream';
              streamUri = uri.replace(path: newPath);
            }

            debugPrint('🔌 Connecting to SSE: $streamUri (attempt $attempt)');

            final client = http.Client();
            final request = http.Request('GET', streamUri);
            request.headers['Accept'] = 'text/event-stream';
            request.headers['User-Agent'] = 'Opticell/1.0.0';

            final streamed = await client
                .send(request)
                .timeout(const Duration(seconds: 20));

            if (streamed.statusCode != 200) {
              debugPrint('❌ SSE endpoint response ${streamed.statusCode}');
              lastError = 'Live stream unavailable (${streamed.statusCode})';
              client.close();
              if (cancelled) break;
              await Future.delayed(const Duration(seconds: 3));
              continue;
            }

            debugPrint('✅ SSE connected successfully');
            attempt = 0; // Reset on successful connection

            final buffer = StringBuffer();

            await for (final chunk in streamed.stream.transform(utf8.decoder)) {
              if (cancelled) break;
              buffer.write(chunk);

              String content = buffer.toString().replaceAll('\r\n', '\n');
              int idx;
              while ((idx = content.indexOf('\n\n')) != -1) {
                final rawEvent = content.substring(0, idx).trim();
                content = content.substring(idx + 2);

                final dataLines = rawEvent
                    .split('\n')
                    .where((l) => l.startsWith('data:'))
                    .map((l) => l.substring(5).trim())
                    .toList();

                if (dataLines.isNotEmpty) {
                  final payload = dataLines.join('\n');
                  try {
                    final decoded = jsonDecode(payload);
                    final records = decoded is List
                        ? decoded
                        : decoded['data'] ?? decoded['reports'] ?? [];
                    
                    if (records is List && records.isNotEmpty) {
                      debugPrint('📨 SSE received ${records.length} records');
                      final list = records.map((item) {
                        if (item is Map<String, dynamic>) {
                          return BatchReport.fromJson(item);
                        }
                        if (item is Map) {
                          return BatchReport.fromJson(
                            Map<String, dynamic>.from(item),
                          );
                        }
                        throw StateError('Invalid report item format');
                      }).toList();
                      if (!controller.isClosed) {
                        controller.add(list);
                      }
                    }
                  } catch (e) {
                    debugPrint('⚠️ SSE parse error: $e');
                    lastError = e.toString();
                  }
                }
              }

              buffer.clear();
              buffer.write(content);
            }

            client.close();
            debugPrint('⚠️ SSE connection closed cleanly');

            // clean disconnect: reset attempts
            attempt = 0;
            if (!cancelled) await Future.delayed(baseDelay);
          } catch (e) {
            debugPrint('❌ SSE connection error (attempt $attempt): $e');
            lastError = e.toString();
            if (cancelled) break;
            final mult = pow(2, min(attempt, maxRetries)).toInt();
            final waitSec = min(60, baseDelay.inSeconds * mult);
            debugPrint('⏳ Retrying in ${waitSec}s...');
            await Future.delayed(Duration(seconds: waitSec));
          }
        }
      }();
    };

    controller.onCancel = () {
      cancelled = true;
      try {
        controller.close();
      } catch (_) {}
    };

    return controller.stream;
  }
}
