import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'start_screen.dart';
import 'feedback_screen.dart';

class SharedClosingScreen extends StatefulWidget {
  final String sessionId;
  const SharedClosingScreen({super.key, required this.sessionId});

  @override
  State<SharedClosingScreen> createState() => _SharedClosingScreenState();
}

class _SharedClosingScreenState extends State<SharedClosingScreen> {
  int? _selectedRating;

  Future<List<String>> _fetchEmotions() async {
    try {
      print("DEBUG: Fetching emotions for session: ${widget.sessionId}");
      final snapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
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

  Future<void> _rateSession(int rating) async {
    setState(() => _selectedRating = rating);
    
    // 1. Save rating
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
         await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).set({
           'ratings': {uid: rating}
         }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error saving rating: $e");
    }

    // 2. Logic: If 1 star, open feedback
    if (rating == 1) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FeedbackScreen(sessionId: widget.sessionId, initialRating: rating)),
        );
      }
    } else {
      // Show simple thanks
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Thank you for your rating!")),
        );
      }
    }
  }

  Future<void> _endSession(BuildContext context) async {
    // Return to start for this user only
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
      appBar: AppBar(
        title: const Text("Peacekeeper: Couples Coach"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FeedbackScreen(sessionId: widget.sessionId))),
            icon: const Icon(Icons.feedback_outlined, color: Colors.blueGrey),
            tooltip: 'Send Feedback',
          ),
          const SizedBox(width: 16),
        ],
      ),
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
                
                const SizedBox(height: 48),
                const Text("How helpful was this session?", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starRating = index + 1;
                    return IconButton(
                      onPressed: () => _rateSession(starRating),
                      icon: Icon(
                        _selectedRating != null && starRating <= _selectedRating! ? Icons.star : Icons.star_border,
                        size: 36,
                        color: Colors.amber,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 48),
                
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