import 'package:flutter/foundation.dart';

class DebugService {
  // Global switch to toggle logging
  static bool isEnabled = false;

  static void log(String message) {
    if (isEnabled) {
      debugPrint("🔵 [INFO] $message");
    }
  }

  static void error(String message, [dynamic error]) {
    if (isEnabled) {
      debugPrint("🔴 [ERROR] $message ${error != null ? ': $error' : ''}");
    }
  }

  static void info(String message) {
    if (isEnabled) {
      debugPrint("🟢 [DEBUG] $message");
    }
  }
}
