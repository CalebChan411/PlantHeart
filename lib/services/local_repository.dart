import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_data.dart';
import '../models/plant_collection.dart';

class LoadResult {
  final PlantCollection collection;
  PlantData get data => collection.active.data;
  final String? warning;
  const LoadResult(this.collection, [this.warning]);
}

class LocalRepository {
  static const key = 'plant_heart_v1';
  final SharedPreferences preferences;
  bool? _legacyBackupConfirmed;
  LocalRepository(this.preferences);
  Future<LoadResult> load() async {
    final raw = preferences.get(key);
    if (raw == null) return LoadResult(PlantCollection.single(PlantData()));
    try {
      if (raw is! String) throw const FormatException('Invalid document');
      return LoadResult(PlantCollection.decode(raw));
    } catch (_) {
      // Keep the original key untouched until a deliberate user edit. Save a
      // recovery copy first, including when a previous recovery already exists.
      final backupKey =
          '${key}_recovery_${DateTime.now().microsecondsSinceEpoch}';
      final copied = await preferences.setString(backupKey, raw.toString());
      if (!copied) throw StateError('Could not preserve unreadable local data');
      return LoadResult(
        PlantCollection.single(PlantData()),
        'Saved data could not be read. The original was preserved in a local recovery copy. Defaults are shown.',
      );
    }
  }

  Future<void> save(String document) async {
    // Retain one original legacy document before the first multi-plant write.
    // If the backup cannot be written, leave the original document untouched.
    const backup = '${key}_before_multi_plant';
    final previous = preferences.get(key);
    if (previous is String) {
      try {
        final old = jsonDecode(previous);
        if (old is Map && old['version'] == 1) {
          _legacyBackupConfirmed ??= preferences.containsKey(backup);
          if (!_legacyBackupConfirmed!) {
            if (!await preferences.setString(backup, previous)) {
              // SharedPreferences can update its cache even after a failed disk
              // write; retry this backup rather than trusting cache membership.
              throw StateError('Could not preserve the single-plant document');
            }
            _legacyBackupConfirmed = true;
          }
        }
      } on FormatException {
        /* Unreadable originals are handled by load(). */
      }
    }
    if (!await preferences.setString(key, document)) {
      throw StateError('Local storage rejected the write');
    }
  }
}
