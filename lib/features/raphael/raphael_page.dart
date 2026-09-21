import 'package:flutter/material.dart';
import 'raphael_runtime.dart';
import 'raphael_state.dart';
import 'raphael_widget.dart';

class RaphaelPage extends StatelessWidget {
  const RaphaelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final runtime = RaphaelRuntime.instance;
    return AnimatedBuilder(
      animation: runtime,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Raphael')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaphaelWidget(mood: runtime.mood, size: 220),
                const SizedBox(height: 24),
                Text(
                  'Estado: ${runtime.mood.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: RaphaelMood.values.map((mood) => ChoiceChip(
                    label: Text(mood.name),
                    selected: runtime.mood == mood,
                    onSelected: (_) => runtime.setMood(mood),
                  )).toList(),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => runtime.setFloating(!runtime.floating),
                  icon: Icon(runtime.floating
                      ? Icons.visibility_off
                      : Icons.picture_in_picture_alt_outlined),
                  label: Text(runtime.floating
                      ? 'Desactivar Raphael flotante'
                      : 'Activar Raphael flotante'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
