import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/widgets/theme_toggle_switch.dart';
import '../../../data/models/task_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../../core/utils/pdf_generator.dart';
import '../widgets/interactive_clock_face.dart';

/// Main dashboard screen.
/// Shows a premium greeting, a live clock face for time blocking, 
/// and quick-action dashboard cards.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final dateStr   = DateFormat('EEEE, d MMMM').format(_now);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bgUrl     = ref.watch(backgroundPhotoProvider);

    Widget scaffold = Scaffold(
      backgroundColor: bgUrl != null ? Colors.transparent : (isDark ? AppColors.surfaceDark : const Color(0xFFE2EAF4)),
      
      // ── Custom Slipped AppBar ──────────────────────────────
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: bgUrl != null ? Colors.transparent : (isDark ? AppColors.surfaceDark : const Color(0xFFE2EAF4)),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Text(
                dateStr,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              background: Container(color: Colors.transparent),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.search_rounded, size: 20),
                  ),
                  onPressed: () => context.push('/home/search'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                        width: 1,
                      ),
                    ),
                    child: const Icon(Icons.person_rounded, size: 20),
                  ),
                  onPressed: () => context.push('/home/profile'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: isDark ? AppColors.cardDarkElevated : Colors.white,
                  onSelected: (value) => _handleMenuSelection(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'theme',
                      child: Row(
                        children: [
                          Icon(Icons.palette_rounded, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text('Change Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sort',
                      child: Row(
                        children: [
                          Icon(Icons.sort_rounded, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reorder',
                      child: Row(
                        children: [
                          Icon(Icons.drag_handle_rounded, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text('Reorder Tasks', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.content_copy_rounded, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text('Send Copy', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'print',
                      child: Row(
                        children: [
                          Icon(Icons.print_rounded, size: 20, color: Colors.grey),
                          SizedBox(width: 12),
                          Text('Print list', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Dashboard Content ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: ThemeToggleSwitch(),
                  ),
                  const SizedBox(height: 16),
                  userAsync.when(
                    loading: () => const SizedBox(height: 20),
                    error:   (_, __) => const SizedBox(height: 20),
                    data: (user) => _Greeting(userName: '${user?.displayName ?? 'User'}! 👋'),
                  ),
                  
                  const SizedBox(height: 16),
                  const _DateSelector(),
                  const SizedBox(height: 24), // space before clock
                  
                  // ── Interactive Task Clock ────────────────
                  ref.watch(tasksForDateProvider).when(
                    data: (tasks) => InteractiveClockFace(tasks: tasks, isDark: isDark),
                    loading: () => InteractiveClockFace(tasks: const [], isDark: isDark),
                    error:   (_, __) => InteractiveClockFace(tasks: const [], isDark: isDark),
                  ),
                  
                  const SizedBox(height: 24), // space after clock
                  
                  // ── Daily Progress ─────────────────────────
                  const _DailyProgressCard(),
                  const SizedBox(height: 24),
                  
                  // ── Quick Actions ────────────────────────────
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _QuickActionGrid(),
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Premium Floating Action Button ──────────────────────
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_task_fab',
        onPressed: () => context.push('/home/task-editor'),
        icon:  const Icon(Icons.add_rounded, size: 24),
        label: const Text('New Plan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      
      bottomNavigationBar: const _BottomNav(),
    );

    if (bgUrl != null) {
      final isNetwork = bgUrl.startsWith('http');
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: isNetwork ? NetworkImage(bgUrl) as ImageProvider : FileImage(File(bgUrl)),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8),
              BlendMode.darken,
            ),
          ),
        ),
        child: scaffold,
      );
    }

    return scaffold;
  }

  // ── Menu Handlers ──────────────────────────────────────────────────

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'theme': _showThemeDialog(); break;
      case 'sort': _showSortDialog(); break;
      case 'reorder': _showReorderSnackbar(); break;
      case 'copy': _copyTasksToClipboard(); break;
      case 'print': _showPrintSnackbar(); break;
    }
  }

  void _showThemeDialog() {
    final currentMode = ref.read(settingsProvider).themeMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('System'),
                  selected: currentMode == ThemeMode.system,
                  selectedColor: const Color(0xFFD3643B).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: Colors.black87,
                    fontWeight: currentMode == ThemeMode.system ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (v) => ref.read(settingsProvider.notifier).updateThemeMode(ThemeMode.system),
                ),
                ChoiceChip(
                  label: const Text('Light'),
                  selected: currentMode == ThemeMode.light,
                  selectedColor: const Color(0xFFD3643B).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: Colors.black87,
                    fontWeight: currentMode == ThemeMode.light ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (v) => ref.read(settingsProvider.notifier).updateThemeMode(ThemeMode.light),
                ),
                ChoiceChip(
                  label: const Text('Dark'),
                  selected: currentMode == ThemeMode.dark,
                  selectedColor: const Color(0xFFD3643B).withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: Colors.black87,
                    fontWeight: currentMode == ThemeMode.dark ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (v) => ref.read(settingsProvider.notifier).updateThemeMode(ThemeMode.dark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Color Way', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ColorPickerCircle(color: AppColors.primary, label: 'Default'),
                _ColorPickerCircle(color: Colors.red, label: 'Red'),
                _ColorPickerCircle(color: Colors.pink, label: 'Pink'),
                _ColorPickerCircle(color: Colors.purple, label: 'Purple'),
                _ColorPickerCircle(color: Colors.deepPurple, label: 'Deep Purple'),
                _ColorPickerCircle(color: Colors.indigo, label: 'Indigo'),
                _ColorPickerCircle(color: Colors.blue, label: 'Blue'),
                _ColorPickerCircle(color: Colors.lightBlue, label: 'Light Blue'),
                _ColorPickerCircle(color: Colors.cyan, label: 'Cyan'),
                _ColorPickerCircle(color: Colors.teal, label: 'Teal'),
                _ColorPickerCircle(color: Colors.green, label: 'Green'),
                _ColorPickerCircle(color: Colors.lightGreen, label: 'Light Green'),
                _ColorPickerCircle(color: Colors.amber, label: 'Amber'),
                _ColorPickerCircle(color: Colors.orange, label: 'Orange'),
                _ColorPickerCircle(color: Colors.deepOrange, label: 'Deep Orange'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Background Photo', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PhotoPickerCircle(url: null, label: 'None'),
                _DevicePhotoPickerCircle(),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1506744626753-1fa44df31c2f?auto=format&fit=crop&w=3840&q=100',
                    label: 'Nature'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=3840&q=100',
                    label: 'Space'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=3840&q=100',
                    label: 'Office'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=3840&q=100',
                    label: 'Abstract'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1511818966892-d7d671e672a2?auto=format&fit=crop&w=3840&q=100',
                    label: 'Architecture'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=3840&q=100',
                    label: 'Ocean'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=3840&q=100',
                    label: 'Mountains'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=3840&q=100',
                    label: 'Forest'),
                _PhotoPickerCircle(
                    url: 'https://images.unsplash.com/photo-1449844908441-8829872d2607?auto=format&fit=crop&w=3840&q=100',
                    label: 'Cityscape'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    final currentSort = ref.read(taskSortProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskSortOption.values.map((opt) {
            final isSelected = opt == currentSort;
            final label = switch (opt) {
              TaskSortOption.importance => 'Importance',
              TaskSortOption.dueDate => 'Due Date',
              TaskSortOption.alphabetically => 'Alphabetically',
              TaskSortOption.creationDate => 'Creation Date',
            };
            return ListTile(
              title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                ref.read(taskSortProvider.notifier).state = opt;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sorted by $label'), behavior: SnackBarBehavior.floating));
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showReorderSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Drag and drop to reorder tasks is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyTasksToClipboard() async {
    final tasksData = ref.read(tasksForDateProvider);
    tasksData.whenData((tasks) {
      if (tasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tasks to copy.'), behavior: SnackBarBehavior.floating));
        return;
      }
      final dateStr = DateFormat('EEEE, d MMMM').format(_now);
      final buffer = StringBuffer('Tasks for $dateStr:\n');
      for (final t in tasks) {
        buffer.writeln('- [${t.status == TaskStatus.completed ? 'x' : ' '}] ${t.title} (${DateFormat('h:mm a').format(t.startTime)})');
      }
      Clipboard.setData(ClipboardData(text: buffer.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasks copied to clipboard!'), behavior: SnackBarBehavior.floating),
      );
    });
  }

  void _showPrintSnackbar() {
    final tasksData = ref.read(tasksForDateProvider);
    tasksData.whenData((tasks) {
      if (tasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tasks to print.'), behavior: SnackBarBehavior.floating));
        return;
      }
      PdfGenerator.printTaskList(tasks, _now);
    });
  }
}

class _ColorPickerCircle extends ConsumerWidget {
  final Color color;
  final String label;

  const _ColorPickerCircle({required this.color, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(primaryColorProvider) == color;
    return GestureDetector(
      onTap: () => ref.read(primaryColorProvider.notifier).state = color,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2) : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      )
    );
  }
}

class _PhotoPickerCircle extends ConsumerWidget {
  final String? url;
  final String label;

  const _PhotoPickerCircle({required this.url, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(backgroundPhotoProvider) == url;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => ref.read(backgroundPhotoProvider.notifier).state = url,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: url == null ? (isDark ? Colors.black26 : Colors.black12) : null,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : 
                                   Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              image: url != null ? DecorationImage(
                image: url!.startsWith('http') ? NetworkImage(url!) as ImageProvider : FileImage(File(url!)),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: url == null ? Icon(Icons.do_not_disturb_alt_rounded, color: isDark ? Colors.white54 : Colors.black54) 
                               : (isSelected ? const Icon(Icons.check, color: Colors.white, size: 24) : null),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      )
    );
  }
}

class _DevicePhotoPickerCircle extends ConsumerWidget {
  const _DevicePhotoPickerCircle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgUrl = ref.watch(backgroundPhotoProvider);
    final isDevicePhotoActive = bgUrl != null && !bgUrl.startsWith('http');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          ref.read(backgroundPhotoProvider.notifier).state = pickedFile.path;
        }
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.black12,
              shape: BoxShape.circle,
              border: isDevicePhotoActive 
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) 
                  : Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
            ),
            child: Icon(Icons.add_photo_alternate_rounded, color: isDark ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 4),
          const Text('Device', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, d MMMM').format(DateTime.now()),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.textSecondaryDark 
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          userName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.textPrimaryDark 
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}


class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.edit_note_rounded,
            title: 'Notes',
            subtitle: 'Drafts',
            cardColor: isDark ? const Color(0xFF2C3E2C) : const Color(0xFFC7DAC1),
            iconContainerColor: isDark ? const Color(0xFF4C8F4C) : const Color(0xFFA5CFA5),
            iconColor: Colors.black87,
            onTap: () => context.push('/home/notes'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.timeline_rounded,
            title: 'Insights',
            subtitle: 'Analytics',
            cardColor: isDark ? const Color(0xFF3E3C32) : const Color(0xFFD4DEC6),
            iconContainerColor: isDark ? const Color(0xFF8F6E4C) : const Color(0xFFF7AB8A),
            iconColor: Colors.black87,
            onTap: () => context.push('/home/insights'),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardColor,
    required this.iconContainerColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardColor;
  final Color iconContainerColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140, // Match visual height proportions
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconContainerColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
               ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: context.go('/home');
          case 1: context.push('/home/calendar');
          case 2: context.push('/home/checklist');
          case 3: context.push('/home/settings');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.schedule_rounded), label: 'Daily'),
        NavigationDestination(icon: Icon(Icons.calendar_today_rounded), label: 'History'),
        NavigationDestination(icon: Icon(Icons.task_alt_rounded), label: 'TASK'),
        NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}

class _DateSelector extends ConsumerWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch for dynamically generated dates that have tasks assigned
    final dates = ref.watch(activeDatesProvider);

    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
                             date.month == selectedDate.month &&
                             date.day == selectedDate.day;

          return GestureDetector(
            onTap: () => ref.read(selectedDateProvider.notifier).state = date,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64, // Slightly wider for squarish look
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkElevated : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
          );
        },
      ),
    );
  }
}

class _DailyProgressCard extends ConsumerWidget {
  const _DailyProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksData = ref.watch(tasksForDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Progress',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          tasksData.when(
            data: (tasks) {
              final total = tasks.length;
              final completed = tasks.where((t) => t.status == TaskStatus.completed).length;
              final progress = total == 0 ? 0.0 : completed / total;

              return Row(
                children: [
                   SizedBox(
                     height: 72,
                     width: 72,
                     child: CircularProgressIndicator(
                       value: progress,
                       strokeWidth: 10,
                       backgroundColor: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                       valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                     ),
                   ),
                   const SizedBox(width: 24),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         '$completed/$total',
                         style: TextStyle(
                           fontSize: 28,
                           fontWeight: FontWeight.w700,
                           color: isDark ? Colors.white : Colors.black87,
                         ),
                       ),
                       Text(
                         'Tasks Done',
                         style: TextStyle(
                           fontSize: 13,
                           fontWeight: FontWeight.w500,
                           color: isDark ? Colors.white60 : Colors.black54,
                         ),
                       ),
                     ],
                   ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Error loading progress'),
          ),
        ],
      ),
    );
  }
}
