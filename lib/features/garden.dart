import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/plant_controller.dart';
import '../models/plant_data.dart';
import '../widgets/design.dart';

class GardenPage extends StatefulWidget {
  final PlantController controller;
  const GardenPage({super.key, required this.controller});
  @override
  State<GardenPage> createState() => _GardenPageState();
}

class _GardenPageState extends State<GardenPage> {
  bool memory = true;
  Future<void> edit([Entry? entry]) async {
    final text = await editText(
      context,
      title:
          '${entry == null ? 'Add' : 'Edit'} ${memory ? 'memory' : 'milestone'}',
      initial: entry?.text ?? '',
    );
    if (text == null || !mounted) return;
    await reportSave(
      context,
      widget.controller.saveEntry(text, memory: memory, id: entry?.id),
      '${memory ? 'Memory' : 'Milestone'} saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, d = c.data;
    final entries = (memory ? d.memories : d.milestones).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return PageBody(
      title: 'Our memoir.',
      subtitle: 'Save the moments. Watch your story take root.',
      eyebrow: 'MEMORIES & GROWTH',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            ChoiceChip(
              label: const Text('Memories'),
              selected: memory,
              onSelected: (_) => setState(() => memory = true),
            ),
            ChoiceChip(
              label: const Text('Journey'),
              selected: !memory,
              onSelected: (_) => setState(() => memory = false),
            ),
          ],
        ),
        if (!memory) ...[
          SoftCard(
            color: mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.name}’s growth journey',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: d.stage,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Life stage'),
                  items: [
                    for (final stage in lifeStages)
                      DropdownMenuItem(value: stage, child: Text(stage)),
                  ],
                  onChanged: (v) async {
                    await reportSave(
                      context,
                      c.stage(v!),
                      'Life stage recorded in the journey.',
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  '${d.checkInDays.length} days of care · ${d.milestones.length} milestones · ${d.snapshots.length} snapshots',
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: c.journeySummary));
                if (context.mounted) {
                  feedback(context, true, 'Journey summary copied.');
                }
              } catch (_) {
                if (context.mounted) feedback(context, false, '');
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy journey summary'),
          ),
          const Text(
            'Photo notes can be added as text milestones. Camera capture, time-lapse and memorial video are future integrations.',
          ),
        ],
        FilledButton.icon(
          onPressed: edit,
          icon: const Icon(Icons.add_rounded),
          label: Text(memory ? 'Plant a memory' : 'Add a milestone'),
        ),
        if (entries.isEmpty)
          SoftCard(
            color: memory ? sun : sky,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  memory
                      ? Icons.local_florist_outlined
                      : Icons.auto_stories_outlined,
                  size: 36,
                  color: leaf,
                ),
                const SizedBox(height: 12),
                Text(
                  memory
                      ? 'A place for your little moments.'
                      : 'Every story starts with a first leaf.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  memory
                      ? 'Save a little moment from your life with this plant.'
                      : 'Mark a new leaf, a repotting day, or a quiet moment of care.',
                ),
              ],
            ),
          ),
        for (final e in entries)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(
                  memory
                      ? 'A shared memory'
                      : e.kind == 'stage'
                      ? 'Life stage'
                      : 'Milestone',
                  color: memory ? sun : sky,
                ),
                const SizedBox(height: 12),
                Text(e.text, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(dateLabel(e.at)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Edit ${memory ? 'memory' : 'milestone'}',
                      onPressed: () => edit(e),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete ${memory ? 'memory' : 'milestone'}',
                      onPressed: () async {
                        final isMemory = memory;
                        if (await confirm(
                              context,
                              'Remove this ${isMemory ? 'memory' : 'milestone'}?',
                              'This only removes this entry from your device. It cannot be undone.',
                            ) &&
                            context.mounted) {
                          await reportSave(
                            context,
                            c.deleteEntry(e.id, memory: isMemory),
                            'Entry removed.',
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (!memory && d.activities.isNotEmpty) ...[
          const SectionTitle('Care moments'),
          for (final event in d.activities.reversed.take(15))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 10, color: leaf),
              title: Text(event.text),
              subtitle: Text(dateLabel(event.at)),
            ),
        ],
      ],
    );
  }
}
