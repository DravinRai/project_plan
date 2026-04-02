import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_plan/features/checklist/models/checklist_item.dart';

/// Repository for checklist CRUD (Things to Remember).
class ChecklistRepository {
  ChecklistRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('checklists');

  // ── Create ────────────────────────────────────────────────

  Future<String> createItem(String uid, ChecklistItem item) async {
    final ref  = _col(uid).doc();
    await ref.set(item.toFirestore());
    return ref.id;
  }

  // ── Watch ─────────────────────────────────────────────────

  /// Streams all checklist items ordered by creation time.
  /// Persistent items (date == null) + today's items are mixed together.
  Stream<List<ChecklistItem>> watchItems(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChecklistItem.fromFirestore(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  // ── Toggle ────────────────────────────────────────────────

  Future<void> toggleItem(String uid, ChecklistItem item) async {
    await _col(uid)
        .doc(item.listId)
        .update({'isCompleted': !item.isCompleted});
  }

  // ── Delete ────────────────────────────────────────────────

  Future<void> deleteItem(String uid, String listId) async {
    await _col(uid).doc(listId).delete();
  }

  // ── Update title ─────────────────────────────────────────

  Future<void> updateTitle(String uid, String listId, String newTitle) async {
    await _col(uid).doc(listId).update({'title': newTitle});
  }
}
