import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const PeacekeeperApp());
}

class PeacekeeperApp extends StatelessWidget {
  const PeacekeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peacekeeper',
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
