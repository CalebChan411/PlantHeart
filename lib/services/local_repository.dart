import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_data.dart';

class LoadResult {
  final PlantData data;
  final String? warning;
  const LoadResult(this.data, [this.warning]);
}

class LocalRepository {
  static const key = 'plant_heart_v1';
  final SharedPreferences preferences;
  LocalRepository(this.preferences);
  Future<LoadResult> load() async {
    final raw = preferences.get(key);
    if (raw == null) return LoadResult(PlantData());
    try {
      if (raw is! String) throw const FormatException('Invalid document');
      return LoadResult(PlantData.decode(raw));
    } catch (_) {
      // Keep the original key untouched until a deliberate user edit. Save a
      // recovery copy first, including when a previous recovery already exists.
      final backupKey =
          '${key}_recovery_${DateTime.now().microsecondsSinceEpoch}';
      final copied = await preferences.setString(backupKey, raw.toString());
      if (!copied) throw StateError('Could not preserve unreadable local data');
      return LoadResult(
        PlantData(),
        'Saved data could not be read. The original was preserved in a local recovery copy. Defaults are shown.',
      );
    }
  }

  Future<void> save(String document) async {
    if (!await preferences.setString(key, document)) {
      throw StateError('Local storage rejected the write');
    }
  }
}
