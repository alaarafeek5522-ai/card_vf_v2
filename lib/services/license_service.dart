import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class LicenseResult {
  final bool success;
  final String? message;
  final bool isConnectionError;
  const LicenseResult({required this.success, this.message, this.isConnectionError = false});
}

class LicenseService {
  static const String _gistId = '2785cef01df36d14fa5ebada2e31ef09';
  static const String _fileName = 'keys_v2.json';
  static const String _savedKeyPref = 'saved_license_key_v2';
  static const String _savedDevicePref = 'saved_device_id_v2';

  static String get _token {
    final parts = ['g','h','p','_','x','O','R','p','k','E','8','H','M','g','T','t','v','W','5','O','k','L','v','y','G','j','b','E','y','5','o','5','p','e','4','c','O','n','6','H'];
    return parts.join();
  }

  static Future<String> _getLocalKeysPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  static Future<Map<String, dynamic>> _loadLocalKeys() async {
    try {
      final path = await _getLocalKeysPath();
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
    } catch (_) {}
    return {};
  }

  static Future<void> _saveLocalKeys(String content) async {
    try {
      final path = await _getLocalKeysPath();
      await File(path).writeAsString(content);
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> _fetchGist() async {
    final res = await http.get(
      Uri.parse('https://api.github.com/gists/$_gistId'),
      headers: {'Authorization': 'token $_token', 'Accept': 'application/vnd.github.v3+json'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Gist read failed');
    final data = jsonDecode(res.body);
    final content = data['files'][_fileName]['content'];
    await _saveLocalKeys(content);
    return Map<String, dynamic>.from(jsonDecode(content));
  }

  static Future<Map<String, dynamic>> _getKeysData() async {
    try {
      return await _fetchGist();
    } catch (_) {
      return _loadLocalKeys();
    }
  }

  static Future<void> _updateGist(Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('https://api.github.com/gists/$_gistId'),
      headers: {
        'Authorization': 'token $_token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'files': {_fileName: {'content': const JsonEncoder.withIndent('  ').convert(data)}}}),
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode < 200 || res.statusCode >= 300) throw Exception('Gist update failed');
    await _saveLocalKeys(const JsonEncoder.withIndent('  ').convert(data));
  }

  static Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_savedDevicePref);
    if (saved != null) return saved;
    final android = await DeviceInfoPlugin().androidInfo;
    await prefs.setString(_savedDevicePref, android.id);
    return android.id;
  }

  static LicenseResult? _checkExpiry(Map<String, dynamic> keyData) {
    final raw = keyData['expires_at']?.toString();
    if (raw == null || raw.isEmpty) return null;
    final expires = DateTime.tryParse(raw)?.toUtc();
    if (expires == null) return const LicenseResult(success: false, message: "بيانات المفتاح غير صحيحة");
    if (!DateTime.now().toUtc().isBefore(expires)) {
      return const LicenseResult(success: false, message: "⏳ انتهت مدة المفتاح.");
    }
    return null;
  }

  static Future<LicenseResult> activateKey(String key) async {
    try {
      final deviceId = await _getDeviceId();
      final gistData = await _getKeysData();
      final keys = gistData['keys'] as Map<String, dynamic>? ?? {};
      if (!keys.containsKey(key)) return const LicenseResult(success: false, message: "❌ المفتاح غير صحيح");
      final keyData = Map<String, dynamic>.from(keys[key]);
      if (keyData['active'] != true) return const LicenseResult(success: false, message: "🚫 المفتاح معطل");
      final existingDevice = keyData['device_id'];
      if (existingDevice != null && existingDevice != deviceId) {
        return const LicenseResult(success: false, message: "⚠️ المفتاح مستخدم على جهاز آخر");
      }
      if (keyData['registered_at'] == null && keyData['expires_at'] == null) {
        final now = DateTime.now().toUtc();
        final duration = keyData['duration'] ?? 30;
        final unit = keyData['unit'] ?? 'days';
        DateTime expires;
        switch (unit) {
          case 'hours': expires = now.add(Duration(hours: duration)); break;
          case 'weeks': expires = now.add(Duration(days: duration * 7)); break;
          default: expires = now.add(Duration(days: duration));
        }
        keyData['registered_at'] = now.toIso8601String();
        keyData['expires_at'] = expires.toIso8601String();
      }
      final expiryError = _checkExpiry(keyData);
      if (expiryError != null) return expiryError;
      keyData['device_id'] = deviceId;
      keys[key] = keyData;
      gistData['keys'] = keys;
      await _updateGist(gistData);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedKeyPref, key);
      return const LicenseResult(success: true);
    } catch (_) {
      return const LicenseResult(success: false, message: "خطأ في الاتصال", isConnectionError: true);
    }
  }

  static Future<LicenseResult> validateSavedKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_savedKeyPref);
      if (savedKey == null) return const LicenseResult(success: false);
      final deviceId = await _getDeviceId();
      final gistData = await _getKeysData();
      final keys = gistData['keys'] as Map<String, dynamic>? ?? {};
      if (!keys.containsKey(savedKey)) return const LicenseResult(success: false);
      final keyData = Map<String, dynamic>.from(keys[savedKey]);
      if (keyData['active'] != true) return const LicenseResult(success: false, message: "🚫 تم إيقاف المفتاح");
      final expiry = _checkExpiry(keyData);
      if (expiry != null) return expiry;
      if (keyData['device_id'] != deviceId) return const LicenseResult(success: false);
      return const LicenseResult(success: true);
    } catch (_) {
      return const LicenseResult(success: false, isConnectionError: true);
    }
  }

  static Future<String?> getSavedKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedKeyPref);
  }
}
