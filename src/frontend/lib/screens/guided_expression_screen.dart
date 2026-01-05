import 'package:flutter/material.dart';

class GuidedExpressionScreen extends StatelessWidget {
  final String sessionId;
  const GuidedExpressionScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guided Expression')),
      body: const Center(
        child: Text('Placeholder: Speaker/Listener flow starts here.'),
      ),
    );
  }
}
