import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SessionCreationScreen extends StatefulWidget {
  const SessionCreationScreen({super.key});

  @override
  State<SessionCreationScreen> createState() => _SessionCreationScreenState();
}

class _SessionCreationScreenState extends State<SessionCreationScreen> {
  String? conflictCode;
  String status = "initializing"; // initializing, waiting, connected

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    try {
      // 1. Ensure user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }

      if (user == null) throw Exception("Authentication failed");

      // 2. Generate Code
      final code = _generateConflictCode();

      // 3. Create Session in Firestore
      // We use the code as the document ID for easy lookup by the joiner
      await FirebaseFirestore.instance.collection('sessions').doc(code).set({
        'hostId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting_for_partner', // initial state
        'participants': [user.uid],
      });

      if (mounted) {
        setState(() {
          conflictCode = code;
          status = "waiting";
        });
      }

      // 4. Listen for partner joining
      FirebaseFirestore.instance
          .collection('sessions')
          .doc(code)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['status'] == 'active') {
             // TODO: Navigate to the next phase (Shared Regulation)
             if (mounted) {
               setState(() {
                 status = "connected";
               });
               // Navigation would happen here
             }
          }
        }
      });

    } catch (e) {
      debugPrint("Error creating session: $e");
      // Handle error (show snackbar, etc.)
    }
  }

  String _generateConflictCode() {
    var rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (conflictCode == null) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 20),
                const Text(
                  'Creating secure session...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ] else ...[
                const Text(
                  'Your Conflict Code',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    conflictCode!,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                const Text(
                  'Ask the other person to join this conversation.',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                status == "connected" 
                  ? const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 8),
                        Text("Partner Connected!", style: TextStyle(fontWeight: FontWeight.bold))
                      ],
                    )
                  : const Column(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Waiting for partner...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
