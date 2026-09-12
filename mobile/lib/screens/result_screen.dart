import 'package:flutter/material.dart';

import '../models/team.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.winner, required this.didWin});

  final Team winner;
  final bool didWin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: didWin ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              didWin ? 'فريقكم فاز! 🎉' : 'خسر فريقكم',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'الفريق الفائز: ${winner == Team.red ? "الأحمر" : "الأزرق"}',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    );
  }
}
