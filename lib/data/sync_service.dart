import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_db.dart';

class SyncService {
  static const String baseUrl = 'http://10.0.2.2:5000';
  static const String syncPath = '/sync/jobs';

  static Future<SyncResult> syncNow() async {
    final queue = await LocalDb.getSyncQueue();

    if (queue.isEmpty) {
      return const SyncResult(ok: true, message: 'Nothing to sync');
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

      if (res.statusCode >= 200 && res.statusCode < 300) {
        await LocalDb.clearSyncQueue();
        return const SyncResult(ok: true, message: 'Sync complete');
      }

      return SyncResult(ok: false, message: 'Sync failed: HTTP ${res.statusCode}');
    } catch (e) {
      return SyncResult(ok: false, message: 'Sync failed: $e');
    }
  }
}

class SyncResult {
  final bool ok;
  final String message;
  const SyncResult({required this.ok, required this.message});
}
