import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Habit {
  final String id;
  String name;
  int planetColorValue;
  String iconName;
  int targetDaysPerWeek;
  final Set<String> completedDates;

  Habit({
    required this.id,
    required this.name,
    required this.planetColorValue,
    required this.iconName,
    this.targetDaysPerWeek = 7,
    Set<String>? completedDates,
  }) : completedDates = completedDates ?? {};

  static String dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool isCompletedOn(DateTime dt) => completedDates.contains(dateKey(dt));
  bool get isDoneToday => isCompletedOn(DateTime.now());

  void toggleToday() {
    final key = dateKey(DateTime.now());
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  int get currentStreak {
    int streak = 0;
    var check = DateTime.now();
    if (!isCompletedOn(check)) {
      check = check.subtract(const Duration(days: 1));
      if (!isCompletedOn(check)) return 0;
    }

    while (isCompletedOn(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get thisWeekCount {
    int count = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      if (isCompletedOn(d)) count++;
    }
    return count;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'planetColorValue': planetColorValue,
        'iconName': iconName,
        'targetDaysPerWeek': targetDaysPerWeek,
        'completedDates': completedDates.toList(),
      };

  static Habit fromJson(Map<String, dynamic> j) => Habit(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        planetColorValue: (j['planetColorValue'] as num?)?.toInt() ?? 0xFF8AB4FF,
        iconName: (j['iconName'] ?? 'star').toString(),
        targetDaysPerWeek: (j['targetDaysPerWeek'] as num?)?.toInt() ?? 7,
        completedDates: (j['completedDates'] as List? ?? [])
            .map((e) => e.toString())
            .toSet(),
      );
}

class OrbitStore extends ChangeNotifier {
  static const _key = 'orbitstreak_habits_v1';

  final List<Habit> _habits = [];
  bool _ready = false;

  bool get ready => _ready;
  List<Habit> get habits => List.unmodifiable(_habits);

  int get todayCompletedCount => _habits.where((h) => h.isDoneToday).length;
  double get todayProgress =>
      _habits.isEmpty ? 0 : todayCompletedCount / _habits.length;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _habits.clear();
        for (final item in list) {
          _habits.add(Habit.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (_) {}

    if (_habits.isEmpty) {
      _seedDemoHabits();
    }

    _ready = true;
    notifyListeners();
  }

  void _seedDemoHabits() {
    final now = DateTime.now();
    _habits.addAll([
      Habit(
        id: 'h1',
        name: 'Утренняя зарядка',
        planetColorValue: 0xFF8AB4FF,
        iconName: 'fitness_center',
        targetDaysPerWeek: 7,
        completedDates: {
          Habit.dateKey(now),
          Habit.dateKey(now.subtract(const Duration(days: 1))),
          Habit.dateKey(now.subtract(const Duration(days: 2))),
          Habit.dateKey(now.subtract(const Duration(days: 3))),
          Habit.dateKey(now.subtract(const Duration(days: 4))),
        },
      ),
      Habit(
        id: 'h2',
        name: 'Чтение книги 20м',
        planetColorValue: 0xFFFFB4C8,
        iconName: 'menu_book',
        targetDaysPerWeek: 5,
        completedDates: {
          Habit.dateKey(now),
          Habit.dateKey(now.subtract(const Duration(days: 1))),
          Habit.dateKey(now.subtract(const Duration(days: 3))),
        },
      ),
      Habit(
        id: 'h3',
        name: 'Пить 2 литра воды',
        planetColorValue: 0xFF7EE787,
        iconName: 'water_drop',
        targetDaysPerWeek: 7,
        completedDates: {
          Habit.dateKey(now),
          Habit.dateKey(now.subtract(const Duration(days: 1))),
          Habit.dateKey(now.subtract(const Duration(days: 2))),
          Habit.dateKey(now.subtract(const Duration(days: 4))),
        },
      ),
      Habit(
        id: 'h4',
        name: 'Кодинг пет-проекта',
        planetColorValue: 0xFFD2A8FF,
        iconName: 'code',
        targetDaysPerWeek: 4,
        completedDates: {
          Habit.dateKey(now.subtract(const Duration(days: 1))),
          Habit.dateKey(now.subtract(const Duration(days: 2))),
        },
      ),
    ]);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_habits.map((h) => h.toJson()).toList());
      await prefs.setString(_key, raw);
    } catch (_) {}
  }

  Future<void> toggleHabit(Habit habit) async {
    habit.toggleToday();
    notifyListeners();
    await _persist();
  }

  Future<void> addHabit({
    required String name,
    required int colorValue,
    required String iconName,
    required int targetDays,
  }) async {
    final habit = Habit(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      planetColorValue: colorValue,
      iconName: iconName,
      targetDaysPerWeek: targetDays,
    );
    _habits.add(habit);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteHabit(Habit habit) async {
    _habits.removeWhere((h) => h.id == habit.id);
    notifyListeners();
    await _persist();
  }

  Future<void> resetAll() async {
    _habits.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

class OrbitScope extends InheritedNotifier<OrbitStore> {
  const OrbitScope({super.key, required OrbitStore store, required super.child})
      : super(notifier: store);

  static OrbitStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OrbitScope>();
    assert(scope != null, 'OrbitScope not found');
    return scope!.notifier!;
  }
}
