import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'speaker_flow_screen.dart'; 
import 'shared_closing_screen.dart';

class GuidedExpressionScreen extends StatefulWidget {
  final String sessionId;
  const GuidedExpressionScreen({super.key, required this.sessionId});

  @override
  State<GuidedExpressionScreen> createState() => _GuidedExpressionScreenState();
}

class _GuidedExpressionScreenState extends State<GuidedExpressionScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _setListenerReady() async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({'listener_status': 'ready'});
  }

  Future<void> _startNextTurn(String currentSpeakerId, List<dynamic> participants, int turnsCompleted) async {
    if (turnsCompleted >= 1) {
      // Both have spoken (0 -> 1 -> 2)
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .update({'status': 'shared_closing'});
      return;
    }

    // Find the other participant
    final nextSpeaker = participants.firstWhere(
      (id) => id != currentSpeakerId,
      orElse: () => '',
    );

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final currentSpeakerId = data['current_speaker'];
          final listenerStatus = data['listener_status'] ?? 'waiting';
          final sessionStatus = data['status'];
          final participants = data['participants'] as List<dynamic>;
          final turnsCompleted = (data['turns_completed'] ?? 0) as int;
          final isSpeaker = _uid == currentSpeakerId;

          if (sessionStatus == 'shared_closing') {
             return SharedClosingScreen(sessionId: widget.sessionId);
          }

          if (sessionStatus == 'turn_complete') {
            return Scaffold(
              body: Center(
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
                         style: FilledButton.styleFrom(
                           padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                         ),
                         child: Text(
                           turnsCompleted >= 1 ? "Finish Session" : "Start Next Turn", 
                           style: const TextStyle(fontSize: 18)
                         ),
                       ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (isSpeaker) {
            if (sessionStatus == 'message_sent') {
               return const Center(child: Text("Waiting for partner to reflect..."));
            }
            return _buildSpeakerView(listenerStatus);
          } else {
            if (sessionStatus == 'message_sent') {
               return _buildReflectionView(data['current_message']);
            }
            return _buildListenerView(listenerStatus);
          }
        },
      ),
    );
  }

  Widget _buildReflectionView(Map<String, dynamic>? message) {
    if (message == null) return const SizedBox();

    // Extract emotions for the reflection options
    final emotions = List<String>.from(message['emotions'] ?? []);
    final primaryEmotion = emotions.isNotEmpty ? emotions.first : '...';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Partner says:", style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("When ${message['observation']}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text("I feel ${emotions.join(' & ')}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("because I need ${message['need']}.", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text("Reflect back what you heard:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          _buildReflectionOption("I heard that you are feeling $primaryEmotion."),
          const SizedBox(height: 12),
          _buildReflectionOption("I understand this made you feel $primaryEmotion."),
          const SizedBox(height: 12),
          _buildReflectionOption("It sounds like you are feeling $primaryEmotion."),
        ],
      ),
    );
  }

  Widget _buildReflectionOption(String text) {
    return OutlinedButton(
      onPressed: () {
        // TODO: Complete the turn (Phase 6)
        // For now, just show a dialog or reset
        FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .update({'status': 'turn_complete'}); // Placeholder status
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
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
            const Text(
              "It's your turn to listen.",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Prepare yourself to listen without interrupting. You will get your turn to speak later.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton(
              onPressed: _setListenerReady,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "I'm ready to listen",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 60, color: Colors.grey),
            SizedBox(height: 24),
            Text(
              "Listening...",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                "The other person is composing their message. Please wait.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
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
              Text(
                "Waiting for partner...",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                "They are preparing to listen. You can start speaking once they are ready.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    } else {
      // Listener is ready, show the Speaker Flow
      return SpeakerFlowScreen(sessionId: widget.sessionId);
    }
  }
}