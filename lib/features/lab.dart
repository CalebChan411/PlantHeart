import 'package:flutter/material.dart';
import '../app/plant_controller.dart';
import '../widgets/design.dart';
import '../services/engines.dart';

class LabPage extends StatelessWidget {
  final PlantController controller;
  const LabPage({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    final s = controller.data.sensors;
    return PageBody(
      title: 'A tiny plant lab.',
      subtitle: 'Try a scenario. See how your friend responds.',
      eyebrow: 'CURIOUS BY NATURE',
      children: [
        const Tag('Local sensor simulation · no device connected', color: sky),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in SensorService.presets.keys)
              ActionChip(
                label: Text(name),
                onPressed: () async {
                  await reportSave(
                    context,
                    controller.preset(name),
                    '$name applied to all plant views.',
                  );
                },
              ),
          ],
        ),
        SoftCard(
          child: Column(
            children: [
              _slider(
                'Soil moisture',
                '${s.moisture.round()}%',
                s.moisture,
                0,
                100,
                (v) => controller.sensors(
                  controller.data.sensors.copyWith(moisture: v),
                ),
              ),
              _slider(
                'Light intensity',
                '${s.light.round()} lux',
                s.light,
                0,
                30000,
                (v) => controller.sensors(
                  controller.data.sensors.copyWith(light: v),
                ),
              ),
              _slider(
                'Temperature',
                '${s.temperature.toStringAsFixed(1)}°C',
                s.temperature,
                0,
                50,
                (v) => controller.sensors(
                  controller.data.sensors.copyWith(temperature: v),
                ),
              ),
              _slider(
                'Air humidity',
                '${s.humidity.round()}%',
                s.humidity,
                0,
                100,
                (v) => controller.sensors(
                  controller.data.sensors.copyWith(humidity: v),
                ),
              ),
              _slider(
                'Soil pH',
                s.ph.toStringAsFixed(1),
                s.ph,
                0,
                14,
                (v) =>
                    controller.sensors(controller.data.sensors.copyWith(ph: v)),
              ),
            ],
          ),
        ),
        SoftCard(
          color: mint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${controller.emotion.mood} · ${controller.care.first.title}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(controller.care.first.reason),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  await reportSave(
                    context,
                    controller.saveSnapshot(),
                    'Sensor snapshot saved.',
                  );
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save sensor snapshot'),
              ),
            ],
          ),
        ),
        const SectionTitle('A little history'),
        if (controller.data.snapshots.isEmpty)
          const SoftCard(
            child: Text(
              'No snapshots yet. Save a reading to start your moisture story.',
            ),
          ),
        for (final snapshot in controller.data.snapshots.reversed.take(10))
          SoftCard(
            padding: const EdgeInsets.all(12),
            child: ExpansionTile(
              title: Text(
                '${snapshot.reading.moisture.round()}% soil moisture',
              ),
              subtitle: Text(dateLabel(snapshot.at)),
              children: [
                LinearProgressIndicator(
                  value: snapshot.reading.moisture / 100,
                  minHeight: 6,
                ),
                const SizedBox(height: 12),
                Text(
                  'Light ${snapshot.reading.light.round()} lux · Temperature ${snapshot.reading.temperature.toStringAsFixed(1)}°C\n'
                  'Air humidity ${snapshot.reading.humidity.round()}% · pH ${snapshot.reading.ph.toStringAsFixed(1)}',
                ),
              ],
            ),
          ),
        const Text(
          'Showing the latest 10 of up to 100 saved readings. Sliders update Home, Care and the conversation simulator immediately.',
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 12,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value),
        ],
      ),
      Slider(
        semanticFormatterCallback: (next) =>
            '$label ${switch (label) {
              'Soil pH' => next.toStringAsFixed(1),
              'Light intensity' => '${next.round()} lux',
              'Temperature' => '${next.toStringAsFixed(1)}°C',
              _ => '${next.round()}%',
            }}',
        value: current,
        min: min,
        max: max,
        divisions: label == 'Soil pH'
            ? 140
            : label == 'Light intensity'
            ? 300
            : 100,
        label: value,
        onChanged: onChanged,
      ),
    ],
  );
}
