import 'package:flutter/material.dart';
import 'raphael_controller.dart';
import 'raphael_state.dart';
import 'raphael_widget.dart';

class RaphaelPage extends StatefulWidget {
  const RaphaelPage({super.key});
  @override State<RaphaelPage> createState() => _RaphaelPageState();
}

class _RaphaelPageState extends State<RaphaelPage> {
  late final RaphaelController controller;
  @override void initState() { super.initState(); controller = RaphaelController(); }
  @override void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Raphael')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (controller.visible) RaphaelWidget(mood: controller.mood),
            const SizedBox(height: 28),
            Text('Estado: ' + controller.mood.name),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              children: RaphaelMood.values.map((mood) => ChoiceChip(
                label: Text(mood.name),
                selected: controller.mood == mood,
                onSelected: (_) => controller.setMood(mood),
              )).toList(),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: controller.toggleVisible,
              icon: Icon(controller.visible ? Icons.visibility_off : Icons.visibility),
              label: Text(controller.visible ? 'Ocultar Raphael' : 'Mostrar Raphael'),
            ),
          ],
        ),
      ),
    ),
  );
}
