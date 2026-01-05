import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SafetyService {
  // Use 10.0.2.2 for Android Emulator, localhost for others
  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  Future<SafetyCheckResult> checkText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze/safety'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SafetyCheckResult(
          isSafe: data['is_safe'] ?? true,
          censoredText: data['censored_text'] ?? text,
          flagged: data['flagged'] ?? false,
        );
      } else {
        debugPrint('Backend error: ${response.statusCode}');
        // Fallback: allow text if backend fails (or block, depending on policy)
        return SafetyCheckResult(isSafe: true, censoredText: text, flagged: false); 
      }
    } catch (e) {
      debugPrint('Safety Check failed: $e');
      // Fallback for demo if backend isn't running
      return SafetyCheckResult(isSafe: true, censoredText: text, flagged: false);
    }
  }
}

class SafetyCheckResult {
  final bool isSafe;
  final String censoredText;
  final bool flagged;

  SafetyCheckResult({
    required this.isSafe,
    required this.censoredText,
    required this.flagged,
  });
}
