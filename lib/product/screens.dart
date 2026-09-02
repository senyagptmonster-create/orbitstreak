import 'dart:math';

import 'package:flutter/material.dart';

import '../app/brand.dart';
import '../app/theme.dart';
import 'orbit_store.dart';

IconData iconForName(String name) {
  return switch (name) {
    'fitness_center' => Icons.fitness_center_rounded,
    'menu_book' => Icons.menu_book_rounded,
    'water_drop' => Icons.water_drop_rounded,
    'code' => Icons.code_rounded,
    'bedtime' => Icons.bedtime_rounded,
    'directions_run' => Icons.directions_run_rounded,
    'psychology' => Icons.psychology_rounded,
    _ => Icons.star_rounded,
  };
}

/// Экран 1. Система орбит и список привычек
class OrbitHomeScreen extends StatelessWidget {
  const OrbitHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = OrbitScope.of(context);
    final habits = store.habits;

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Орбиты привычек', style: AppTheme.display(26)),
                          const SizedBox(height: 4),
                          Text(
                            '${store.todayCompletedCount} из ${habits.length} на сегодня',
                            style: AppTheme.text(13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: cSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cEdge),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: cAccent, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${(store.todayProgress * 100).toInt()}%',
                            style: AppTheme.text(14, color: cAccent, weight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 240,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: cSurface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cEdge),
                  boxShadow: [
                    BoxShadow(
                      color: cAccent.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: CustomPaint(
                    painter: _OrbitSolarSystemPainter(habits: habits),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Text('Твои привычки', style: AppTheme.display(18)),
              ),
            ),
            if (habits.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Нет активных планет-привычек', style: AppTheme.text(14, color: AppTheme.textMuted)),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: habits.length,
                itemBuilder: (context, i) {
                  final h = habits[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: h.isDoneToday ? Color(h.planetColorValue).withValues(alpha: 0.6) : cEdge,
                          width: h.isDoneToday ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Color(h.planetColorValue).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Color(h.planetColorValue), width: 2),
                          ),
                          child: Icon(iconForName(h.iconName), color: Color(h.planetColorValue), size: 20),
                        ),
                        title: Text(h.name, style: AppTheme.text(15.5, color: cInk, weight: FontWeight.w600)),
                        subtitle: Text(
                          '${h.currentStreak} дн. подряд · ${h.thisWeekCount}/${h.targetDaysPerWeek} на неделе',
                          style: AppTheme.text(12, color: AppTheme.textMuted),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            h.isDoneToday ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: h.isDoneToday ? Color(h.planetColorValue) : cEdge,
                            size: 28,
                          ),
                          onPressed: () => store.toggleHabit(h),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HabitDetailScreen(habit: h, store: store),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }
}

class _OrbitSolarSystemPainter extends CustomPainter {
  final List<Habit> habits;
  _OrbitSolarSystemPainter({required this.habits});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Центр - Солнце / ядро энергии
    final sunPaint = Paint()
      ..color = cAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, sunPaint);
    canvas.drawCircle(center, 22, Paint()..color = cAccent.withValues(alpha: 0.15));

    if (habits.isEmpty) return;

    final maxR = min(size.width, size.height) * 0.44;
    final rStep = habits.length > 1 ? (maxR - 26) / (habits.length) : maxR / 2;

    for (int i = 0; i < habits.length; i++) {
      final h = habits[i];
      final radius = 28 + (i + 1) * rStep;

      // Орбита
      final orbitPaint = Paint()
        ..color = h.isDoneToday
            ? Color(h.planetColorValue).withValues(alpha: 0.4)
            : cEdge.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h.isDoneToday ? 1.5 : 1.0;
      canvas.drawCircle(center, radius, orbitPaint);

      // Планета на орбите
      final angle = (i * (2 * pi / habits.length)) - (pi / 4);
      final px = center.dx + radius * cos(angle);
      final py = center.dy + radius * sin(angle);
      final planetRadius = h.isDoneToday ? 8.0 : 6.0;

      if (h.isDoneToday) {
        // Свечение планеты
        canvas.drawCircle(
          Offset(px, py),
          planetRadius * 2.0,
          Paint()..color = Color(h.planetColorValue).withValues(alpha: 0.3),
        );
      }

      final planetPaint = Paint()..color = Color(h.planetColorValue);
      canvas.drawCircle(Offset(px, py), planetRadius, planetPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitSolarSystemPainter oldDelegate) => true;
}

/// Экран 2. Детали привычки
class HabitDetailScreen extends StatelessWidget {
  const HabitDetailScreen({super.key, required this.habit, required this.store});

  final Habit habit;
  final OrbitStore store;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: cInk),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(habit.name, style: AppTheme.display(18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: cSurface,
                  title: Text('Удалить привычку?', style: AppTheme.display(18)),
                  content: Text('Вся история серии будет удалена.', style: AppTheme.text(14, color: cInk)),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await store.deleteHabit(habit);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Color(habit.planetColorValue).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(habit.planetColorValue).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(habit.planetColorValue), width: 3),
                    ),
                    child: Icon(iconForName(habit.iconName), color: Color(habit.planetColorValue), size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name, style: AppTheme.display(20)),
                        const SizedBox(height: 4),
                        Text('${habit.targetDaysPerWeek} дней в неделю', style: AppTheme.text(13, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: '${habit.currentStreak}',
                    label: 'Дней серия',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: cAccent2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: '${habit.completedDates.length}',
                    label: 'Всего отметок',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: Color(habit.planetColorValue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Последние 14 дней', style: AppTheme.display(18)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cEdge),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(14, (index) {
                  final day = now.subtract(Duration(days: 13 - index));
                  final isDone = habit.isCompletedOn(day);
                  return Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDone ? Color(habit.planetColorValue) : cBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDone ? Color(habit.planetColorValue) : cEdge),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isDone ? Colors.black : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(title, style: AppTheme.display(24, color: cInk)),
          const SizedBox(height: 4),
          Text(label, style: AppTheme.text(12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

/// Экран 3. Создание новой привычки
class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  int _targetDays = 7;
  int _selectedColor = 0xFF8AB4FF;
  String _selectedIcon = 'star';

  final _colors = [
    0xFF8AB4FF, 0xFFFFB4C8, 0xFF7EE787, 0xFFD2A8FF,
    0xFFFFD27A, 0xFF22D3EE, 0xFFFF7B72, 0xFFF2545B,
  ];

  final _icons = [
    'star', 'fitness_center', 'menu_book', 'water_drop',
    'code', 'bedtime', 'directions_run', 'psychology',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = OrbitScope.of(context);

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text('Новая орбита', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text('Добавь планету в свою систему привычек', style: AppTheme.text(13.5, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: AppTheme.text(16, color: cInk),
              decoration: InputDecoration(
                labelText: 'Название привычки',
                labelStyle: AppTheme.text(14, color: AppTheme.textMuted),
                filled: true,
                fillColor: cSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: cEdge)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: cEdge)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: cAccent, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Цвет планеты', style: AppTheme.display(16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((c) {
                final isSel = _selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = c),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 3),
                    ),
                    child: isSel ? const Icon(Icons.check, color: Colors.black, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Иконка', style: AppTheme.display(16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _icons.map((ic) {
                final isSel = _selectedIcon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSel ? cAccent.withValues(alpha: 0.25) : cSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSel ? cAccent : cEdge),
                    ),
                    child: Icon(iconForName(ic), color: isSel ? cAccent : AppTheme.textMuted, size: 20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Цель: $_targetDays дней в неделю', style: AppTheme.display(16)),
            Slider(
              value: _targetDays.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              activeColor: cAccent,
              onChanged: (v) => setState(() => _targetDays = v.round()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: cAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final text = _titleController.text.trim();
                  if (text.isEmpty) return;
                  await store.addHabit(
                    name: text,
                    colorValue: _selectedColor,
                    iconName: _selectedIcon,
                    targetDays: _targetDays,
                  );
                  _titleController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Планета-привычка запущена на орбиту!')),
                    );
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: Text('Запустить на орбиту', style: AppTheme.text(15, color: Colors.black, weight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Экран 4. Календарь
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = OrbitScope.of(context);
    final now = DateTime.now();
    const daysInMonth = 30;

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text('Звёздный календарь', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text('Карта твоей активности за 30 дней', style: AppTheme.text(13.5, color: AppTheme.textMuted)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cEdge),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final day = now.subtract(Duration(days: daysInMonth - 1 - index));
                  final completedHabitsCount = store.habits.where((h) => h.isCompletedOn(day)).length;
                  final intensity = store.habits.isEmpty ? 0.0 : completedHabitsCount / store.habits.length;

                  return Container(
                    decoration: BoxDecoration(
                      color: intensity > 0 ? cAccent.withValues(alpha: max(0.2, intensity)) : cBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: intensity > 0 ? cAccent : cEdge),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${day.day}', style: TextStyle(fontSize: 12, color: intensity > 0 ? Colors.white : AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        if (completedHabitsCount > 0)
                          Text('★ $completedHabitsCount', style: const TextStyle(fontSize: 9, color: cAccent2)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Экран 5. Настройки
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = OrbitScope.of(context);

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          children: [
            Text('Настройки', style: AppTheme.display(28)),
            const SizedBox(height: 4),
            Text('OrbitStreak v1.0.0', style: AppTheme.text(13.5, color: AppTheme.textMuted)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: cSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cEdge),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.public_rounded, color: cAccent),
                    title: Text('Активных орбит', style: AppTheme.text(15, color: cInk)),
                    trailing: Text('${store.habits.length}', style: AppTheme.text(15, color: cAccent, weight: FontWeight.w700)),
                  ),
                  const Divider(height: 1, color: cEdge),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: Colors.redAccent),
                    title: const Text('Сбросить все данные', style: TextStyle(color: Colors.redAccent)),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cSurface,
                          title: Text('Сбросить орбиты?', style: AppTheme.display(18)),
                          content: Text('Все привычки и серии будут удалены.', style: AppTheme.text(14, color: cInk)),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Отмена')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Сбросить'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await store.resetAll();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
