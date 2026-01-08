import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/content_service.dart';
import '../services/subscription_service.dart';

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
  bool _isPremium = false;

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

  // Instructions Data
  static const Map<String, Map<String, dynamic>> _stepInstructions = {
    'observation': {
      'title': 'Observations',
      'short': 'Describe what is happening without adding judgment.',
      'detail': 'Describe what is happening without adding judgment, evaluation, or "always/never" labels. It is like a camera recording a scene.',
      'impulsive': "You're always lazy with the dishes.",
      'nvc': "When I saw the dishes in the sink this morning..."
    },
    'feelings': {
      'title': 'Feelings',
      'short': 'Name your internal emotion.',
      'detail': "Name your internal emotion. Crucially, NVC distinguishes between true feelings and interpretations of others' actions (e.g., 'I feel ignored' is an interpretation; 'I feel lonely' is a feeling).",
      'impulsive': "I feel like you don't care about me.",
      'nvc': "...I felt frustrated and overwhelmed."
    },
    'needs': {
      'title': 'Needs',
      'short': 'Connect the feeling to a universal human need.',
      'detail': "Connect the feeling to a universal human need. This is the 'why' behind the emotion. It’s hard to argue with a basic human need like 'respect' or 'order'.",
      'impulsive': "I need you to grow up.",
      'nvc': "...because I have a need for support and shared responsibility."
    },
    'request': {
      'title': 'Requests',
      'short': 'Make a specific, positive, and doable request.',
      'detail': "Make a specific, positive, and doable request. It must be something the person can do, and it must be a request, not a demand (they can say 'no').",
      'impulsive': "Clean up after yourself for once.",
      'nvc': "...Would you be willing to empty the dishwasher before work tomorrow?"
    }
  };

  void _showHelp(BuildContext context, String stepKey) {
    final content = _stepInstructions[stepKey]!;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(content['title']!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(content['detail']!, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("IMPULSIVE (Avoid)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  Text('"${content['impulsive']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("NVC WAY (Try this)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                  const SizedBox(height: 4),
                  Text('"${content['nvc']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it"),
              ),
            )
          ],
        ),
      ),
    );
  }

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
    final premiumStatus = await SubscriptionService.isPremium();
    if (mounted) {
      setState(() { 
        _vocabulary = vocab; 
        _selectedFeelings.addAll(preSelectedEmotions); 
        _isPremium = premiumStatus;
        _isLoading = false; 
      });
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
    if (!_isPremium) return true;
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
    if (!_isPremium) return;
    final result = await _contentService.suggestFeelings("When ${_observationController.text}");
    if (mounted && !result.hasError) setState(() => _aiSuggestedFeelings = List<String>.from(result.result));
  }

  Future<void> _getNeedsSuggestions() async {
    if (!_isPremium) return;
    final result = await _contentService.suggestNeeds("When ${_observationController.text}", _selectedFeelings);
    if (mounted && !result.hasError) setState(() => _aiSuggestedNeeds = List<String>.from(result.result));
  }

  Future<bool> _refineRequest() async {
    if (!_isPremium) return true;
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
              _buildSelectionStep(stepKey: 'feelings', title: "I feel...", dataKey: 'feelings', selectedItems: _selectedFeelings, aiSuggestions: _aiSuggestedFeelings, maxItems: 2, onContinue: _nextPage, showObs: true),
              _buildSelectionStep(stepKey: 'needs', title: "Because I need...", dataKey: 'needs', selectedItems: _selectedNeeds, aiSuggestions: _aiSuggestedNeeds, maxItems: 2, onContinue: _nextPage, showObs: true, showFeelings: true),
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

  Widget _buildAlternativesBox(TextEditingController controller, String nextButtonLabel, {String? stoppingQuestion}) {
    if (_aiAlternatives.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (_isOffensive && stoppingQuestion != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.pause_circle_outline, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Text(stoppingQuestion, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900))),
              ],
            ),
          ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Step 1: Observation", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _showHelp(context, 'observation'),
                icon: const Icon(Icons.help_outline, size: 20, color: Colors.blueGrey),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("What happened?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_stepInstructions['observation']!['short']!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 24),
          TextField(controller: _observationController, maxLength: 200, maxLines: 2, decoration: const InputDecoration(prefixText: 'When ', border: OutlineInputBorder(), filled: true)),
          _buildAlternativesBox(_observationController, "Next", stoppingQuestion: "Am I certain about this interpretation?"),
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

  Widget _buildSelectionStep({required String stepKey, required String title, required String dataKey, required List<String> selectedItems, required List<String> aiSuggestions, required int maxItems, required VoidCallback onContinue, bool showObs = false, bool showFeelings = false}) {
    final sectionData = _vocabulary[dataKey] as Map<String, dynamic>? ?? {};
    final categories = (sectionData['categories'] as List<dynamic>?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPreviousContext(showObs: showObs, showFeelings: showFeelings),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              IconButton(
                onPressed: () => _showHelp(context, stepKey),
                icon: const Icon(Icons.help_outline, size: 20, color: Colors.blueGrey),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_stepInstructions[stepKey]!['short']!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Step 4: Request", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _showHelp(context, 'request'),
                icon: const Icon(Icons.help_outline, size: 20, color: Colors.blueGrey),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("What would help?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_stepInstructions['request']!['short']!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 24),
          TextField(controller: _requestController, maxLength: 200, maxLines: 2, decoration: const InputDecoration(prefixText: "Would you be willing to ", border: OutlineInputBorder(), filled: true)),
          _buildAlternativesBox(_requestController, "Preview", stoppingQuestion: "Is my partner bad, or simply different from me?"),
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
