import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;

  void _prevMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
        _selectedDay = null;
      });

  void _nextMonth() => setState(() {
        _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
        _selectedDay = null;
      });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardTheme = Theme.of(context).cardTheme;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = cardTheme.color ?? colorScheme.surface;
    final divBorder = colorScheme.outlineVariant.withValues(alpha: 0.5);
    final textColor = colorScheme.onSurface;
    final subColor = colorScheme.onSurfaceVariant;

    return ref.watch(allTasksProvider).when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => _ErrorView(error: e.toString(), onRetry: () => ref.invalidate(allTasksProvider)),
          data: (tasks) {
            // Group tasks by date string
            final Map<String, List<TaskModel>> tasksByDate = {};
            for (final t in tasks) {
              tasksByDate.putIfAbsent(t.date, () => []).add(t);
            }

            final selectedTasks = _selectedDay == null
                ? <TaskModel>[]
                : tasksByDate[DateFormat('yyyy-MM-dd').format(_selectedDay!)] ?? [];

            return Scaffold(
              backgroundColor: bg,
              appBar: AppBar(
                backgroundColor: bg,
                title: const Text('History'),
              ),
              body: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _MonthCalendar(
                        viewMonth: _viewMonth,
                        tasksByDate: tasksByDate,
                        selectedDay: _selectedDay,
                        colorScheme: colorScheme,
                        cardBg: cardBg,
                        divBorder: divBorder,
                        textColor: textColor,
                        subColor: subColor,
                        onPrev: _prevMonth,
                        onNext: _nextMonth,
                        onDayTap: (d) => setState(() => _selectedDay = d),
                      ),
                    ),
                  ),

                  // Selected day task list
                  if (_selectedDay != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Text(
                          DateFormat('EEEE, d MMMM').format(_selectedDay!).toUpperCase(),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subColor, letterSpacing: 1),
                        ),
                      ),
                    ),
                    selectedTasks.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                              child: _EmptyDayState(colorScheme: colorScheme),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _DayTaskTile(
                                  task: selectedTasks[i],
                                  colorScheme: colorScheme,
                                  cardBg: cardBg,
                                  divBorder: divBorder,
                                  textColor: textColor,
                                  subColor: subColor,
                                ),
                                childCount: selectedTasks.length,
                              ),
                            ),
                          ),
                  ],

                  // Past Performance
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text('PAST PERFORMANCE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subColor, letterSpacing: 1)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final datesWithTasks = tasksByDate.keys.toList()..sort((a, b) => b.compareTo(a));
                          if (datesWithTasks.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: Text('No performance data yet.', style: TextStyle(color: subColor))),
                            );
                          }
                          if (i >= datesWithTasks.length) return null;
                          final dateStr = datesWithTasks[i];
                          final dayTasks = tasksByDate[dateStr]!;
                          final completed = dayTasks.where((t) => t.status == TaskStatus.completed).length;
                          final total = dayTasks.length;
                          final pct = total == 0 ? 0 : (completed / total * 100).round();
                          final date = DateTime.parse(dateStr);
                          return _PerformanceTile(
                            date: date,
                            completed: completed,
                            total: total,
                            pct: pct,
                            colorScheme: colorScheme,
                            cardBg: cardBg,
                            divBorder: divBorder,
                            textColor: textColor,
                            subColor: subColor,
                          );
                        },
                        childCount: tasksByDate.keys.isEmpty ? 1 : tasksByDate.keys.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
  }
}

class _MonthCalendar extends StatelessWidget {
  final DateTime viewMonth;
  final Map<String, List<TaskModel>> tasksByDate;
  final DateTime? selectedDay;
  final ColorScheme colorScheme;
  final Color cardBg, divBorder, textColor, subColor;
  final VoidCallback onPrev, onNext;
  final ValueChanged<DateTime> onDayTap;

  const _MonthCalendar({
    required this.viewMonth,
    required this.tasksByDate,
    required this.selectedDay,
    required this.colorScheme,
    required this.cardBg,
    required this.divBorder,
    required this.textColor,
    required this.subColor,
    required this.onPrev,
    required this.onNext,
    required this.onDayTap,
  });



  Color _dotColor(List<TaskModel>? tasks) {
    if (tasks == null || tasks.isEmpty) return Colors.transparent;
    final total = tasks.length;
    final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
    final missed = tasks.where((t) => t.status == TaskStatus.missed).length;
    if (completed == total) return colorScheme.tertiary;
    if (missed > 0) return colorScheme.error;
    return colorScheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = viewMonth;
    final nextMonth = DateTime(viewMonth.year, viewMonth.month + 1, 1);
    final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;
    // weekday: 1=Mon, 7=Sun → we want Sun=0 offset
    final startOffset = (firstDay.weekday % 7); // Sun=0, Mon=1, ...

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divBorder),
      ),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: onPrev, icon: Icon(Icons.chevron_left_rounded, size: 20, color: subColor)),
              Text(
                DateFormat('MMMM yyyy').format(viewMonth),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: textColor),
              ),
              IconButton(onPressed: onNext, icon: Icon(Icons.chevron_right_rounded, size: 20, color: subColor)),
            ],
          ),
          const SizedBox(height: 8),
          // Day of week headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((d) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(d, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: subColor)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
              childAspectRatio: 2.8, // Adjusted for larger fonts
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox();
              final dayNum = index - startOffset + 1;
              final date = DateTime(viewMonth.year, viewMonth.month, dayNum);
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final dayTasks = tasksByDate[dateStr];
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final isSelected = selectedDay != null &&
                  date.year == selectedDay!.year &&
                  date.month == selectedDay!.month &&
                  date.day == selectedDay!.day;
              final dot = _dotColor(dayTasks);

              return GestureDetector(
                onTap: () => onDayTap(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? colorScheme.primary 
                      : (isToday ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected 
                        ? colorScheme.primary 
                        : (isToday ? colorScheme.primary.withValues(alpha: 0.5) : Colors.transparent),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : (isToday ? colorScheme.primary : textColor),
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (dot != Colors.transparent)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : dot,
                            shape: BoxShape.circle,
                            boxShadow: isSelected ? null : [
                              BoxShadow(
                                color: dot.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Legend
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: colorScheme.tertiary, label: 'All done', colorScheme: colorScheme),
              const SizedBox(width: 16),
              _Legend(color: colorScheme.secondary, label: 'Partial', colorScheme: colorScheme),
              const SizedBox(width: 16),
              _Legend(color: colorScheme.error, label: 'Missed', colorScheme: colorScheme),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final ColorScheme colorScheme;
  const _Legend({required this.color, required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6))),
    ]);
  }
}

class _DayTaskTile extends StatelessWidget {
  final TaskModel task;
  final ColorScheme colorScheme;
  final Color cardBg, divBorder, textColor, subColor;

  const _DayTaskTile({
    required this.task,
    required this.colorScheme,
    required this.cardBg,
    required this.divBorder,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status) {
      TaskStatus.completed => colorScheme.tertiary,
      TaskStatus.missed => colorScheme.error,
      TaskStatus.remaining => colorScheme.outline,
      TaskStatus.assigned => colorScheme.secondary,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divBorder),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 36, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor))),
                    if (task.recurrence != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.repeat_rounded, size: 8, color: colorScheme.primary),
                            const SizedBox(width: 2),
                            Text(
                              task.recurrence!.toUpperCase(),
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Text(
                  '${DateFormat('h:mm a').format(task.startTime)} · ${task.durationMinutes}min · ${task.status.label}',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceTile extends StatelessWidget {
  final DateTime date;
  final int completed, total, pct;
  final ColorScheme colorScheme;
  final Color cardBg, divBorder, textColor, subColor;

  const _PerformanceTile({
    required this.date,
    required this.completed,
    required this.total,
    required this.pct,
    required this.colorScheme,
    required this.cardBg,
    required this.divBorder,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    final pctColor = pct >= 80 ? colorScheme.tertiary : pct >= 40 ? colorScheme.secondary : colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pctColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle_rounded, color: pctColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEE, MMM d').format(date), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textColor)),
                Text('$completed/$total tasks completed', style: TextStyle(color: subColor, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: pctColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$pct%', style: TextStyle(fontWeight: FontWeight.w700, color: pctColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyDayState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        Icon(Icons.event_busy_rounded, size: 32, color: colorScheme.onSurface.withValues(alpha: 0.2)),
        const SizedBox(height: 8),
        Text('No tasks on this day', style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.missed),
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ]),
      ),
    );
  }
}
