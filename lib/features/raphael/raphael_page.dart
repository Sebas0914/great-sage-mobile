import 'package:flutter/material.dart';
import 'raphael_state.dart';
import 'raphael_widget.dart';

class RaphaelPage extends StatefulWidget {
  const RaphaelPage({super.key});
  @override State<RaphaelPage> createState() => _RaphaelPageState();
}
class _RaphaelPageState extends State<RaphaelPage> {
  RaphaelMood mood = RaphaelMood.neutral;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Raphael')),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      RaphaelWidget(mood: mood),
      const SizedBox(height: 28),
      Text('Estado: ${mood.name}'),
      const SizedBox(height: 24),
      Wrap(spacing: 8, children: RaphaelMood.values.map((v) => ChoiceChip(
        label: Text(v.name), selected: mood == v, onSelected: (_) => setState(() => mood = v),
      )).toList()),
    ])),
  );
}
