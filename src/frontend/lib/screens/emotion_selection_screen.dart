import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../services/content_service.dart';
import 'waiting_screen.dart';

class EmotionSelectionScreen extends StatefulWidget {
  final String sessionId;
  const EmotionSelectionScreen({super.key, required this.sessionId});

  @override
  State<EmotionSelectionScreen> createState() => _EmotionSelectionScreenState();
}

class _EmotionSelectionScreenState extends State<EmotionSelectionScreen> {
  // Dynamic Data
  final ContentService _contentService = ContentService();
  Map<String, dynamic> _vocabulary = {};
  bool _isLoading = true;

  final List<String> _selectedEmotions = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  Future<void> _loadVocabulary() async {
    final vocab = await _contentService.fetchVocabulary();
    if (mounted) {
      setState(() {
        _vocabulary = vocab;
        _isLoading = false;
      });
    }
  }

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

      // Save to Firestore
      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);
      
      await sessionRef
          .collection('participant_states')
          .doc(user.uid)
          .set({
        'emotions': _selectedEmotions,
        'status': 'emotions_selected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Orchestration: Check if both are ready
      final statesSnapshot = await sessionRef.collection('participant_states').get();
      final participants = statesSnapshot.docs;
      
      bool allReady = participants.length == 2 && 
          participants.every((doc) => doc.data()['status'] == 'emotions_selected');

      if (allReady) {
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

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Parse Feelings Data
    final feelingsData = _vocabulary['feelings'] as Map<String, dynamic>? ?? {};
    final categories = (feelingsData['categories'] as List<dynamic>?) ?? [];

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
              
              if (categories.isEmpty) const Text("No vocabulary loaded."),

              ...categories.map((cat) {
                final catName = cat['name'];
                final words = (cat['words'] as List<dynamic>).cast<String>();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(catName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: words.map((word) {
                        final isSelected = _selectedEmotions.contains(word);
                        return FilterChip(
                          label: Text(word),
                          selected: isSelected,
                          onSelected: (_) => _toggleEmotion(word),
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
                    const Divider(height: 32),
                  ],
                );
              }),

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