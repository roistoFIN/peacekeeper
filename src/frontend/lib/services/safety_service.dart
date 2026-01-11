import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'debug_service.dart';

class SafetyService {
  String get _baseUrl {
    // 1. PRODUCTION (Release Build)
    if (kReleaseMode) {
      return 'https://peacekeeper-backend-c7fnii4s3a-uc.a.run.app';
    }

    // 2. DEVELOPMENT (Debug Mode)
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'https://peacekeeper-backend-c7fnii4s3a-uc.a.run.app';
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
        DebugService.error('Backend error: ${response.statusCode}');
        // Fallback: allow text if backend fails (or block, depending on policy)
        return SafetyCheckResult(isSafe: true, censoredText: text, flagged: false); 
      }
    } catch (e) {
      DebugService.error('Safety Check failed', e);
      // Fallback for demo if backend isn't running
      return SafetyCheckResult(isSafe: true, censoredText: text, flagged: false);
    }
  }

  bool validateLocalRules(String text, Map<String, dynamic>? rules) {
    if (rules == null) return false;
    
    // 1. Regex Patterns
    final patterns = rules['blame_patterns'] as List<dynamic>?;
    if (patterns != null) {
      for (final pattern in patterns) {
        try {
          var cleanPattern = pattern.toString();
          bool ignoreCase = false;
          if (cleanPattern.startsWith("(?i)")) {
             ignoreCase = true;
             cleanPattern = cleanPattern.substring(4);
          }
          if (RegExp(cleanPattern, caseSensitive: !ignoreCase).hasMatch(text)) {
            return true;
          }
        } catch (e) {
          DebugService.error("Invalid regex pattern: $pattern", e);
        }
      }
    }

    // 2. Violent Words
    final violentWords = rules['violent_words'] as List<dynamic>?;
    if (violentWords != null) {
      for (final word in violentWords) {
        final w = word.toString();
        if (RegExp(r'\b' + RegExp.escape(w) + r'\b', caseSensitive: false).hasMatch(text)) {
           return true;
        }
      }
    }
    
    return false;
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
