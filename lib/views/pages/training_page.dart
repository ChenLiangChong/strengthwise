import 'package:flutter/material.dart';

class TrainingPage extends StatelessWidget {
  const TrainingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練計劃'),
      ),
      body: const Center(
        child: Text('訓練頁面'),
      ),
    );
  }
} 