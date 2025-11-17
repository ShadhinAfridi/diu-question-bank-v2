// question_upload_screen.dart
import 'package:flutter/material.dart';

class QuestionUploadScreen extends StatelessWidget {
  const QuestionUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Question Upload Screen',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
    );
  }
}