import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:project_plan/features/notes/models/note_model.dart';

const _notesBoxName = 'notes';

final notesBoxProvider = Provider.autoDispose<Box<NoteModel>>((ref) {
  return Hive.box<NoteModel>(_notesBoxName);
});

final notesProvider = StateNotifierProvider.autoDispose<NotesNotifier, List<NoteModel>>((ref) {
  final box = ref.watch(notesBoxProvider);
  return NotesNotifier(box);
});

class NotesNotifier extends StateNotifier<List<NoteModel>> {
  final Box<NoteModel> _box;
  static const _uuid = Uuid();

  NotesNotifier(this._box) : super([]) {
    _load();
  }

  void _load() {
    state = _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  NoteModel addNote({String title = 'Untitled'}) {
    final note = NoteModel(
      id: _uuid.v4(),
      title: title,
      content: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _box.put(note.id, note);
    _load();
    return note;
  }

  void updateNote(String id, {String? title, String? content}) {
    final note = _box.get(id);
    if (note == null) return;
    if (title != null) note.title = title;
    if (content != null) note.content = content;
    note.updatedAt = DateTime.now();
    note.save();
    _load();
  }

  void deleteNote(String id) {
    _box.delete(id);
    _load();
  }
}
