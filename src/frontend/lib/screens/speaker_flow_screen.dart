import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/safety_service.dart';

class SpeakerFlowScreen extends StatefulWidget {
  final String sessionId;
  const SpeakerFlowScreen({super.key, required this.sessionId});

  @override
  State<SpeakerFlowScreen> createState() => _SpeakerFlowScreenState();
}

class _SpeakerFlowScreenState extends State<SpeakerFlowScreen> {
  final PageController _pageController = PageController();
  final SafetyService _safetyService = SafetyService();
  int _currentStep = 0;

  // Data Holders
  final TextEditingController _observationController = TextEditingController();
  List<dynamic> _myEmotions = [];
  String? _selectedNeed;
  final TextEditingController _requestController = TextEditingController();

  final List<String> _needs = [
    'to be heard',
    'to receive support',
    'to feel safe',
    'to feel appreciated',
    'to gain clarity',
    'autonomy',
    'connection'
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyEmotions();
  }

  Future<void> _fetchMyEmotions() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .collection('participant_states')
        .doc(uid)
        .get();
    
    if (doc.exists && mounted) {
      setState(() {
        _myEmotions = doc.data()?['emotions'] ?? [];
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

  Future<void> _sendMessage() async {
    // Basic validation
    if (_observationController.text.isEmpty || _selectedNeed == null || _requestController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all fields")));
        return;
    }

    // Combine message (simplified for v0.1)
    final fullMessage = {
      'observation': _observationController.text,
      'emotions': _myEmotions,
      'need': _selectedNeed,
      'request': _requestController.text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).update({
      'current_message': fullMessage,
      'status': 'message_sent', // Triggers Listener's Reflection Phase
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress Indicator
        LinearProgressIndicator(value: (_currentStep + 1) / 4),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe
            children: [
              _buildObservationStep(),
              _buildNeedStep(),
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
          const Text(
            "Step 1: Observation",
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "What happened – without blame?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Describe it like a video camera would record it. No opinions or 'always/never'.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _observationController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'When...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _nextPage,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  // STEP 2: Needs (and Emotion recap)
  Widget _buildNeedStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Step 2: Feelings & Needs",
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            "I feel ${_myEmotions.join(' & ')}...",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          const Text(
            "...because I need:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: _needs.map((need) {
                return RadioListTile<String>(
                  title: Text(need),
                  value: need,
                  groupValue: _selectedNeed,
                  onChanged: (value) {
                    setState(() {
                      _selectedNeed = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          FilledButton(
            onPressed: _selectedNeed != null ? _nextPage : null,
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  // STEP 3: Request
  Widget _buildRequestStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Step 3: Request",
            style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "What would help right now?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Make a clear, specific request. Not a demand.",
            style: TextStyle(color: Colors.black54),
          ),
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

  // STEP 4: Preview
  Widget _buildPreviewStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Review your message",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "When ${_observationController.text}",
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  "I feel ${_myEmotions.join(' & ')}",
                  style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "because I need ${_selectedNeed}.",
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  "${_requestController.text}",
                  style: const TextStyle(fontSize: 16, height: 1.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _sendMessage,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: Colors.green,
            ),
            child: const Text("Send Message", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
