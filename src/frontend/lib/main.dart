import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'screens/start_screen.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';
import 'services/debug_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize App Check
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
        // In development/test, this will fail on Web without a valid key/registration.
        // We catch it so the app doesn't crash.
        webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
      );
    } catch (e) {
      DebugService.error("App Check init failed (expected in dev without valid keys)", e);
    }

    await SubscriptionService.init();
    await AdService.init();
  } catch (e) {
    DebugService.error("Initialization error", e);
    // This allows the app to run on Linux/Web even if config is missing,
    // though Auth/Firestore features will likely fail when used.
  }

  runApp(const PeacekeeperApp());
}

class PeacekeeperApp extends StatelessWidget {
  const PeacekeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peacekeeper: Couples Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ),
      ),
      home: const StartScreen(),
    );
  }
}
