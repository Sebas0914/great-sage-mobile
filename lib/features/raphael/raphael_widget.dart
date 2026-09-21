import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'raphael_state.dart';

class RaphaelWidget extends StatefulWidget {
  const RaphaelWidget({super.key, required this.mood, this.size = 180});
  final RaphaelMood mood;
  final double size;
  @override State<RaphaelWidget> createState() => _RaphaelWidgetState();
}

class _RaphaelWidgetState extends State<RaphaelWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse;

  @override
  void initState() {
    super.initState();
    pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = switch (widget.mood) {
      RaphaelMood.listening => const Color(0xFF48D8FF),
      RaphaelMood.thinking => const Color(0xFF9C8CFF),
      RaphaelMood.speaking => const Color(0xFF7CFFB2),
      RaphaelMood.happy => const Color(0xFFFFD76A),
      RaphaelMood.neutral => const Color(0xFF8C83FF),
    };
    final active = widget.mood != RaphaelMood.neutral;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final wave = math.sin(pulse.value * math.pi);
        final scale = active ? 1.0 + wave * .035 : 1.0;
        return Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                stops: const [0.0, .45, 1.0],
                colors: [
                  accent.withValues(alpha: .20 + wave * .08),
                  accent.withValues(alpha: .08),
                  Colors.transparent,
                ],
              ),
              border: Border.all(color: accent.withValues(alpha: .8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .25 + wave * .12),
                  blurRadius: 28 + wave * 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _RaphaelCorePainter(accent: accent, mood: widget.mood, phase: wave),
              child: Center(
                child: Icon(
                  widget.mood == RaphaelMood.thinking
                      ? Icons.more_horiz
                      : widget.mood == RaphaelMood.listening
                          ? Icons.hearing
                          : widget.mood == RaphaelMood.speaking
                              ? Icons.graphic_eq
                              : Icons.auto_awesome,
                  size: widget.size * .30,
                  color: accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RaphaelCorePainter extends CustomPainter {
  const _RaphaelCorePainter({required this.accent, required this.mood, required this.phase});
  final Color accent;
  final RaphaelMood mood;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .34;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: .35);
    final rings = mood == RaphaelMood.thinking ? 3 : 2;
    for (var i = 0; i < rings; i++) {
      final r = radius + i * 15 + phase * 4;
      canvas.drawCircle(center, r, paint);
    }
    if (mood == RaphaelMood.listening || mood == RaphaelMood.speaking) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: .75);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 10),
        -math.pi / 2,
        mood == RaphaelMood.speaking ? math.pi * 1.5 : math.pi,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaphaelCorePainter oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.mood != mood || oldDelegate.phase != phase;
}
