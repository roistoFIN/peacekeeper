import 'dart:async';
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
  final List<String> _selectedNeeds = [];
  final TextEditingController _requestController = TextEditingController();

  // AI States
  List<String> _aiAlternatives = [];
  bool _isOffensive = false;
  
  List<String> _aiSuggestedFeelings = [];
  List<String> _aiSuggestedNeeds = [];
  bool _isProcessingAI = false;
  
  String? _lastVettedText;
  String? _lastVettedRequest;

  @override
  void initState() {
    super.initState();
    _observationController.addListener(() {
      if (_aiAlternatives.isNotEmpty && _observationController.text != _lastVettedText) {
        setState(() { _aiAlternatives = []; _isOffensive = false; });
      }
      setState(() {});
    });
    _requestController.addListener(() {
      if (_aiAlternatives.isNotEmpty && _requestController.text != _lastVettedRequest) {
        setState(() { _aiAlternatives = []; _isOffensive = false; });
      }
      setState(() {});
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final vocab = await _contentService.fetchVocabulary();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId).collection('participant_states').doc(uid).get();
    final preSelectedEmotions = userDoc.exists ? List<String>.from(userDoc.data()?['emotions'] ?? []) : <String>[];
    if (mounted) {
      setState(() { _vocabulary = vocab; _selectedFeelings.addAll(preSelectedEmotions); _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _observationController.dispose();
    _requestController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() { _currentStep++; _aiAlternatives = []; _isOffensive = false; });
    if (_currentStep == 1) _getFeelingsSuggestions();
    if (_currentStep == 2) _getNeedsSuggestions();
  }

  void _prevPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() { _currentStep--; _aiAlternatives = []; _isOffensive = false; });
  }

  // --- AI Logic ---
  Future<bool> _neutralizeObservation() async {
    final currentText = _observationController.text.trim();
    if (currentText.length < 5) return true;
    if (currentText == _lastVettedText) return !_isOffensive;

    setState(() => _isProcessingAI = true);
    final result = await _contentService.neutralizeObservation("When $currentText");
    
    if (mounted) {
      setState(() {
        _isProcessingAI = false;
        _lastVettedText = currentText;
        _isOffensive = result.isOffensive;
        _aiAlternatives = result.alternatives ?? (result.result != currentText ? [result.result] : []);
      });
      return !result.isOffensive && _aiAlternatives.isEmpty;
    }
    return true;
  }

  Future<void> _getFeelingsSuggestions() async {
    final result = await _contentService.suggestFeelings("When ${_observationController.text}");
    if (mounted && !result.hasError) setState(() => _aiSuggestedFeelings = List<String>.from(result.result));
  }

  Future<void> _getNeedsSuggestions() async {
    final result = await _contentService.suggestNeeds("When ${_observationController.text}", _selectedFeelings);
    if (mounted && !result.hasError) setState(() => _aiSuggestedNeeds = List<String>.from(result.result));
  }

  Future<bool> _refineRequest() async {
    final currentReq = _requestController.text.trim();
    if (currentReq.length < 5) return true;
    if (currentReq == _lastVettedRequest) return !_isOffensive;

    setState(() => _isProcessingAI = true);
    final result = await _contentService.refineRequest("Would you be willing to $currentReq", {
      'feelings': _selectedFeelings.join(", "),
      'needs': _selectedNeeds.join(", "),
    });
    
    if (mounted) {
      setState(() {
        _isProcessingAI = false;
        _lastVettedRequest = currentReq;
        _isOffensive = result.isOffensive;
        String mainResult = result.result;
        if (mainResult.toLowerCase().startsWith("would you be willing to ")) mainResult = mainResult.substring(24).replaceFirst(RegExp(r'\?$'), '').trim();
        
        List<String> alts = result.alternatives?.map((s) {
          if (s.toLowerCase().startsWith("would you be willing to ")) return s.substring(24).replaceFirst(RegExp(r'\?$'), '').trim();
          return s;
        }).toList() ?? (mainResult != currentReq ? [mainResult] : []);
        
        _aiAlternatives = alts;
      });
      return !result.isOffensive && _aiAlternatives.isEmpty;
    }
    return true;
  }

  Future<void> _sendMessage() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fullMessage = {
      'observation': "When ${_observationController.text}",
      'emotions': _selectedFeelings,
      'need': _selectedNeeds.join(", "),
      'request': "Would you be willing to ${_requestController.text}?",
      'timestamp': FieldValue.serverTimestamp(),
    };
    final batch = FirebaseFirestore.instance.batch();
    final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);
    batch.update(sessionRef, {'current_message': fullMessage, 'status': 'message_sent'});
    batch.set(sessionRef.collection('participant_states').doc(uid), {'emotions': _selectedFeelings}, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        LinearProgressIndicator(value: (_currentStep + 1) / 5),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildObservationStep(),
              _buildSelectionStep(title: "I feel...", dataKey: 'feelings', selectedItems: _selectedFeelings, aiSuggestions: _aiSuggestedFeelings, maxItems: 2, onContinue: _nextPage, showObs: true),
              _buildSelectionStep(title: "Because I need...", dataKey: 'needs', selectedItems: _selectedNeeds, aiSuggestions: _aiSuggestedNeeds, maxItems: 2, onContinue: _nextPage, showObs: true, showFeelings: true),
              _buildRequestStep(),
              _buildPreviewStep(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousContext({bool showObs = false, bool showFeelings = false, bool showNeeds = false}) {
    return Container(
      padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showObs) Text("When ${_observationController.text}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          if (showFeelings && _selectedFeelings.isNotEmpty) Text("I feel ${_selectedFeelings.join(' & ')}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.blue)),
          if (showNeeds && _selectedNeeds.isNotEmpty) Text("because I need ${_selectedNeeds.join(' & ')}", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStepButtons({required VoidCallback onNext, bool isProcessing = false, String nextLabel = "Next", bool canProceed = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        children: [
          if (_currentStep > 0) OutlinedButton(onPressed: _prevPage, child: const Text("Back")),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: (isProcessing || !canProceed) ? null : onNext,
              child: isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesBox(TextEditingController controller, String nextButtonLabel) {
    if (_aiAlternatives.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(_isOffensive ? "That sounds judgmental. Try these facts instead:" : "AI Suggestion:", style: TextStyle(fontWeight: FontWeight.bold, color: _isOffensive ? Colors.orange.shade800 : Colors.blue)),
        const SizedBox(height: 8),
        ..._aiAlternatives.map((alt) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () { 
              setState(() { 
                controller.text = alt; 
                _aiAlternatives = []; 
                _isOffensive = false; 
                _lastVettedText = alt; 
                _lastVettedRequest = alt; 
              }); 
              // Acceptance allows automatic progress
              _nextPage();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.2))),
              child: Row(children: [Expanded(child: Text(alt, style: const TextStyle(fontStyle: FontStyle.italic))), const Icon(Icons.check_circle, color: Colors.blue)]),
            ),
          ),
        )),
        if (_isOffensive) 
          const Text("Please select a neutral alternative to continue.", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))
        else
          Text("Tap to accept or click $nextButtonLabel to keep yours", style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildObservationStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Step 1: Observation", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("What happened?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(controller: _observationController, maxLength: 200, maxLines: 2, decoration: const InputDecoration(prefixText: 'When ', border: OutlineInputBorder(), filled: true)),
          _buildAlternativesBox(_observationController, "Next"),
          const Spacer(),
          _buildStepButtons(
            onNext: () async {
              if (_aiAlternatives.isNotEmpty && !_isOffensive) { 
                _nextPage(); 
                return; 
              }
              
              final shouldProceed = await _neutralizeObservation();
              if (shouldProceed && mounted) {
                _nextPage();
              }
            },
            isProcessing: _isProcessingAI,
            canProceed: !_isOffensive
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionStep({required String title, required String dataKey, required List<String> selectedItems, required List<String> aiSuggestions, required int maxItems, required VoidCallback onContinue, bool showObs = false, bool showFeelings = false}) {
    final sectionData = _vocabulary[dataKey] as Map<String, dynamic>? ?? {};
    final categories = (sectionData['categories'] as List<dynamic>?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPreviousContext(showObs: showObs, showFeelings: showFeelings),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (aiSuggestions.isNotEmpty) ...[
            const Text("AI Suggestions:", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            Wrap(spacing: 8, children: aiSuggestions.map((s) => FilterChip(label: Text(s), selected: selectedItems.contains(s), onSelected: (val) { setState(() { if (val && selectedItems.length < maxItems) selectedItems.add(s); if (!val) selectedItems.remove(s); }); }, backgroundColor: Colors.blue.shade50)).toList()),
            const Divider(height: 32),
          ],
          ...categories.map((cat) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Wrap(spacing: 8, children: (cat['words'] as List).cast<String>().map((word) => FilterChip(label: Text(word), selected: selectedItems.contains(word), onSelected: (val) { setState(() { if (val && selectedItems.length < maxItems) selectedItems.add(word); if (!val) selectedItems.remove(word); }); })).toList()),
            const SizedBox(height: 16),
          ])),
          _buildStepButtons(onNext: onContinue),
        ],
      ),
    );
  }

  Widget _buildRequestStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPreviousContext(showObs: true, showFeelings: true, showNeeds: true),
          const Text("Step 4: Request", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("What would help?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(controller: _requestController, maxLength: 200, maxLines: 2, decoration: const InputDecoration(prefixText: "Would you be willing to ", border: OutlineInputBorder(), filled: true)),
          _buildAlternativesBox(_requestController, "Preview"),
          const Spacer(),
          _buildStepButtons(
            onNext: () async {
              if (_aiAlternatives.isNotEmpty && !_isOffensive) { 
                _nextPage(); 
                return; 
              }
              final shouldProceed = await _refineRequest();
              if (shouldProceed && mounted) {
                _nextPage();
              }
            },
            isProcessing: _isProcessingAI,
            canProceed: !_isOffensive, 
            nextLabel: "Preview"
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Step 5: Say this to your partner", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blueGrey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("When ${_observationController.text}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text("I feel ${_selectedFeelings.join(' & ')}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 8),
                Text("because I need ${_selectedNeeds.join(' & ')}.", style: const TextStyle(fontSize: 18, color: Colors.green)),
                const Divider(height: 40),
                Text("Would you be willing to ${_requestController.text}?", style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Spacer(),
          _buildStepButtons(onNext: _sendMessage, nextLabel: "I have shared this"),
        ],
      ),
    );
  }
}
