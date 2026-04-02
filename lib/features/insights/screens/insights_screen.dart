import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import 'streak_history_screen.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121418) : const Color(0xFFCAD8DF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Insights', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Streak')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _OverviewTab(isDark: isDark),
          const StreakHistoryBody(),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final bool isDark;
  const _OverviewTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(allTasksProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.missed),
          const SizedBox(height: 12),
          Text(e.toString(), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(allTasksProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ),
      data: (tasks) {
        final now = DateTime.now();

        // 7-day data
        final List<_DayData> weekData = List.generate(7, (i) {
          final date = now.subtract(Duration(days: 6 - i));
          final dateStr = DateFormat('yyyy-MM-dd').format(date);
          final dayTasks = tasks.where((t) => t.date == dateStr).toList();
          final completed = dayTasks.where((t) => t.status == TaskStatus.completed).length;
          return _DayData(
            label: DateFormat('E').format(date).substring(0, 1),
            total: dayTasks.length,
            completed: completed,
            isToday: i == 6,
          );
        });

        // Category breakdown
        final Map<TaskCategory, int> catMap = {};
        for (final t in tasks) {
          if (t.category != null) catMap[t.category!] = (catMap[t.category!] ?? 0) + 1;
        }

        // Summary stats
        final totalAll = tasks.length;
        final completedAll = tasks.where((t) => t.status == TaskStatus.completed).length;
        final missedAll = tasks.where((t) => t.status == TaskStatus.missed).length;
        final completionRate = totalAll == 0 ? 0.0 : completedAll / totalAll;

        // Best day
        final best = weekData.isEmpty ? null : weekData.reduce((a, b) {
          final aRate = a.total == 0 ? 0.0 : a.completed / a.total;
          final bRate = b.total == 0 ? 0.0 : b.completed / b.total;
          return aRate >= bRate ? a : b;
        });

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Summary cards row
            Row(children: [
              Expanded(child: _StatCard(label: 'Total Tasks', value: '$totalAll', icon: Icons.task_alt_rounded, color: AppColors.assigned, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Completed', value: '$completedAll', icon: Icons.check_circle_rounded, color: AppColors.completed, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Missed', value: '$missedAll', icon: Icons.cancel_rounded, color: AppColors.missed, isDark: isDark)),
            ]),
            const SizedBox(height: 16),

            // Completion rate card
            _RateCard(rate: completionRate, isDark: isDark),
            const SizedBox(height: 16),

            // 7-day bar chart
            _BarChartCard(weekData: weekData, isDark: isDark),
            const SizedBox(height: 16),

            // Best day
            if (best != null && best.total > 0)
              _InfoCard(
                icon: Icons.star_rounded,
                color: AppColors.primary,
                title: 'Best day this week',
                subtitle: 'You were most productive on a ${_expandDay(best.label)} (${best.completed}/${best.total} tasks)',
                isDark: isDark,
              ),
            const SizedBox(height: 16),

            // Category breakdown
            if (catMap.isNotEmpty) ...[
              _CategoryCard(catMap: catMap, isDark: isDark),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  String _expandDay(String abbr) {
    final map = {'M': 'Monday', 'T': 'Tuesday', 'W': 'Wednesday', 'F': 'Friday', 'S': 'Saturday', 'U': 'Sunday'};
    return map[abbr] ?? abbr;
  }
}

class _DayData {
  final String label;
  final int total, completed;
  final bool isToday;
  const _DayData({required this.label, required this.total, required this.completed, required this.isToday});
  double get rate => total == 0 ? 0.0 : completed / total;
}

// ── Stat Cards ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E202B) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87)),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
      ]),
    );
  }
}

class _RateCard extends StatelessWidget {
  final double rate;
  final bool isDark;
  const _RateCard({required this.rate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = (rate * 100).round();
    final color = pct >= 70 ? AppColors.completed : pct >= 40 ? AppColors.assigned : AppColors.missed;
    final cardBg = isDark ? const Color(0xFF1E202B) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        SizedBox(
          width: 64, height: 64,
          child: Stack(fit: StackFit.expand, children: [
            CircularProgressIndicator(value: 1.0, strokeWidth: 7, color: isDark ? Colors.white10 : Colors.black12),
            CircularProgressIndicator(value: rate.clamp(0.0, 1.0), strokeWidth: 7, backgroundColor: Colors.transparent, color: color, strokeCap: StrokeCap.round),
            Center(child: Text('$pct%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Overall Completion Rate', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(
            pct >= 70 ? 'Great work! Keep it up 🔥' : pct >= 40 ? 'Room to improve — you got this!' : 'Let\'s build a stronger streak!',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
          ),
        ])),
      ]),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  final List<_DayData> weekData;
  final bool isDark;
  const _BarChartCard({required this.weekData, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E202B) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('7-Day Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekData.map((d) {
              final barHeight = d.total == 0 ? 4.0 : math.max(4.0, d.rate * 100);
              final completedH = d.total == 0 ? 0.0 : (d.completed / d.total * barHeight);
              final color = d.isToday ? AppColors.primary : AppColors.assigned;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Text('${d.completed}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(children: [
                        Container(height: barHeight, color: (isDark ? Colors.white10 : Colors.black12)),
                        Container(height: completedH, color: color),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Text(d.label, style: TextStyle(
                      fontSize: 12, fontWeight: d.isToday ? FontWeight.w700 : FontWeight.w500,
                      color: d.isToday ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
                    )),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          const _BarLegend(color: AppColors.primary, label: 'Today'),
          const SizedBox(width: 12),
          const _BarLegend(color: AppColors.assigned, label: 'Completed'),
          const SizedBox(width: 12),
          _BarLegend(color: isDark ? Colors.white10 : Colors.black12, label: 'Total'),
        ]),
      ]),
    );
  }
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _BarLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

// ── Category Donut ────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final Map<TaskCategory, int> catMap;
  final bool isDark;
  const _CategoryCard({required this.catMap, required this.isDark});

  static const _catColors = {
    TaskCategory.work: Color(0xFF60A5FA),
    TaskCategory.personal: Color(0xFF34D399),
    TaskCategory.health: Color(0xFFFB923C),
    TaskCategory.learning: Color(0xFFA78BFA),
    TaskCategory.finance: Color(0xFFFBBF24),
    TaskCategory.social: Color(0xFFF472B6),
    TaskCategory.other: Color(0xFF94A3B8),
  };

  @override
  Widget build(BuildContext context) {
    final total = catMap.values.fold(0, (a, b) => a + b);
    final cardBg = isDark ? const Color(0xFF1E202B) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Category Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textColor)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(
            width: 100, height: 100,
            child: CustomPaint(painter: _DonutPainter(catMap: catMap, colors: _catColors, total: total)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: catMap.entries.map((e) {
                final pct = (e.value / total * 100).round();
                final color = _catColors[e.key] ?? Colors.grey;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.key.label, style: TextStyle(fontSize: 12, color: textColor))),
                    Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: subColor)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<TaskCategory, int> catMap;
  final Map<TaskCategory, Color> colors;
  final int total;
  const _DonutPainter({required this.catMap, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    double startAngle = -math.pi / 2;
    const strokeWidth = 18.0;

    for (final entry in catMap.entries) {
      final sweep = entry.value / total * 2 * math.pi;
      final paint = Paint()
        ..color = colors[entry.key] ?? Colors.grey
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle, sweep, false, paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

// ── Info card ────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool isDark;
  const _InfoCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E202B) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
        ])),
      ]),
    );
  }
}

// ── Streak History body (reuse streak_history_screen's body) ──────

class StreakHistoryBody extends StatelessWidget {
  const StreakHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const StreakHistoryScreen(embeddedMode: true);
  }
}
