import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_plan/features/checklist/models/checklist_item.dart';
import 'package:project_plan/features/checklist/repositories/checklist_repository.dart';
import '../../auth/providers/auth_provider.dart';

// ── Repository Provider ───────────────────────────────────────

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository();
});

// ── Checklist Stream ──────────────────────────────────────────

final checklistProvider =
    StreamProvider.autoDispose<List<ChecklistItem>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(checklistRepositoryProvider).watchItems(uid);
});

// ── Checklist Notifier ────────────────────────────────────────

class ChecklistNotifier extends AsyncNotifier<void> {
  ChecklistRepository get _repo => ref.read(checklistRepositoryProvider);
  String get _uid => ref.read(authStateProvider).valueOrNull!.uid;

  @override
  Future<void> build() async {}

  Future<void> addItem(String title, {String? date}) async {
    final item = ChecklistItem(
      listId:    '',          // assigned by Firestore
      title:     title,
      date:      date,
      createdAt: DateTime.now(),
    );
    state = await AsyncValue.guard(() => _repo.createItem(_uid, item));
  }

  Future<void> toggleItem(ChecklistItem item) async {
    state = await AsyncValue.guard(() => _repo.toggleItem(_uid, item));
  }

  Future<void> deleteItem(String listId) async {
    state = await AsyncValue.guard(() => _repo.deleteItem(_uid, listId));
  }

  Future<void> renameItem(String listId, String newTitle) async {
    state = await AsyncValue.guard(
        () => _repo.updateTitle(_uid, listId, newTitle));
  }
}

final checklistNotifierProvider =
    AsyncNotifierProvider<ChecklistNotifier, void>(ChecklistNotifier.new);
