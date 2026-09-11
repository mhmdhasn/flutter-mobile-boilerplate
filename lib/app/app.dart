// Application entry widget.
// Firebase / Localization / DI are initialized in main.dart before runApp.
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // home: ..., routerConfig: ... (see router.dart)
    );
  }
}
