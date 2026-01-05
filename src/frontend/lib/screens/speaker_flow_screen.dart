import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/content_service.dart';

class SpeakerFlowScreen extends StatefulWidget {
  final String sessionId;
  const SpeakerFlowScreen({super.key, required this.sessionId});

  @override
  State<SpeakerFlowScreen> createState() => _SpeakerFlowScreenState();
}

class _SpeakerFlowScreenState extends State<SpeakerFlowScreen> {
  final PageController _pageController = PageController();
  final ContentService _contentService = ContentService();
  int _currentStep = 0;
  bool _isLoading = true;

  // Data
  Map<String, dynamic> _vocabulary = {};
  
  // User Selections
  final TextEditingController _observationController = TextEditingController();
  final List<String> _selectedFeelings = [];
  final List<String> _selectedNeeds = []; // Changed from single selection
  final TextEditingController _requestController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vocab = await _contentService.fetchVocabulary();
    
    // Fetch pre-selected emotions from Phase 1
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .collection('participant_states')
        .doc(uid)
        .get();

    final preSelectedEmotions = userDoc.exists 
        ? List<String>.from(userDoc.data()?['emotions'] ?? []) 
        : <String>[];

    if (mounted) {
      setState(() {
        _vocabulary = vocab;
        _selectedFeelings.addAll(preSelectedEmotions);
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentStep++;
    });
  }

  // STEP 1 VALIDATION
  Future<void> _validateAndContinueStep1() async {
    final text = _observationController.text.trim();
    if (text.isEmpty) return;

    // Show loading indicator on button? (omitted for brevity)
    final result = await _contentService.validateObservation(text);
    
    if (!result.isValid && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result.reason ?? "Optimization Suggestion"),
          content: Text(result.suggestion ?? "Please rephrase to avoid judgment."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Edit"),
            ),
          ],
        ),
      );
    } else {
      _nextPage();
    }
  }

  Future<void> _sendMessage() async {
    final fullMessage = {
      'observation': _observationController.text,
      'emotions': _selectedFeelings,
      'need': _selectedNeeds.join(", "),
      'request': _requestController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).update({
      'current_message': fullMessage,
      'status': 'message_sent',
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        LinearProgressIndicator(value: (_currentStep + 1) / 4),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildObservationStep(),
              _buildSelectionStep(
                title: "How do you feel?",
                subtitle: "Select the words that best describe your experience.",
                dataKey: 'feelings',
                selectedItems: _selectedFeelings,
                maxItems: 3,
                onContinue: _nextPage,
              ),
              _buildSelectionStep(
                title: "What do you need?",
                subtitle: "Select the values that are important to you right now.",
                dataKey: 'needs',
                selectedItems: _selectedNeeds,
                maxItems: 2,
                onContinue: _nextPage,
              ),
              _buildRequestStep(),
              _buildPreviewStep(),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 1: Observation
  Widget _buildObservationStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Step 1: Observation", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("What happened?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Describe it like a video camera – just the facts.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          TextField(
            controller: _observationController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'When I saw...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _validateAndContinueStep1,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  // GENERIC SELECTION STEP (Used for Feelings & Needs)
  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required String dataKey,
    required List<String> selectedItems,
    required int maxItems,
    required VoidCallback onContinue,
  }) {
    // Parse vocabulary data safely
    final sectionData = _vocabulary[dataKey] as Map<String, dynamic>? ?? {};
    final categories = (sectionData['categories'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
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
                  child: Text(catName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: words.map((word) {
                    final isSelected = selectedItems.contains(word);
                    return FilterChip(
                      label: Text(word),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            if (selectedItems.length < maxItems) selectedItems.add(word);
                          } else {
                            selectedItems.remove(word);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const Divider(),
              ],
            );
          }),

          const SizedBox(height: 20),
          FilledButton(
            onPressed: selectedItems.isNotEmpty ? onContinue : null,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  // STEP 4: Request
  Widget _buildRequestStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Step 4: Request", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("What would help?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Make a positive, doable request.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          TextField(
            controller: _requestController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Would you be willing to...', 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _nextPage,
            child: const Text("Preview"),
          ),
        ],
      ),
    );
  }

  // PREVIEW
  Widget _buildPreviewStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Review Message", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 18, color: Colors.black87, height: 1.5),
                children: [
                  const TextSpan(text: "When "),
                  TextSpan(text: _observationController.text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: ",\nI feel "),
                  TextSpan(text: _selectedFeelings.join(" & "), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const TextSpan(text: "\nbecause I need "),
                  TextSpan(text: _selectedNeeds.join(" & "), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  const TextSpan(text: ".\n\n"),
                  const TextSpan(text: "Would you be willing to "),
                  TextSpan(text: _requestController.text, style: const TextStyle(fontStyle: FontStyle.italic)),
                  const TextSpan(text: "?"),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _sendMessage,
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Send Message"),
          ),
        ],
      ),
    );
  }
}