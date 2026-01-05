import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'guided_expression_screen.dart';

class WaitingScreen extends StatefulWidget {
  final String sessionId;
  const WaitingScreen({super.key, required this.sessionId});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  @override
  void initState() {
    super.initState();
    _listenForPhaseChange();
  }

  void _listenForPhaseChange() {
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['status'] == 'expression_phase') {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GuidedExpressionScreen(sessionId: widget.sessionId),
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text("Waiting for partner to finish..."),
          ],
        ),
      ),
    );
  }
}