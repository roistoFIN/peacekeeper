import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'waiting_screen.dart';

class RegulationScreen extends StatefulWidget {
  final String sessionId;
  const RegulationScreen({super.key, required this.sessionId});

  @override
  State<RegulationScreen> createState() => _RegulationScreenState();
}

class _RegulationScreenState extends State<RegulationScreen> with SingleTickerProviderStateMixin {
  int _secondsRemaining = 1; // TEMPORARY: Reduced for testing (original: 60)
  Timer? _timer;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);

      // 1. Mark myself as ready
      await sessionRef.collection('participant_states').doc(user.uid).set({
        'status': 'regulation_complete',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Check if everyone is ready
      final statesSnapshot = await sessionRef.collection('participant_states').get();
      final participants = statesSnapshot.docs;
      
      // We expect 2 participants. Check if all are 'regulation_complete'
      final allReady = participants.length == 2 && 
          participants.every((doc) => doc.data()['status'] == 'regulation_complete');

      if (allReady) {
        // Pick random speaker and start expression phase
        final speakerId = participants[Random().nextInt(participants.length)].id;
        await sessionRef.update({
          'status': 'expression_phase',
          'current_speaker': speakerId,
          'phase_start_time': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WaitingScreen(sessionId: widget.sessionId)),
        );
      }

    } catch (e) {
      debugPrint("Error in regulation continue: $e");
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Breathe together', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text('When the body calms down, conversation becomes possible.', style: TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
              const SizedBox(height: 80),
              Center(
                child: AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 150 * _breathingAnimation.value,
                      height: 150 * _breathingAnimation.value,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                      child: Center(
                        child: Container(
                          width: 100, 
                          height: 100, 
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.primary.withOpacity(0.5))
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 80),
              Text('$_secondsRemaining', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300, fontFeatures: [FontFeature.tabularFigures()])),
              const Text('seconds', style: TextStyle(fontSize: 16, color: Colors.black54)),
              const Spacer(),
              ElevatedButton(
                onPressed: (_secondsRemaining == 0 && !_isProcessing) ? _handleContinue : null,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Continue'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}