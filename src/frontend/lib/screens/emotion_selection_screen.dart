import 'package:flutter/material.dart';

class EmotionSelectionScreen extends StatelessWidget {
  final String sessionId;
  const EmotionSelectionScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotion Selection')),
      body: const Center(
        child: Text('Placeholder: Select your emotions here.'),
      ),
    );
  }
}
