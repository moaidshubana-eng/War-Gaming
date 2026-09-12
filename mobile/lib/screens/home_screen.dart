import 'package:flutter/material.dart';

import 'lobby_screen.dart';

enum ConnectionMode { online, bluetooth }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF102027),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'War Gaming',
                style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'لعبة حرب جماعية بالفرق — أونلاين أو بلوتوث',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              _ModeButton(
                label: 'اللعب أونلاين مع الأصدقاء',
                icon: Icons.public,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LobbyScreen(mode: ConnectionMode.online)),
                ),
              ),
              const SizedBox(height: 16),
              _ModeButton(
                label: 'اللعب عبر البلوتوث (بدون إنترنت)',
                icon: Icons.bluetooth,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LobbyScreen(mode: ConnectionMode.bluetooth)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF37474F),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
