import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';

class StreakHistoryScreen extends StatelessWidget {
  const StreakHistoryScreen({super.key, this.embeddedMode = false});
  final bool embeddedMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Streak History',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: const [
          _TopStreakCard(),
          SizedBox(height: 16),
          _CalendarPathCard(),
          SizedBox(height: 16),
          _WeeklyInsightsGrid(),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _TopStreakCard extends ConsumerWidget {
  const _TopStreakCard();

  int _calculateStreak(List<TaskModel> tasks) {
    final completedDates = tasks
        .where((t) => t.status == TaskStatus.completed)
        .map((t) => t.date)
        .toSet()
        .toList();
    if (completedDates.isEmpty) return 0;

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    if (!completedDates.contains(todayStr) && !completedDates.contains(yesterdayStr)) {
       return 0;
    }

    int streak = 0;
    DateTime currentCheck = completedDates.contains(todayStr) ? now : now.subtract(const Duration(days: 1));

    while (true) {
      final checkStr = DateFormat('yyyy-MM-dd').format(currentCheck);
      if (completedDates.contains(checkStr)) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardTheme = Theme.of(context).cardTheme;
    
    final cardDecoration = BoxDecoration(
      color: cardTheme.color ?? colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: cardDecoration,
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ref.watch(allTasksProvider).when(
                data: (tasks) => Text(
                  '${_calculateStreak(tasks)}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    height: 1.0,
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('0'),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Day Streak!',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarPathCard extends ConsumerWidget {
  const _CalendarPathCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardTheme = Theme.of(context).cardTheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: (){}, icon: Icon(Icons.chevron_left_rounded, size: 20, color: colorScheme.onSurfaceVariant)),
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(onPressed: (){}, icon: Icon(Icons.chevron_right_rounded, size: 20, color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Text(
                day,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ref.watch(allTasksProvider).when(
            data: (tasks) {
              final firstDay = DateTime(DateTime.now().year, DateTime.now().month, 1);
              final startOffset = firstDay.weekday % 7;
              final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 1).subtract(const Duration(days: 1)).day;
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 0,
                  childAspectRatio: 3.5, // Even flatter for horizontal stretch
                ),
                itemCount: 42,
                itemBuilder: (context, index) {
                  final dayNum = index - startOffset + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
                  
                  final isToday = dayNum == DateTime.now().day;
                  
                  return Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isToday ? Border.all(color: colorScheme.primary.withOpacity(0.5), width: 1) : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isToday ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.4),
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const SizedBox(height: 200),
            error: (_, __) => const SizedBox(height: 200),
          ),
        ],
      ),
    );
  }
}

class _WeeklyInsightsGrid extends ConsumerWidget {
  const _WeeklyInsightsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(allTasksProvider).when(
      data: (tasks) {
        // Calculate dynamic weekly insight (simplistic past 4 days)
        final now = DateTime.now();
        List<Widget> cards = [];
        for (int i = 3; i >= 0; i--) {
           final date = now.subtract(Duration(days: i));
           final dateStr = DateFormat('yyyy-MM-dd').format(date);
           final dayTasks = tasks.where((t) => t.date == dateStr).toList();
           final completed = dayTasks.where((t) => t.status == TaskStatus.completed).length;
           double prog = dayTasks.isEmpty ? 0 : completed / dayTasks.length;
           cards.add(_MiniInsightCard(
             day: DateFormat('EEE').format(date), 
             date: DateFormat('MMM d').format(date), 
             progress: prog
           ));
        }
        
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: cards,
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _MiniInsightCard extends StatelessWidget {
  final String day;
  final String date;
  final double progress;

  const _MiniInsightCard({
    required this.day,
    required this.date,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardTheme = Theme.of(context).cardTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Text(
             '$day, $date',
             style: TextStyle(
               color: colorScheme.onSurface,
               fontSize: 13,
               fontWeight: FontWeight.w600,
             ),
           ),
        ],
      ),
    );
  }
}

// End of file
