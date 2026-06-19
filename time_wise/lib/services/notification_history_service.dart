import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationHistoryService {
  static const _key = 'notification_history';

  static Future<void> addEntry({
    required String title,
    required String body,
    required String type,
    required String refId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

    final now = DateTime.now();
    final alreadyExists = list.any((e) {
      if (e['refId'] != refId || e['type'] != type) return false;
      final ts = DateTime.tryParse(e['timestamp'] ?? '');
      if (ts == null) return false;
      return ts.year == now.year && ts.month == now.month && ts.day == now.day;
    });
    if (alreadyExists) return;

    list.insert(0, {
      'title': title,
      'body': body,
      'type': type,
      'refId': refId,
      'timestamp': now.toIso8601String(),
      'isRead': false,
    });

    if (list.length > 100) {
      list.removeRange(100, list.length);
    }

    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    try {
      final List data = jsonDecode(raw);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> markAsRead(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

    for (final e in list) {
      if (e['timestamp'] == timestamp) {
        e['isRead'] = true;
        break;
      }
    }

    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

    for (final e in list) {
      e['isRead'] = true;
    }

    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<int> getUnreadCount() async {
    final list = await getHistory();
    return list.where((e) => e['isRead'] != true).length;
  }

  static Future<void> deleteEntry(String timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();
    list.removeWhere((e) => e['timestamp'] == timestamp);
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}