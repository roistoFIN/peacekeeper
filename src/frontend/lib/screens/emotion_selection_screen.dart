import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../services/safety_service.dart';
import 'waiting_screen.dart';

class EmotionSelectionScreen extends StatefulWidget {
  final String sessionId;
  const EmotionSelectionScreen({super.key, required this.sessionId});

  @override
  State<EmotionSelectionScreen> createState() => _EmotionSelectionScreenState();
}

class _EmotionSelectionScreenState extends State<EmotionSelectionScreen> {
  final List<String> _emotions = [
    'Angry',
    'Hurt',
    'Unsafe',
    'Disappointed',
    'Lonely',
    'Confused',
    'I don\'t know',
    'I don\'t want to say'
  ];

  final List<String> _selectedEmotions = [];
  final TextEditingController _fearController = TextEditingController();
  bool _isSubmitting = false;
  final SafetyService _safetyService = SafetyService();

  void _toggleEmotion(String emotion) {
    setState(() {
      if (_selectedEmotions.contains(emotion)) {
        _selectedEmotions.remove(emotion);
      } else {
        if (_selectedEmotions.length < 2) {
          _selectedEmotions.add(emotion);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedEmotions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one emotion.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("No user found");

      String fearText = _fearController.text.trim();
      
      // Safety Check
      if (fearText.isNotEmpty) {
        final safetyResult = await _safetyService.checkText(fearText);
        if (safetyResult.flagged) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Language unsafe. Suggestion: "${safetyResult.censoredText}"'),
                 backgroundColor: Colors.red,
               ),
             );
             setState(() {
               _isSubmitting = false;
             });
             return;
           }
        }
      }

      // Save to Firestore
      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);
      
      await sessionRef
          .collection('participant_states')
          .doc(user.uid)
          .set({
        'emotions': _selectedEmotions,
        'fear': fearText,
        'status': 'emotions_selected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Orchestration: Check if both are ready
      final statesSnapshot = await sessionRef.collection('participant_states').get();
      final participants = statesSnapshot.docs;
      
      // We expect 2 participants. If both have 'status' == 'emotions_selected', we proceed.
      bool allReady = participants.length == 2 && 
          participants.every((doc) => doc.data()['status'] == 'emotions_selected');

      if (allReady) {
        // Randomly pick who speaks first
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
      debugPrint("Error submitting: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving selection. Please try again.')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Feelings'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'How are you feeling right now?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select up to 2 emotions.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _emotions.map((emotion) {
                  final isSelected = _selectedEmotions.contains(emotion);
                  return FilterChip(
                    label: Text(emotion),
                    selected: isSelected,
                    onSelected: (_) => _toggleEmotion(emotion),
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.onPrimaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected 
                        ? theme.colorScheme.onPrimaryContainer 
                        : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              const Text(
                'What is the biggest fear right now?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fearController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., I am afraid that...', 
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}