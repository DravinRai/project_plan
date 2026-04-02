import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import 'package:project_plan/features/tasks/models/task_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/task_provider.dart';

/// Create or Edit a task.
/// If [existingTask] is null, creates a new task.
/// Pass via GoRouter extra: `context.push('/home/task-editor', extra: task)`
class TaskEditorScreen extends ConsumerStatefulWidget {
  const TaskEditorScreen({super.key, this.existingTask});
  final TaskModel? existingTask;

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid    = const Uuid();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;

  late DateTime  _date;
  late TimeOfDay _startTime;
  late int       _durationMinutes;
  TaskCategory?  _category;
  DateTime?      _dueDate;
  String?        _reminder;
  String?        _recurrence;
  List<String>   _attachments = [];
  bool           _isImportant = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleCtrl      = TextEditingController(text: task?.title ?? '');
    _notesCtrl      = TextEditingController(text: task?.notes ?? '');
    _date           = task != null
        ? task.startTime
        : ref.read(selectedDateProvider);
    _startTime      = task != null
        ? TimeOfDay.fromDateTime(task.startTime)
        : TimeOfDay.now();
    _durationMinutes = task?.durationMinutes ?? 30;
    _category       = task?.category;
    _dueDate        = task?.dueDate;
    _reminder       = task?.reminder;
    _recurrence     = task?.recurrence;
    _attachments    = task?.attachments != null ? List.from(task!.attachments!) : [];
    _isImportant    = task?.isImportant ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Save ─────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) {
      debugPrint('[UI] ERROR: UID is null! Cannot save.');
      return;
    }
    debugPrint('[UI] Saving task for UID: $uid');

    final startDateTime = DateTime(
      _date.year, _date.month, _date.day,
      _startTime.hour, _startTime.minute,
    );
    final now = DateTime.now();

    // Prevent past-time scheduling for NEW tasks
    if (!_isEditing && startDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot schedule activities in the past!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_date);

    final task = TaskModel(
      taskId:          _isEditing ? widget.existingTask!.taskId : _uuid.v4(),
      userId:          uid,
      title:           _titleCtrl.text.trim(),
      date:            dateStr,
      startTime:       startDateTime,
      durationMinutes: _durationMinutes,
      status:          widget.existingTask?.status ?? TaskStatus.assigned,
      completedAt:     widget.existingTask?.completedAt,
      notes:           _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      category:        _category,
      dueDate:         _dueDate,
      reminder:        _reminder,
      recurrence:      _recurrence,
      attachments:     _attachments.isEmpty ? null : _attachments,
      createdAt:       widget.existingTask?.createdAt ?? now,
      updatedAt:       now,
      isClockAssigned: widget.existingTask?.isClockAssigned ?? false,
      isImportant:     _isImportant,
    );

    final notifier = ref.read(taskNotifierProvider.notifier);
    if (_isEditing) {
      await notifier.updateTask(task);
    } else {
      await notifier.createTask(task);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity saved successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/home/checklist');
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
  appBar: AppBar(
    title: Text(_isEditing ? 'Edit Activity' : 'Plan Activity', style: const TextStyle(fontSize: 16, letterSpacing: 0.5)),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => context.pop(),
    ),
  ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // ── Activity Name ───────────────────────────────
            Text(
              'ACTIVITY DETAILS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white38 : Colors.black38,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'What are you planning?',
                filled: true,
                fillColor: isDark ? AppColors.cardDarkElevated : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
                ),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.grey),
              ),
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 24),

            // ── Timing ─────────────────────────────────────────
            _SectionHeader(label: 'SCHEDULE', isDark: isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat('MMM d').format(_date),
                    onTap: _pickDate,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: 'Start',
                    value: _startTime.format(context),
                    onTap: _pickTime,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Duration Slider ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDarkElevated : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('DURATION',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Colors.grey)),
                      Text(
                        _durationMinutes >= 60
                            ? '${_durationMinutes ~/ 60}h ${_durationMinutes % 60 == 0 ? '' : '${_durationMinutes % 60}m'}'
                            : '${_durationMinutes}m',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    ),
                    child: Slider(
                      value: _durationMinutes.toDouble(),
                      min: 15,
                      max: 480,
                      divisions: 31,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _durationMinutes = v.round()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Advanced Options ──────────────────────────────
            _SectionHeader(label: 'OPTIONS', isDark: isDark),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.flag_rounded,
                    label: 'Due Date',
                    value: _dueDate != null ? DateFormat('MMM d').format(_dueDate!) : 'None',
                    onTap: _pickDueDate,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.notifications_active_rounded,
                    label: 'Remind Me',
                    value: _reminder ?? 'None',
                    onTap: _pickReminder,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.repeat_rounded,
                    label: 'Repeat',
                    value: _recurrence ?? 'Never',
                    onTap: _pickRecurrence,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isImportant = !_isImportant),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isImportant ? (isDark ? Colors.amber.withValues(alpha: 0.2) : Colors.amber.shade50) : (isDark ? AppColors.cardDarkElevated : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isImportant ? Colors.amber : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                          width: _isImportant ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isImportant ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 20,
                            color: _isImportant ? Colors.amber : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Important',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: _isImportant ? Colors.amber.shade700 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // ── Notes Input (Expandable) ─────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDarkElevated : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: null,
                style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white70 : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Add Note',
                  hintStyle: TextStyle(
                      color: isDark ? Colors.white24 : Colors.black26),
                  border: InputBorder.none,
                  icon: const Icon(Icons.notes_rounded, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Attachments ──────────────────────────────────────
            if (_attachments.isNotEmpty) ...[
              for (final att in _attachments)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_rounded, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          att,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _attachments.remove(att)),
                        child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // ── Add File Mock ──────────────────────────────────
            GestureDetector(
              onTap: _mockAddFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDarkElevated : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.attach_file_rounded, color: Colors.grey),
                    SizedBox(width: 16),
                    Text(
                      'Add File',
                      style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Category Selector ─────────────────────────────
            _SectionHeader(label: 'CATEGORY', isDark: isDark),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: TaskCategory.values.map((cat) {
                final selected = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = selected ? null : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : (isDark ? Colors.transparent : Colors.white),
                      borderRadius: BorderRadius.circular(24), // Pillow shaped
                      border: Border.all(
                        color: selected ? AppColors.primary : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                      ),
                    ),
                    child: Text(
                      cat.label,
                      style: TextStyle(
                        color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            const SizedBox(height: 48),

            // ── Save Button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'SAVE ACTIVITY',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Delete ───────────────────────────────────────
            if (_isEditing)
              Center(
                child: TextButton.icon(
                  onPressed: _deleteTask,
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  label: const Text(
                    'DELETE THIS ACTIVITY',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Pickers ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _date,
      firstDate:    DateTime.now().subtract(const Duration(days: 365)),
      lastDate:     DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context:     context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _dueDate ?? _date,
      firstDate:    DateTime.now().subtract(const Duration(days: 365)),
      lastDate:     DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickReminder() async {
    final options = ['None', '5 mins before', '15 mins before', '30 mins before', '1 hour before'];
    final selected = await _showOptionsDialog('Remind Me', options);
    if (selected != null) {
      setState(() => _reminder = selected == 'None' ? null : selected);
    }
  }

  Future<void> _pickRecurrence() async {
    final options = ['Never', 'Daily', 'Weekly', 'Monthly'];
    final selected = await _showOptionsDialog('Repeat', options);
    if (selected != null) {
      setState(() => _recurrence = selected == 'Never' ? null : selected);
    }
  }

  Future<String?> _showOptionsDialog(String title, List<String> options) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: options.map((opt) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, opt),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(opt, style: const TextStyle(fontSize: 16)),
          ),
        )).toList(),
      ),
    );
  }

  Future<void> _mockAddFile() async {
    setState(() {
      _attachments.add('attached_document_${_attachments.length + 1}.pdf');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated adding a file!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   const Text('Delete Activity'),
        content: const Text('Are you sure you want to remove this plan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(taskNotifierProvider.notifier)
          .deleteTask(widget.existingTask!.taskId);
      if (mounted) context.pop();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white54 : Colors.black54,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDarkElevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
