import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AppControlService {
  static const String _gistId = '2785cef01df36d14fa5ebada2e31ef09';
  static const String _fileName = 'keys_v2.json';

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
      headers: {
        'Authorization': 'token $_token',
        'Accept': 'application/vnd.github.v3+json',
      },
    ).timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body);
    final content = data['files'][_fileName]['content'];
    await _saveLocalKeys(content);
    return jsonDecode(content);
  }

  static Future<Map<String, dynamic>> _getKeysData() async {
    try {
      return await _fetchGist();
    } catch (_) {
      return _loadLocalKeys();
    }
  }

  static Future<AppControlResult> fetchControl() async {
    try {
      final json = await _getKeysData();
      final ctrl = json['app_control'] as Map<String, dynamic>? ?? {};
      return AppControlResult(
        forceStop: ctrl['force_stop'] == true,
        forceStopMsg: ctrl['force_stop_msg']?.toString() ?? 'التطبيق موقوف مؤقتاً',
        forceUpdate: ctrl['force_update'] == true,
        forceUpdateMsg: ctrl['force_update_msg']?.toString() ?? 'يوجد تحديث جديد',
        updateUrl: ctrl['update_url']?.toString() ?? '',
        message: ctrl['message']?.toString() ?? '',
        messageTitle: ctrl['message_title']?.toString() ?? 'تنبيه',
      );
    } catch (_) {
      return AppControlResult.empty();
    }
  }
}

class AppControlResult {
  final bool forceStop;
  final String forceStopMsg;
  final bool forceUpdate;
  final String forceUpdateMsg;
  final String updateUrl;
  final String message;
  final String messageTitle;

  AppControlResult({
    required this.forceStop,
    required this.forceStopMsg,
    required this.forceUpdate,
    required this.forceUpdateMsg,
    required this.updateUrl,
    required this.message,
    required this.messageTitle,
  });

  factory AppControlResult.empty() => AppControlResult(
    forceStop: false,
    forceStopMsg: '',
    forceUpdate: false,
    forceUpdateMsg: '',
    updateUrl: '',
    message: '',
    messageTitle: '',
  );

  bool get hasMessage => message.isNotEmpty;
}
