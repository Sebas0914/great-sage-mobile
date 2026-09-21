import 'package:flutter/material.dart';

void main() {
  runApp(const GreatSageMobileApp());
}

class GreatSageMobileApp extends StatelessWidget {
  const GreatSageMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GREAT SAGE Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF070A10),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6C63FF),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 28,
                        spreadRadius: 2,
                        color: Color(0x556C63FF),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 72,
                    color: Color(0xFFB9B4FF),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'GREAT SAGE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mobile',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 36),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Abrir GREAT SAGE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
