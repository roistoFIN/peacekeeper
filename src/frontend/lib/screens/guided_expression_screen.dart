import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'speaker_flow_screen.dart';
import 'shared_closing_screen.dart';
import 'start_screen.dart';
import '../services/content_service.dart';

class GuidedExpressionScreen extends StatefulWidget {
  final String sessionId;
  const GuidedExpressionScreen({super.key, required this.sessionId});

  @override
  State<GuidedExpressionScreen> createState() => _GuidedExpressionScreenState();
}

class _GuidedExpressionScreenState extends State<GuidedExpressionScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final ContentService _contentService = ContentService();
  
  String? _aiReflection;
  bool _isGeneratingReflection = false;

  // Timer logic (120s)
  int _secondsRemaining = 120;
  Timer? _timer;
  bool _timerStarted = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        // Time ran out! End session for both.
        if (mounted) {
          FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).update({'status': 'finished'});
        }
      }
    });
  }

  Future<void> _setListenerReady() async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({'listener_status': 'ready'});
  }

  Future<void> _quitSession() async {
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
  }

  Future<void> _startNextTurn(String currentSpeakerId, List<dynamic> participants, int turnsCompleted) async {
    if (turnsCompleted >= 1) {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .update({'status': 'shared_closing'});
      return;
    }

    final nextSpeaker = participants.firstWhere((id) => id != currentSpeakerId, orElse: () => '');

    if (nextSpeaker.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .update({
        'status': 'expression_phase',
        'current_speaker': nextSpeaker,
        'listener_status': 'waiting',
        'current_message': FieldValue.delete(),
        'turns_completed': FieldValue.increment(1),
      });
      setState(() {
        _aiReflection = null;
        _secondsRemaining = 120; // Reset timer for next turn
        _timerStarted = false;
      });
    }
  }

  Future<void> _getAIReflection(Map<String, dynamic> message) async {
    if (_aiReflection != null || _isGeneratingReflection) return;
    
    Future.microtask(() {
      if (mounted) setState(() => _isGeneratingReflection = true);
    });

    final result = await _contentService.generateReflection({
      'observation': message['observation'],
      'feelings': (message['emotions'] as List).join(", "),
      'needs': message['need'],
      'request': message['request'],
      'is_calm': true, 
    });

    if (mounted) {
      setState(() {
        _isGeneratingReflection = false;
        if (!result.hasError) _aiReflection = result.result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final sessionStatus = data['status'];

        // If other user quit
        if (sessionStatus == 'finished') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const StartScreen()), (route) => false);
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final currentSpeakerId = data['current_speaker'];
        final listenerStatus = data['listener_status'] ?? 'waiting';
        final participants = data['participants'] as List<dynamic>;
        final turnsCompleted = (data['turns_completed'] ?? 0) as int;
        final isSpeaker = _uid == currentSpeakerId;

        // Timer visibility: ONLY the active speaker sees the timer, and only during active expression
        final showTimer = isSpeaker && sessionStatus == 'expression_phase' && listenerStatus == 'ready';

        // Start/Stop timer based on active speaker status
        if (showTimer) {
          _startTimer();
        } else {
          _timer?.cancel();
          _timerStarted = false;
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (showTimer) ...[
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text("$_secondsRemaining s", style: const TextStyle(fontSize: 16)),
                ] else
                  const Text("Peacekeeper"),
              ],
            ),
            actions: [
              IconButton(onPressed: _quitSession, icon: const Icon(Icons.exit_to_app, color: Colors.red)),
            ],
            automaticallyImplyLeading: false,
          ),
          body: _buildContent(data, isSpeaker, listenerStatus, sessionStatus, currentSpeakerId, participants, turnsCompleted),
        );
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> data, bool isSpeaker, String listenerStatus, String sessionStatus, String currentSpeakerId, List<dynamic> participants, int turnsCompleted) {
    if (sessionStatus == 'shared_closing') return SharedClosingScreen(sessionId: widget.sessionId);

    if (sessionStatus == 'turn_complete') {
      return _buildTurnCompleteView(currentSpeakerId, participants, turnsCompleted);
    }

    if (isSpeaker) {
      if (sessionStatus == 'message_sent') return const Center(child: Text("Waiting for partner to reflect..."));
      return _buildSpeakerView(listenerStatus);
    } else {
      if (sessionStatus == 'message_sent') {
        final message = data['current_message'] as Map<String, dynamic>;
        _getAIReflection(message);
        return _buildReflectionView(message);
      }
      return _buildListenerView(listenerStatus);
    }
  }

  Widget _buildReflectionView(Map<String, dynamic> message) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Your partner shared:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildMessageBubble(message),
          const SizedBox(height: 40),
          const Text("Your response:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Read this out loud to show you understand.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          if (_isGeneratingReflection) 
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_aiReflection != null)
            _buildReflectionOption(_aiReflection!)
          else
            const Text("Preparing reflection...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message['observation'] ?? "", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text("I feel ${(message['emotions'] as List).join(' & ')}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 4),
          Text("because I need ${message['need']}.", style: const TextStyle(fontSize: 16, color: Colors.green)),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(message['request'] ?? "", style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildReflectionOption(String text) {
    return OutlinedButton(
      onPressed: () {
        FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).update({'status': 'turn_complete'});
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(20), 
        side: const BorderSide(color: Colors.blue, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
      ),
      child: Column(
        children: [
          Text(text, style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text("Click to confirm you've shared this", style: TextStyle(fontSize: 12, color: Colors.blue)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTurnCompleteView(String currentSpeakerId, List<dynamic> participants, int turnsCompleted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text("Turn Complete", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text("You stayed connected.", style: TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: () => _startNextTurn(currentSpeakerId, participants, turnsCompleted),
              child: Text(turnsCompleted >= 1 ? "Finish Session" : "Start Next Turn", style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListenerView(String status) {
    if (status != 'ready') {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.hearing, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 32),
            const Text("It's your turn to listen.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text("Listen without interrupting. You will get your turn later.", textAlign: TextAlign.center),
            const SizedBox(height: 48),
            FilledButton(onPressed: _setListenerReady, child: const Text("I'm ready to listen")),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text("Waiting for expression...", style: TextStyle(fontSize: 18, color: Colors.black54)),
          ],
        ),
      );
    }
  }

  Widget _buildSpeakerView(String listenerStatus) {
    if (listenerStatus != 'ready') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text("Waiting for partner...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text("They are preparing to listen.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
    } else {
      return SpeakerFlowScreen(sessionId: widget.sessionId);
    }
  }
}