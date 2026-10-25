import 'package:flutter/material.dart';
import '../features/chat.dart';
import '../features/add_plant.dart';
import '../features/expression_screen/expression_screen.dart';
import '../features/garden.dart';
import '../features/home.dart';
import '../features/lab.dart';
import '../features/profile_form.dart';
import '../features/settings.dart';
import '../features/tools.dart';
import '../features/test_window.dart';
import '../widgets/design.dart';
import 'plant_controller.dart';

class PlantHeartApp extends StatelessWidget {
  final PlantController controller;
  const PlantHeartApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Plant Heart',
    debugShowCheckedModeBanner: false,
    theme: plantTheme(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      // Preserve the navigator subtree during data writes. Only a changed
      // accessibility preference should invalidate inherited text scaling.
      return AnimatedBuilder(
        animation: controller,
        child: ColoredBox(
          color: const Color(0xFFEAF0E5),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child!,
            ),
          ),
        ),
        builder: (context, frame) => MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              (media.textScaler.scale(14) /
                      14 *
                      (controller.data.largeText ? 1.25 : 1))
                  .clamp(1, 2),
            ),
          ),
          child: frame!,
        ),
      );
    },
    home: _Shell(controller: controller),
  );
}

class _Shell extends StatefulWidget {
  final PlantController controller;
  const _Shell({required this.controller});
  @override
  State<_Shell> createState() => _ShellState();
}

const testingToolsEnabled = bool.fromEnvironment(
  'PLANT_HEART_TEST_TOOLS',
  defaultValue: true,
);

class _ShellState extends State<_Shell> {
  int selected = 0;
  PlantController get c => widget.controller;
  void open(String title, Widget Function() page) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => AnimatedBuilder(
        animation: c,
        builder: (context, _) => Scaffold(
          appBar: AppBar(title: Text(title), backgroundColor: cream),
          body: SafeArea(child: page()),
        ),
      ),
    ),
  );
  void care() => open('Care Guide', () => CarePage(controller: c));
  void weather() => open('Weather', () => WeatherPage(controller: c));
  void profile() => open('Plant profile', () => ProfileForm(controller: c));
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        backgroundColor: cream,
        scrolledUnderElevation: 0,
        titleSpacing: 22,
        title: const Row(
          children: [
            Icon(Icons.spa_rounded, color: leaf),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'plant heart',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (c.data.onboarded && selected == 0)
            IconButton(
              tooltip: 'Add plant',
              onPressed: () => showAddPlant(context, c),
              icon: const Icon(Icons.add_circle_rounded, color: leaf, size: 30),
            ),
          if (c.data.onboarded && selected != 0)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Tag('${c.data.checkInDays.length} care days'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (c.notice != null)
              _notice(c.notice!, c.dismissNotice, 'Dismiss'),
            if (c.storageError != null)
              _notice(c.storageError!, c.retrySave, 'Retry save'),
            Expanded(
              child: Semantics(
                key: const ValueKey('main-content'),
                container: true,
                explicitChildNodes: true,
                child: !c.data.onboarded
                    ? ProfileForm(controller: c, onboarding: true)
                    : switch (selected) {
                        0 => HomePage(
                          controller: c,
                          select: (i) => setState(() => selected = i),
                          openCare: care,
                          openWeather: weather,
                          editProfile: profile,
                        ),
                        1 => CommunityPage(controller: c),
                        2 => GardenPage(controller: c),
                        3 => CarePage(controller: c),
                        _ => _more(),
                      },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: c.data.onboarded
          ? NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  setState(() => selected = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Community',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories_rounded),
                  label: 'Memoir',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Care',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'More',
                ),
              ],
            )
          : null,
    ),
  );
  Widget _notice(String text, VoidCallback action, String label) => Container(
    color: sun,
    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
    child: Row(
      children: [
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        TextButton(onPressed: action, child: Text(label)),
      ],
    ),
  );
  Widget _tool(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => SoftCard(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: mint,
        child: Icon(icon, color: leaf),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: action,
    ),
  );
  void testWindow(String title, Widget Function() page) => showTestWindow(
    context,
    title: title,
    child: AnimatedBuilder(animation: c, builder: (_, _) => page()),
  );
  Widget _more() => PageBody(
    title: 'Your growing\ntoolkit.',
    subtitle: testingToolsEnabled
        ? 'Plant profiles, preferences and a separate space for prototype tests.'
        : 'Plant profiles, preferences and your local data.',
    eyebrow: 'MORE',
    children: [
      _tool(
        Icons.menu_book_outlined,
        'Plant Library',
        'Profiles for your selected plant',
        () => open('Plant Library', () => LibraryPage(controller: c)),
      ),
      _tool(
        Icons.settings_outlined,
        'Settings',
        'Profile, accessibility and local data',
        () => open(
          'Settings',
          () => SettingsPage(controller: c, editProfile: profile),
        ),
      ),
      if (testingToolsEnabled) ...[
        const SectionTitle('Prototype testing'),
        const Text(
          'These tools simulate future sensor and voice inputs. They are not everyday app destinations. No microphone, hardware or speech service is connected.',
        ),
        _tool(
          Icons.tune_rounded,
          'Sensor simulator',
          'Manually adjust readings and save test snapshots',
          () => testWindow('Sensor simulator', () => LabPage(controller: c)),
        ),
        _tool(
          Icons.mic_none_rounded,
          'Conversation simulator',
          'Type in place of future voice input; watch the reply animation',
          () => testWindow(
            'Conversation simulator',
            () => ChatPage(controller: c),
          ),
        ),
        _tool(
          Icons.wb_sunny_outlined,
          'Weather simulator',
          'Apply local weather scenarios to readings',
          () =>
              testWindow('Weather simulator', () => WeatherPage(controller: c)),
        ),
        _tool(
          Icons.grid_on_rounded,
          'Pixel Display Studio',
          'White pixel facial features and a separate display window',
          () => testWindow(
            'Pixel Display Studio',
            () => ExpressionScreenPage(controller: c),
          ),
        ),
      ],
      const SoftCard(
        color: sky,
        child: Text(
          'Community, Memoir and Care have their own main destinations. Core data stays on this device.',
        ),
      ),
    ],
  );
}
