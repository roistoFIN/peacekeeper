import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/start_screen.dart';
import 'services/subscription_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await SubscriptionService.init();
    await AdService.init();
  } catch (e) {
    debugPrint("Initialization error: $e");
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
