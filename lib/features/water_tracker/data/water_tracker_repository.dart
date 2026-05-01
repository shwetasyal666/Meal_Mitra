import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mealmitra/features/water_tracker/domain/water_target.dart';

final waterTrackerRepositoryProvider = Provider<WaterTrackerRepository>((ref) {
  return WaterTrackerRepository();
});

class WaterTrackerRepository {
  static const _prefix = 'water_tracker_';

  String _key(String date) => '$_prefix$date';

  String get _today => DateTime.now().toIso8601String().split('T').first;

  Future<int> getGlassesToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(_today)) ?? 0;
  }

  Future<void> setGlassesToday(int glasses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(_today), glasses.clamp(0, 99));
  }

  Future<void> addGlass() async {
    final current = await getGlassesToday();
    await setGlassesToday(current + 1);
  }

  Future<void> removeGlass() async {
    final current = await getGlassesToday();
    if (current > 0) {
      await setGlassesToday(current - 1);
    }
  }

  Future<void> resetToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(_today));
  }

  Future<List<WaterDayRecord>> getLastWeekRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final records = <WaterDayRecord>[];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T').first;
      final key = _key(dateStr);
      final glasses = prefs.getInt(key) ?? 0;
      if (glasses > 0) {
        records.add(WaterDayRecord(date: dateStr, glassesTaken: glasses));
      }
    }

    return records.reversed.toList();
  }
}

final todayGlassesProvider = StateNotifierProvider<WaterNotifier, int>((ref) {
  return WaterNotifier(ref.watch(waterTrackerRepositoryProvider));
});

class WaterNotifier extends StateNotifier<int> {
  final WaterTrackerRepository _repository;

  WaterNotifier(this._repository) : super(0) {
    _loadToday();
  }

  Future<void> _loadToday() async {
    state = await _repository.getGlassesToday();
  }

  Future<void> addGlass() async {
    await _repository.addGlass();
    state = await _repository.getGlassesToday();
  }

  Future<void> removeGlass() async {
    await _repository.removeGlass();
    state = await _repository.getGlassesToday();
  }

  Future<void> setGlasses(int count) async {
    await _repository.setGlassesToday(count);
    state = await _repository.getGlassesToday();
  }
}
