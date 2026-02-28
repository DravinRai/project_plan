import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/pdf_generator.dart';
import '../providers/checklist_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../../data/models/checklist_item.dart';
import '../../../data/models/task_model.dart';
import '../../../core/theme/widgets/theme_toggle_switch.dart';
import '../../../core/widgets/completion_overlay.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistAsync = ref.watch(checklistProvider);
    final activitiesAsync = ref.watch(sortedTasksForDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgUrl = ref.watch(backgroundPhotoProvider);

    Widget scaffold = Scaffold(
      backgroundColor: bgUrl != null ? Colors.transparent : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
      appBar: AppBar(
        backgroundColor: bgUrl != null ? Colors.transparent : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        title: const Text('TASK', style: TextStyle(letterSpacing: 2.0, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDialog(context, ref), // In future, route to new task
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: isDark ? AppColors.cardDarkElevated : Colors.white,
              onSelected: (value) => _handleMenuSelection(context, ref, value),
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
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tasks) => checklistAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            final activeTasks = tasks.where((t) => t.status != TaskStatus.completed).toList();
            final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();
            final activeItems = items.where((i) => !i.isCompleted).toList();
            final completedItems = items.where((i) => i.isCompleted).toList();

            return CustomScrollView(
              slivers: [
                // ── Activities ──────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    label: DateFormat('MMM d').format(ref.watch(selectedDateProvider)) == 
                           DateFormat('MMM d').format(DateTime.now())
                        ? 'TODAY\'S ACTIVITIES'
                        : '${DateFormat('MMM d').format(ref.watch(selectedDateProvider)).toUpperCase()} ACTIVITIES',
                    isDark: isDark,
                  ),
                ),
                activeTasks.isEmpty
                    ? const SliverToBoxAdapter(child: _EmptySection(label: 'No active activities'))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _ActivityTile(task: activeTasks[index]),
                            childCount: activeTasks.length,
                          ),
                        ),
                      ),

                // ── Persistent Items (Goals) ────────────────────────────
                SliverToBoxAdapter(
                  child: _SectionHeader(label: 'GOALS', isDark: isDark),
                ),
                activeItems.isEmpty
                    ? const SliverToBoxAdapter(child: _EmptySection(label: 'No active goals'))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _ChecklistTile(item: activeItems[index]),
                            childCount: activeItems.length,
                          ),
                        ),
                      ),

                // ── Completed Section ────────────────────────────
                if (completedTasks.isNotEmpty || completedItems.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(label: 'COMPLETED', isDark: isDark),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ...completedTasks.map((t) => _ActivityTile(task: t)),
                        ...completedItems.map((i) => _ChecklistTile(item: i)),
                      ]),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Goal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Drink Water'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(checklistNotifierProvider.notifier).addItem(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Menu Handlers ──────────────────────────────────────────────────

  void _handleMenuSelection(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'theme': _showThemeDialog(context, ref); break;
      case 'sort': _showSortDialog(context, ref); break;
      case 'reorder': _showReorderSnackbar(context); break;
      case 'copy': _copyTasksToClipboard(context, ref); break;
      case 'print': _printTaskList(context, ref); break;
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);
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
            const ThemeToggleSwitch(),
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

  void _showSortDialog(BuildContext context, WidgetRef ref) {
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

  void _showReorderSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Drag and drop to reorder tasks is coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyTasksToClipboard(BuildContext context, WidgetRef ref) async {
    final tasksData = ref.read(sortedTasksForDateProvider);
    tasksData.whenData((tasks) {
      if (tasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tasks to copy.'), behavior: SnackBarBehavior.floating));
        return;
      }
      final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());
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

  void _printTaskList(BuildContext context, WidgetRef ref) {
    final tasksData = ref.read(sortedTasksForDateProvider);
    tasksData.whenData((tasks) {
      if (tasks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No tasks to print.'), behavior: SnackBarBehavior.floating));
        return;
      }
      PdfGenerator.printTaskList(tasks, DateTime.now());
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white54 : Colors.black54,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.checklist_rounded, size: 48, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54, 
                fontSize: 14, 
                fontWeight: FontWeight.w600
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  const _ActivityTile({required this.task});
  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = task.status == TaskStatus.completed;

    return GestureDetector(
      onTap: () {
        // Open the TaskEditorScreen in edit mode, passing the task
        // We use go_router's push to navigate to the editor
        // Note: the route '/home/task-editor' is defined in router.dart
        // and expects an extra object of type TaskModel.
        context.push('/home/task-editor', extra: task);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDarkElevated : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: IconButton(
            icon: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isCompleted ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
              size: 26,
            ),
            onPressed: () {
              if (isCompleted) {
                ref.read(taskNotifierProvider.notifier).undoCompletion(task);
              } else {
                ref.read(taskNotifierProvider.notifier).completeTask(task);
                showCompletionOverlay(context);
              }
            },
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : (isDark ? Colors.white : Colors.black),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (task.isImportant) ...[
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${DateFormat('h:mm a').format(task.startTime)} (${task.durationMinutes}m)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isCompleted ? Colors.grey : (isDark ? Colors.white54 : Colors.black54),
                    ),
                  ),
                  if (task.recurrence != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.repeat_rounded, size: 10, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            task.recurrence!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    task.isImportant ? Icons.star_rounded : Icons.star_border_rounded,
                    color: task.isImportant ? Colors.amber : (isDark ? Colors.white54 : Colors.black54),
                    size: 22,
                  ),
                  onPressed: () {
                    // Toggle Important flag
                    ref.read(taskNotifierProvider.notifier).updateTask(task.copyWith(isImportant: !task.isImportant));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 22),
                  onPressed: () => _confirmDeleteActivity(context, ref, task),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteActivity(BuildContext context, WidgetRef ref, TaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Remove this plan from your schedule?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(taskNotifierProvider.notifier).deleteTask(task.taskId);
    }
  }
}

class _ChecklistTile extends ConsumerWidget {
  const _ChecklistTile({required this.item});
  final ChecklistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDarkElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: IconButton(
          icon: Icon(
            item.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: item.isCompleted ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
            size: 26,
          ),
          onPressed: () => ref.read(checklistNotifierProvider.notifier).toggleItem(item),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : (isDark ? Colors.white : Colors.black),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: isDark ? Colors.white54 : Colors.black54, size: 22),
          onPressed: () => ref.read(checklistNotifierProvider.notifier).deleteItem(item.listId),
        ),
      ),
    );
  }
}
