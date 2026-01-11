import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'debug_service.dart';

class ContentService {
  String get _baseUrl {
    // 1. PRODUCTION (Release Build)
    if (kReleaseMode) {
      return 'https://peacekeeper-backend-c7fnii4s3a-uc.a.run.app'; // Update this after deployment if needed
    }

    // 2. DEVELOPMENT (Debug Mode)
    if (kIsWeb) return 'http://127.0.0.1:8000';
    // Use Production Backend for Android Dev to support real devices without adb reverse
    if (Platform.isAndroid) return 'https://peacekeeper-backend-c7fnii4s3a-uc.a.run.app';
    return 'http://127.0.0.1:8000';
  }

  Future<Map<String, dynamic>> fetchVocabulary() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/content/vocabulary'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      DebugService.error("Error fetching vocab", e);
      return {};
    }
  }

  // --- AI Endpoints ---

  Future<AIResult> neutralizeObservation(String text) async {
    return _callAI('/ai/neutralize-observation', text);
  }

  Future<AIResult> suggestFeelings(String observation) async {
    return _callAI('/ai/suggest-feelings', observation);
  }

  Future<AIResult> suggestNeeds(String observation, List<String> feelings) async {
    return _callAI('/ai/suggest-needs', observation, context: {'feelings': feelings.join(", ")});
  }

  Future<AIResult> refineRequest(String request, Map<String, dynamic> context) async {
    return _callAI('/ai/refine-request', request, context: context);
  }

  Future<AIResult> generateReflection(Map<String, dynamic> context) async {
    return _callAI('/ai/generate-reflection', "", context: context);
  }

  Future<AIResult> _callAI(String path, String text, {Map<String, dynamic>? context}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return AIResult(error: "User not authenticated");

    try {
      final token = await user.getIdToken();
      DebugService.info(">>> AI REQUEST: $path");
      DebugService.log(">>> TEXT: $text");
      
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': user.uid,
          'text': text,
          'context': context,
        }),
      );

      DebugService.info("<<< AI RESPONSE ($path): ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        DebugService.log("<<< RESULT: ${data['result']}");
        return AIResult(
          result: data['result'],
          alternatives: data['alternatives'] != null ? List<String>.from(data['alternatives']) : null,
          isOffensive: data['is_offensive'] ?? false,
        );
      } else {
        DebugService.error("<<< ERROR BODY: ${response.body}");
        if (response.statusCode == 429) {
          final data = jsonDecode(response.body);
          return AIResult(error: "Rate limited", retryAfter: data['detail']['retry_after']);
        }
        return AIResult(error: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      DebugService.error("!!! AI EXCEPTION", e);
      return AIResult(error: e.toString());
    }
  }
}

class AIResult {

  final dynamic result;

  final List<String>? alternatives;

  final bool isOffensive;

  final String? error;

  final int? retryAfter;



  AIResult({this.result, this.alternatives, this.isOffensive = false, this.error, this.retryAfter});



  bool get hasError => error != null;

}
