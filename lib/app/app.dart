import 'package:flutter/material.dart';
import '../features/chat.dart';
import '../features/garden.dart';
import '../features/home.dart';
import '../features/lab.dart';
import '../features/profile_form.dart';
import '../features/settings.dart';
import '../features/tools.dart';
import '../widgets/design.dart';
import 'plant_controller.dart';

class PlantHeartApp extends StatelessWidget {
  final PlantController controller;
  const PlantHeartApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      title: 'Plant Heart',
      debugShowCheckedModeBanner: false,
      theme: plantTheme(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              (media.textScaler.scale(14) /
                      14 *
                      (controller.data.largeText ? 1.25 : 1))
                  .clamp(1, 2),
            ),
          ),
          child: ColoredBox(
            color: const Color(0xFFEAF0E5),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child!,
              ),
            ),
          ),
        );
      },
      home: _Shell(controller: controller),
    ),
  );
}

class _Shell extends StatefulWidget {
  final PlantController controller;
  const _Shell({required this.controller});
  @override
  State<_Shell> createState() => _ShellState();
}

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
  Widget build(BuildContext context) => Scaffold(
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
        if (c.data.onboarded)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Tag('${c.data.checkInDays.length} care days'),
          ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          if (c.notice != null) _notice(c.notice!, c.dismissNotice, 'Dismiss'),
          if (c.storageError != null)
            _notice(c.storageError!, c.retrySave, 'Retry save'),
          Expanded(
            child: !c.data.onboarded
                ? ProfileForm(controller: c, onboarding: true)
                : switch (selected) {
                    0 => HomePage(
                      controller: c,
                      select: (i) => setState(() => selected = i),
                      openCare: care,
                      openWeather: weather,
                    ),
                    1 => LabPage(controller: c),
                    2 => ChatPage(controller: c),
                    3 => GardenPage(controller: c),
                    _ => _more(),
                  },
          ),
        ],
      ),
    ),
    bottomNavigationBar: c.data.onboarded
        ? NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (index) => setState(() => selected = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.science_outlined),
                selectedIcon: Icon(Icons.science_rounded),
                label: 'Lab',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.yard_outlined),
                selectedIcon: Icon(Icons.yard_rounded),
                label: 'Garden',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'More',
              ),
            ],
          )
        : null,
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
  Widget _more() => PageBody(
    title: 'A little more\nto explore.',
    subtitle: 'Everything you need for your green companion.',
    eyebrow: 'YOUR GROWING TOOLKIT',
    children: [
      for (final tool in <(IconData, String, String, VoidCallback)>[
        (
          Icons.favorite_outline,
          'Care Guide',
          'One clear next step for your plant',
          care,
        ),
        (
          Icons.wb_sunny_outlined,
          'Weather',
          'Try a different kind of day',
          weather,
        ),
        (
          Icons.people_outline,
          'Community',
          'A friendly, local-only neighborhood',
          () => open('Community', () => CommunityPage(controller: c)),
        ),
        (
          Icons.menu_book_outlined,
          'Plant Library',
          'Find your kind of green',
          () => open('Plant Library', () => LibraryPage(controller: c)),
        ),
        (
          Icons.settings_outlined,
          'Settings',
          'Profile, accessibility and your local data',
          () => open(
            'Settings',
            () => SettingsPage(controller: c, editProfile: profile),
          ),
        ),
      ])
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: mint,
              child: Icon(tool.$1, color: leaf),
            ),
            title: Text(
              tool.$2,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(tool.$3),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: tool.$4,
          ),
        ),
      const SoftCard(
        color: sky,
        child: Text(
          'Made for little moments of care.\nOffline by design. Simulated with honesty.',
        ),
      ),
    ],
  );
}
