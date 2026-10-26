import 'package:flutter/material.dart';
import '../../app/plant_controller.dart';
import '../tools.dart';
import 'nearby.dart';
import 'plant_talk.dart';

class CommunityPage extends StatefulWidget {
  final PlantController controller;
  const CommunityPage({super.key, required this.controller});
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final item in [(0, 'Nearby'), (1, 'Plant talk'), (2, 'Feed')])
              ChoiceChip(
                label: Text(item.$2),
                selected: selected == item.$1,
                onSelected: (_) => setState(() => selected = item.$1),
              ),
          ],
        ),
      ),
      Expanded(
        child: switch (selected) {
          0 => NearbyPage(controller: widget.controller),
          1 => PlantTalkPage(controller: widget.controller),
          _ => CommunityFeed(controller: widget.controller),
        },
      ),
    ],
  );
}
