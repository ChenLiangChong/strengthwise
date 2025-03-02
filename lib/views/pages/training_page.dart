import 'package:flutter/material.dart';
import 'exercises_page.dart';

class TrainingPage extends StatelessWidget {
  const TrainingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練計劃'),
      ),
      body: const Center(
        child: Text('訓練頁面'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30, bottom: 20),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FloatingActionButton(
            onPressed: () {
              // 導航到exercises_page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExercisesPage(),
                ),
              );
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
} 