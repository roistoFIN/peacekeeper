import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'guided_expression_screen.dart';
import 'start_screen.dart';
import '../services/subscription_service.dart';
import 'paywall_screen.dart';

class WaitingScreen extends StatefulWidget {
  final String sessionId;
  const WaitingScreen({super.key, required this.sessionId});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremium();
    _listenForPhaseChange();
  }

  Future<void> _checkPremium() async {
    final status = await SubscriptionService.isPremium();
    if (mounted) setState(() => _isPremium = status);
  }

  void _listenForPhaseChange() {
    FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          if (data['status'] == 'expression_phase') {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GuidedExpressionScreen(sessionId: widget.sessionId),
                ),
              );
            }
          } else if (data['status'] == 'finished') {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const StartScreen()),
                (route) => false,
              );
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Peacekeeper: Couples Coach"),
        automaticallyImplyLeading: false,
        actions: [
          if (!_isPremium)
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen()));
                _checkPremium();
              },
              icon: const Icon(Icons.diamond, color: Colors.purple),
              label: const Text("Get Premium", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
            ),
          TextButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Quit Session?"),
                  content: const Text("This will end the conversation for both of you."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Quit", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed == true) {
                await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).update({'status': 'finished'});
              }
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 18),
            label: const Text("Quit", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Waiting for partner to finish..."),
          ],
        ),
      ),
    );
  }
}