import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ContentService {
  String get _baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  // Fetch Feelings and Needs from Backend (which pulls from Firestore)
  Future<Map<String, dynamic>> fetchVocabulary() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/content/vocabulary'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("Error fetching vocab: $e");
      return {};
    }
  }

  // Validate Step 1: Observation
  Future<ValidationResult> validateObservation(String text) async {
    return _validateEndpoint('/validate/observation', text);
  }

  // Validate Step 2: Feelings (Check for pseudo-feelings)
  Future<ValidationResult> validateFeelingText(String text) async {
    return _validateEndpoint('/validate/feelings', text);
  }

  Future<ValidationResult> _validateEndpoint(String endpoint, String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ValidationResult(
          isValid: data['is_valid'] ?? true,
          reason: data['reason'],
          suggestion: data['suggestion'],
        );
      }
    } catch (e) {
      debugPrint("Validation error: $e");
    }
    // Default to valid if server is unreachable (fail open for prototype)
    return ValidationResult(isValid: true);
  }
}

class ValidationResult {
  final bool isValid;
  final String? reason;
  final String? suggestion;

  ValidationResult({required this.isValid, this.reason, this.suggestion});
}
