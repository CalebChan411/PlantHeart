import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'models/expression_frame.dart';
import 'features/expression_screen/expression_screen.dart';
import 'app/plant_controller.dart';
import 'services/local_repository.dart';

Future<void> main(List<String> arguments) async {
  WidgetsFlutterBinding.ensureInitialized();
  final source = displaySource(arguments);
  if (source != null) {
    runApp(ExpressionDisplayApp(source: source));
    return;
  }
  try {
    final repository = LocalRepository(await SharedPreferences.getInstance());
    final loaded = await repository.load();
    runApp(
      PlantHeartApp(
        controller: PlantController(
          repository,
          loaded.data,
          collection: loaded.collection,
          notice: loaded.warning,
        ),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Your local stories could not be opened. Check storage permissions or available disk space. Existing data has not been reset.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => main(arguments),
                    child: const Text('Retry opening Plant Heart'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
