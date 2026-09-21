import 'package:flutter/material.dart';
import 'raphael_state.dart';

class RaphaelWidget extends StatelessWidget {
  const RaphaelWidget({super.key, required this.mood, this.size = 180});
  final RaphaelMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = switch (mood) {
      RaphaelMood.listening => const Color(0xFF48D8FF),
      RaphaelMood.thinking => const Color(0xFF9C8CFF),
      RaphaelMood.speaking => const Color(0xFF7CFFB2),
      RaphaelMood.happy => const Color(0xFFFFD76A),
      RaphaelMood.neutral => const Color(0xFF8C83FF),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [accent.withValues(alpha: .30), Colors.transparent]),
        border: Border.all(color: accent.withValues(alpha: .75), width: 2),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: .20), blurRadius: 30)],
      ),
      child: Center(child: Icon(Icons.auto_awesome, size: size * .38, color: accent)),
    );
  }
}
