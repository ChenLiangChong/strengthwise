import 'package:flutter/material.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('課程預約'),
      ),
      body: const Center(
        child: Text('預約頁面'),
      ),
    );
  }
} 