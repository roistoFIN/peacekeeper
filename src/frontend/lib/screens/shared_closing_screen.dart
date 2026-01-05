import 'package:flutter/material.dart';

class SharedClosingScreen extends StatelessWidget {
  final String sessionId;
  const SharedClosingScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handshake_outlined, size: 80, color: Colors.blueGrey),
                const SizedBox(height: 32),
                const Text(
                  "You may not have solved everything.",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  "But you stayed connected.",
                  style: TextStyle(fontSize: 20, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                const Text(
                  "Emotions present in this conversation:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // TODO: Fetch and display actual emotions from Firestore history if desired
                const Text(
                  "– vulnerability\n– hope", // Placeholder
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                OutlinedButton(
                  onPressed: () {
                    // Navigate back to start (simulating app restart)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text("Return to Start"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
