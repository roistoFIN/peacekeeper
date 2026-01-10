import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'regulation_screen.dart';
import '../services/subscription_service.dart';
import '../services/debug_service.dart';
import 'paywall_screen.dart';

class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    DebugService.info("JoinSessionScreen initialized");
    _checkPremium();
    _codeController.addListener(_validateInput);
  }

  Future<void> _checkPremium() async {
    final status = await SubscriptionService.isPremium();
    if (mounted) setState(() => _isPremium = status);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      _isButtonEnabled = _codeController.text.length == 6 &&
          int.tryParse(_codeController.text) != null;
    });
  }

  Future<void> _joinSession() async {
    final code = _codeController.text;
    DebugService.info("Attempting to join session with code: $code");
    
    setState(() {
      _isButtonEnabled = false; // Prevent double taps
    });
    
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Authenticate
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
      }
      
      if (user == null) throw Exception("Authentication failed");

      // 2. Check Session
      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(code);
      final sessionDoc = await sessionRef.get();

      if (!sessionDoc.exists) {
        Navigator.pop(context); // Close loading dialog
        DebugService.info("Join Failed: Invalid code.");
        _showError("Invalid code. Please check and try again.");
        setState(() { _isButtonEnabled = true; });
        return;
      }
      
      final data = sessionDoc.data();
      if (data != null && data['status'] == 'active') {
         Navigator.pop(context);
         DebugService.info("Join Failed: Session full.");
         _showError("This session is already full.");
         setState(() { _isButtonEnabled = true; });
         return;
      }

      // 3. Join Session
      DebugService.info("Joining session $code...");
      await sessionRef.update({
        'participants': FieldValue.arrayUnion([user.uid]),
        'status': 'active', // This triggers the listener on the Host's side
      });

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegulationScreen(sessionId: code),
          ),
        );
      }
    } catch (e) {
      DebugService.error("Error joining session", e);
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showError("Error joining: $e");
        setState(() { _isButtonEnabled = true; });
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peacekeeper: Couples Coach'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _isPremium
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Center(
                    child: Text("Premium enabled", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                )
              : TextButton.icon(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const PaywallScreen()));
                    _checkPremium();
                  },
                  icon: const Icon(Icons.diamond, color: Colors.purple),
                  label: const Text("Get Premium", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Conflict Code',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ask your partner for the 6-digit code on their screen.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade300,
                    letterSpacing: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isButtonEnabled ? _joinSession : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Join Conversation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
