import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'session_creation_screen.dart';
import 'join_session_screen.dart';
import 'feedback_screen.dart';
import 'paywall_screen.dart';
import 'regulation_screen.dart';
import '../services/subscription_service.dart';
import '../services/debug_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    DebugService.info("StartScreen initialized");
    _ensureAuthAndCheckPremium();
  }

  Future<void> _ensureAuthAndCheckPremium() async {
    // 1. Ensure Auth
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        DebugService.info("Performing anonymous sign-in...");
        await FirebaseAuth.instance.signInAnonymously();
        DebugService.info("Anonymous sign-in successful: ${FirebaseAuth.instance.currentUser?.uid}");
      } catch (e) {
        DebugService.error("Auth error", e);
      }
    } else {
      DebugService.info("User already authenticated: ${FirebaseAuth.instance.currentUser?.uid}");
    }
    
    // 2. Check Premium
    final status = await SubscriptionService.isPremium();
    DebugService.info("Premium Status: $status");
    if (mounted) setState(() => _isPremium = status);
  }

  Future<void> _createSoloSession() async {
    try {
      DebugService.info("Action: Creating Solo Session");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }
      if (user == null) throw Exception("Authentication failed");

      // Generate a unique ID for solo session (doesn't need to be 6-digit readable)
      final sessionId = "solo_${user.uid}_${DateTime.now().millisecondsSinceEpoch}";
      DebugService.info("Session ID generated: $sessionId");

      await FirebaseFirestore.instance.collection('sessions').doc(sessionId).set({
        'hostId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active', 
        'mode': 'solo',
        'participants': [user.uid],
        'current_speaker': user.uid,
      });

      // Initialize participant state
      await FirebaseFirestore.instance.collection('sessions').doc(sessionId)
          .collection('participant_states').doc(user.uid).set({
        'status': 'joined',
      });

      if (mounted) {
        DebugService.info("Solo Session created successfully. Navigating...");
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegulationScreen(sessionId: sessionId),
          ),
        );
      }
    } catch (e) {
      DebugService.error("Solo Session creation failed", e);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showAppInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).primaryColor, size: 28),
                  const SizedBox(width: 12),
                  const Text("About Peacekeeper", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Purpose", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Peacekeeper is a self-help conflict coaching tool designed to help couples de-escalate arguments in real-time. It guides you through a structured process to slow down the conversation and reduce impulsive reactions.",
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              const Text("Scientific Basis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "The application is built on proven frameworks for effective communication and emotional regulation:",
                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              _buildBulletPoint("Gottman Method (Flooding & Repair)"),
              _buildBulletPoint("Polyvagal Theory (Nervous System Regulation)"),
              _buildBulletPoint("Emotionally Focused Therapy (EFT)"),
              _buildBulletPoint("Nonviolent Communication (NVC)"),
              _buildBulletPoint("CBT-lite (Interrupting Distortions)"),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text("LEGAL DISCLAIMER", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "This application is NOT a substitute for professional therapy or counseling. It is a communication tool to help you discuss difficult topics more safely. If you are in immediate danger or fear for your safety, please contact emergency services immediately.",
                      style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isPremium
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Center(
                    child: Text("Premium enabled", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                )
              : TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen()));
                    _ensureAuthAndCheckPremium();
                  },
                  icon: const Icon(Icons.diamond, color: Colors.purple),
                  label: const Text("Get Premium", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackScreen())),
            icon: const Icon(Icons.feedback_outlined, color: Colors.blueGrey),
            tooltip: 'Send Feedback',
          ),
          IconButton(
            onPressed: () => _showAppInfo(context),
            icon: const Icon(Icons.info_outline, color: Colors.blueGrey),
            tooltip: 'About this app',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Peacekeeper: Couples Coach',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SessionCreationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'SOS – Conflict happening now',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinSessionScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'Join an ongoing conversation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _createSoloSession,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  'Guide me to express my feelings, needs and request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'This app helps you speak and listen more safely.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
