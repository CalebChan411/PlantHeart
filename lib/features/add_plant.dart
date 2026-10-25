import 'package:flutter/material.dart';
import '../app/plant_controller.dart';
import '../models/plant_data.dart';
import '../widgets/design.dart';

Future<void> showAddPlant(BuildContext context, PlantController controller) =>
    showDialog<void>(
      context: context,
      builder: (_) => _AddPlantDialog(controller: controller),
    );

class _AddPlantDialog extends StatefulWidget {
  final PlantController controller;
  const _AddPlantDialog({required this.controller});
  @override
  State<_AddPlantDialog> createState() => _AddPlantDialogState();
}

class _AddPlantDialogState extends State<_AddPlantDialog> {
  final name = TextEditingController();
  String species = 'pothos', personality = 'Gentle';
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> add() async {
    if (saving) return;
    setState(() => saving = true);
    final saved = await widget.controller.addPlant(
      name.text,
      species,
      personality,
    );
    if (!mounted) return;
    if (!saved) feedback(context, false, '');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('A new green friend'),
    content: SizedBox(
      width: 340,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Each plant has its own readings, conversations and growing story.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: name,
              autofocus: true,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Plant name',
                hintText: 'e.g. Fern',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: species,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Plant species'),
              items: [
                for (final p in plantProfiles)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(() => species = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: personality,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Personality'),
              items: [
                for (final p in personalities)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: saving
                  ? null
                  : (value) => setState(() => personality = value!),
            ),
            const SizedBox(height: 12),
            const Text(
              'Starts with healthy simulated readings. No hardware is connected.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: saving ? null : add,
        child: Text(saving ? 'Adding…' : 'Add plant'),
      ),
    ],
  );
}
