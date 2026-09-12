import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class WarGamingApp extends StatelessWidget {
  const WarGamingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'War Gaming',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      locale: const Locale('ar'),
      home: const HomeScreen(),
    );
  }
}
