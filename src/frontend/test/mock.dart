import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';

typedef Callback = void Function(MethodCall call);

class MockFirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return FirebaseAppPlatform(
      name ?? '[DEFAULT]',
      options ?? const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }

  @override
  List<FirebaseAppPlatform> get apps => [];

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: '123',
        appId: '123',
        messagingSenderId: '123',
        projectId: '123',
      ),
    );
  }
}

void setupFirebaseAuthMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1. Install the Mock Platform Interface
  FirebasePlatform.instance = MockFirebasePlatform();

  // 2. Mock Auth MethodChannel (Legacy but still needed for FirebaseAuth.instance)
  const MethodChannel authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    authChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'Auth#signInAnonymously') {
        return {
          'user': {'uid': 'test_uid', 'isAnonymous': true},
          'additionalUserInfo': {},
        };
      }
      if (methodCall.method == 'Auth#authStateChanges') {
        return null;
      }
      return null;
    }
  );
}
