import 'package:flutter/material.dart';
import '../app/plant_controller.dart';
import '../models/plant_data.dart';
import '../widgets/design.dart';
import '../widgets/milo.dart';

class ProfileForm extends StatefulWidget {
  final PlantController controller;
  final bool onboarding;
  const ProfileForm({
    super.key,
    required this.controller,
    this.onboarding = false,
  });
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final name = TextEditingController(text: widget.controller.data.name);
  late String species = widget.controller.data.species;
  late String personality = widget.controller.data.personality;
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save({bool defaults = false}) async {
    setState(() => saving = true);
    final ok = await widget.controller.profile(
      defaults ? 'Milo' : name.text,
      defaults ? 'pothos' : species,
      defaults ? 'Gentle' : personality,
      finish: widget.onboarding,
    );
    if (!mounted) return;
    setState(() => saving = false);
    feedback(
      context,
      ok,
      widget.onboarding
          ? 'Your little green story starts here.'
          : 'Profile saved.',
    );
    if (ok && !widget.onboarding) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    eyebrow: widget.onboarding
        ? 'A LITTLE FRIEND. A LITTLE EVERY DAY.'
        : 'MAKE IT YOURS',
    title: widget.onboarding ? 'Meet your new\ngreen friend.' : 'Plant profile',
    subtitle: widget.onboarding
        ? 'Grow a gentle routine together. Let’s start with a name.'
        : 'A little personality makes a plant feel like home.',
    children: [
      Milo(
        name: name.text,
        reducedMotion: widget.controller.data.reducedMotion,
        height: 230,
      ),
      const Tag('100% local · simulated sensors', color: sun),
      TextField(
        controller: name,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Plant name',
          hintText: 'Milo',
        ),
      ),
      DropdownButtonFormField<String>(
        initialValue: species,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Plant species'),
        items: [
          for (final p in plantProfiles)
            DropdownMenuItem(value: p.id, child: Text(p.name)),
        ],
        onChanged: (v) => setState(() => species = v!),
      ),
      DropdownButtonFormField<String>(
        initialValue: personality,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Personality'),
        items: [
          for (final p in personalities)
            DropdownMenuItem(value: p, child: Text(p)),
        ],
        onChanged: (v) => setState(() => personality = v!),
      ),
      FilledButton(
        onPressed: saving ? null : save,
        child: Text(
          saving
              ? 'Saving…'
              : widget.onboarding
              ? 'Let’s grow together'
              : 'Save profile',
        ),
      ),
      if (widget.onboarding)
        TextButton(
          onPressed: saving ? null : () => save(defaults: true),
          child: const Text('Start with Milo · edit details later'),
        ),
      const Text(
        'No hardware, accounts, or internet needed. Your stories stay on this device. This prototype uses rule-based chat, not an AI service.',
      ),
    ],
  );
}
