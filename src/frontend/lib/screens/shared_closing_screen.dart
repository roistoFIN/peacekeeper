import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'start_screen.dart';

class SharedClosingScreen extends StatelessWidget {
  final String sessionId;
  const SharedClosingScreen({super.key, required this.sessionId});

  Future<List<String>> _fetchEmotions() async {
    try {
      print("DEBUG: Fetching emotions for session: $sessionId");
      final snapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('participant_states')
          .get();

      print("DEBUG: Found ${snapshot.docs.length} participant docs");
      final Set<String> allEmotions = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print("DEBUG: Doc ${doc.id} emotions: ${data['emotions']}");
        if (data['emotions'] != null) {
          final List<dynamic> emotions = data['emotions'];
          allEmotions.addAll(emotions.cast<String>());
        }
      }
      return allEmotions.toList();
    } catch (e) {
      print("DEBUG: Error fetching emotions: $e");
      return [];
    }
  }

  Future<void> _endSession(BuildContext context) async {
    // 1. Mark session as finished (invalidating the code effectively)
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .update({'status': 'finished'});

    // 2. Return to start
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const StartScreen()),
        (route) => false,
      );
    }
  }

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
                
                // Dynamic Emotion List
                FutureBuilder<List<String>>(
                  future: _fetchEmotions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text("–", style: TextStyle(color: Colors.grey));
                    }
                    
                    return Column(
                      children: snapshot.data!.map((emotion) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          "– $emotion",
                          style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.black87),
                        ),
                      )).toList(),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                FilledButton(
                  onPressed: () => _endSession(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.blueGrey,
                  ),
                  child: const Text("Thank you for trying", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}