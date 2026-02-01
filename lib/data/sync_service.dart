import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'local_db.dart';

class SyncService {
  static const String syncPath = '/sync/jobs';

  static String get baseUrl {
    // Android emulator -> host machine
    if (Platform.isAndroid) return 'http://10.0.2.2:5001';
    // Windows desktop / host machine
    return 'http://127.0.0.1:5001';
  }

  static Future<SyncResult> syncNow() async {
    final start = DateTime.now();
    final queue = await LocalDb.getSyncQueue();

    if (queue.isEmpty) {
      return const SyncResult(ok: true, message: 'Nothing to sync', durationMs: 0);
    }

    final payload = {
      'items': queue.map((q) {
        return {
          'entityType': q['entityType'],
          'entityId': q['entityId'],
          'action': q['action'],
          'payload': q['payload'],
          'createdAt': q['createdAt'],
        };
      }).toList(),
    };

    try {
      final uri = Uri.parse('$baseUrl$syncPath');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final duration = DateTime.now().difference(start).inMilliseconds;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        await LocalDb.clearSyncQueue();
        return SyncResult(ok: true, message: 'Sync complete', durationMs: duration);
      }

      return SyncResult(
        ok: false,
        message: 'Sync failed: HTTP ${res.statusCode} ${res.body}',
        durationMs: duration,
      );
    } catch (e) {
      final duration = DateTime.now().difference(start).inMilliseconds;
      return SyncResult(ok: false, message: 'Sync failed: $e', durationMs: duration);
    }
  }
}

class SyncResult {
  final bool ok;
  final String message;
  final int durationMs;
  const SyncResult({required this.ok, required this.message, required this.durationMs});
}
