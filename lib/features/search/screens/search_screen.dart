import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/note_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../notes/providers/notes_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _queryCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardBg = isDark ? AppColors.cardDarkElevated : Colors.white;
    final divBorder = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    final allTasksAsync = ref.watch(allTasksProvider);
    final notes = ref.watch(notesProvider);

    final List<TaskModel> filteredTasks = _query.isEmpty
        ? []
        : allTasksAsync.whenOrNull(
              data: (tasks) => tasks
                  .where((t) =>
                      t.title.toLowerCase().contains(_query.toLowerCase()) ||
                      (t.notes ?? '').toLowerCase().contains(_query.toLowerCase()) ||
                      (t.category?.label ?? '').toLowerCase().contains(_query.toLowerCase()))
                  .toList(),
            ) ??
            [];

    final List<NoteModel> filteredNotes = _query.isEmpty
        ? []
        : notes
            .where((n) =>
                n.title.toLowerCase().contains(_query.toLowerCase()) ||
                n.content.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final hasResults = filteredTasks.isNotEmpty || filteredNotes.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          style: TextStyle(color: textColor, fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'Search tasks, notes...',
            hintStyle: TextStyle(color: subColor),
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: subColor),
              onPressed: () {
                _queryCtrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? _EmptySearch(subColor: subColor)
          : !hasResults
              ? _NoResults(query: _query, subColor: subColor)
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (filteredTasks.isNotEmpty) ...[
                      _SectionLabel(label: 'TASKS', subColor: subColor),
                      const SizedBox(height: 8),
                      ...filteredTasks.map((task) => _TaskResult(
                            task: task,
                            isDark: isDark,
                            cardBg: cardBg,
                            divBorder: divBorder,
                            textColor: textColor,
                            subColor: subColor,
                            query: _query,
                            onTap: () => context.push('/home/task-editor', extra: task),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (filteredNotes.isNotEmpty) ...[
                      _SectionLabel(label: 'NOTES', subColor: subColor),
                      const SizedBox(height: 8),
                      ...filteredNotes.map((note) => _NoteResult(
                            note: note,
                            isDark: isDark,
                            cardBg: cardBg,
                            divBorder: divBorder,
                            textColor: textColor,
                            subColor: subColor,
                            query: _query,
                            onTap: () => context.push('/home/notes'),
                          )),
                    ],
                  ],
                ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color subColor;
  const _SectionLabel({required this.label, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: subColor,
            letterSpacing: 1.2));
  }
}

class _TaskResult extends StatelessWidget {
  final TaskModel task;
  final bool isDark;
  final Color cardBg, divBorder, textColor, subColor;
  final String query;
  final VoidCallback onTap;

  const _TaskResult({
    required this.task,
    required this.isDark,
    required this.cardBg,
    required this.divBorder,
    required this.textColor,
    required this.subColor,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (task.status) {
      TaskStatus.completed => AppColors.completed,
      TaskStatus.missed => AppColors.missed,
      TaskStatus.remaining => AppColors.remaining,
      TaskStatus.assigned => AppColors.assigned,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _HighlightedText(text: task.title, query: query, textColor: textColor)),
                      if (task.recurrence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Text(
                            task.recurrence!.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d').format(task.startTime)} • ${DateFormat('h:mm a').format(task.startTime)} • ${task.status.label}',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NoteResult extends StatelessWidget {
  final NoteModel note;
  final bool isDark;
  final Color cardBg, divBorder, textColor, subColor;
  final String query;
  final VoidCallback onTap;

  const _NoteResult({
    required this.note,
    required this.isDark,
    required this.cardBg,
    required this.divBorder,
    required this.textColor,
    required this.subColor,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = note.content.isEmpty ? 'Empty note' : note.content;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(text: note.title, query: query, textColor: textColor),
                  const SizedBox(height: 4),
                  Text(
                    preview.length > 60 ? '${preview.substring(0, 60)}…' : preview,
                    style: TextStyle(fontSize: 12, color: subColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: subColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text, query;
  final Color textColor;
  const _HighlightedText({required this.text, required this.query, required this.textColor});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: textColor));
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final idx = lower.indexOf(qLower);
    if (idx < 0) return Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: textColor));

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, idx), style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withOpacity(0.12),
            ),
          ),
          TextSpan(text: text.substring(idx + query.length), style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  final Color subColor;
  const _EmptySearch({required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 64, color: subColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Search tasks and notes', style: TextStyle(color: subColor, fontSize: 15)),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  final Color subColor;
  const _NoResults({required this.query, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: subColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No results for "$query"', style: TextStyle(color: subColor, fontSize: 15)),
        ],
      ),
    );
  }
}
