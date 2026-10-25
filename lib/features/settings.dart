import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/plant_controller.dart';
import '../widgets/design.dart';

class SettingsPage extends StatelessWidget {
  final PlantController controller;
  final VoidCallback editProfile;
  const SettingsPage({
    super.key,
    required this.controller,
    required this.editProfile,
  });
  @override
  Widget build(BuildContext context) {
    final d = controller.data;
    Future<void> clear(String section, String title) async {
      if (await confirm(
            context,
            title,
            section == 'reset'
                ? 'This erases ALL plants and their profiles, chats, memories, journals, posts, history and preferences on this device. First-run setup will return. Recovery backups, if any, are retained.'
                : 'This deletes the selected data for ${d.name} only. Other plants are kept. It cannot be undone.',
          ) &&
          context.mounted) {
        final ok = await controller.clear(section);
        if (!context.mounted) return;
        feedback(
          context,
          ok,
          section == 'reset'
              ? 'Demo reset. Start a new story.'
              : 'Selected data cleared.',
        );
        if (section == 'reset' && ok) {
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      }
    }

    return PageBody(
      title: 'Make yourself\nat home.',
      subtitle: 'Your plant. Your pace. Your little world.',
      eyebrow: 'SETTINGS & PRIVACY',
      children: [
        SoftCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.spa_outlined, color: leaf),
            title: Text(d.name),
            subtitle: Text('${d.profile.name} · ${d.personality}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: editProfile,
          ),
        ),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Larger text'),
                subtitle: const Text('Make this little world easier to read.'),
                value: d.largeText,
                onChanged: (v) => controller.change(() => d.largeText = v),
              ),
              SwitchListTile(
                title: const Text('Reduce motion'),
                subtitle: const Text('Keep your companion still.'),
                value: d.reducedMotion,
                onChanged: (v) => controller.change(() => d.reducedMotion = v),
              ),
              SwitchListTile(
                title: const Text('Daily check-in button'),
                subtitle: const Text(
                  'Show the check-in action on Home. No system notifications.',
                ),
                value: d.checkIns,
                onChanged: (v) => controller.change(() => d.checkIns = v),
              ),
              SwitchListTile(
                title: const Text('Future sharing preference'),
                subtitle: const Text(
                  'Saved locally only. Cross-device sharing is not connected.',
                ),
                value: d.sharing,
                onChanged: (v) => controller.change(() => d.sharing = v),
              ),
            ],
          ),
        ),
        const SectionTitle('Your stories stay here'),
        SoftCard(
          color: sky,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(controller.dataSummary),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(
                      ClipboardData(text: controller.dataSummary),
                    );
                    if (context.mounted) {
                      feedback(context, true, 'Local data summary copied.');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Clipboard is unavailable on this device.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy data summary'),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () => clear('memories', 'Clear all memories?'),
          child: const Text('Clear Memory Garden'),
        ),
        OutlinedButton(
          onPressed: () => clear('chat', 'Clear conversation?'),
          child: const Text('Clear chat history'),
        ),
        OutlinedButton(
          onPressed: () =>
              clear('history', 'Clear sensor and activity history?'),
          child: const Text('Clear sensor & activity history'),
        ),
        OutlinedButton(
          onPressed: () => clear('reset', 'Start a new story?'),
          child: const Text('Reset all demo data'),
        ),
        const Text(
          'This simulator stores a versioned JSON document in shared preferences. Storage is local and unencrypted. No accounts, analytics, remote sharing, camera or microphones are used. Clearing browser data or uninstalling may delete your stories.',
        ),
        const Text(
          'Future work: real sensors and firmware, weather services, LLM/RAG, encrypted storage, family accounts, camera, voice and video. None are required to enjoy this local companion.',
        ),
      ],
    );
  }
}
