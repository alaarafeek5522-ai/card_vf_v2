import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRecord {
  final String phone;
  final String cardName;
  final String netCharge;
  final bool success;
  final DateTime date;
  final String? productId;

  HistoryRecord({
    required this.phone,
    required this.cardName,
    required this.netCharge,
    required this.success,
    required this.date,
    this.productId,
  });

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'card': cardName,
    'charge': netCharge,
    'success': success,
    'date': date.toIso8601String(),
    'productId': productId,
  };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
    phone: json['phone'] ?? '',
    cardName: json['card'] ?? '',
    netCharge: json['charge'] ?? '',
    success: json['success'] == true,
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    productId: json['productId'],
  );
}

class HistoryService {
  static const String _key = 'charge_history_v2';

  static Future<List<HistoryRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => HistoryRecord.fromJson(e)).toList();
  }

  static Future<void> addRecord({
    required String phone,
    required String cardName,
    required String netCharge,
    required bool success,
    String? productId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, HistoryRecord(
      phone: phone,
      cardName: cardName,
      netCharge: netCharge,
      success: success,
      date: DateTime.now(),
      productId: productId,
    ));
    if (history.length > 100) history.removeLast();
    await prefs.setString(_key, jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  static Future<String?> getLastReceiver() async {
    final history = await getHistory();
    if (history.isEmpty) return null;
    return history.first.phone;
  }

  static Future<List<HistoryRecord>> getFavorites() async {
    final history = await getHistory();
    final phoneCounts = <String, int>{};
    for (final h in history) {
      phoneCounts[h.phone] = (phoneCounts[h.phone] ?? 0) + 1;
    }
    final sorted = phoneCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => history.firstWhere((h) => h.phone == e.key)).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final history = await getHistory();
    final successful = history.where((h) => h.success).length;
    final failed = history.where((h) => !h.success).length;
    final totalAmount = history.where((h) => h.success).fold(0.0, (sum, h) => sum + (double.tryParse(h.netCharge) ?? 0));
    return {
      'total': history.length,
      'successful': successful,
      'failed': failed,
      'totalAmount': totalAmount.toStringAsFixed(2),
    };
  }
}
