import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore document model for /users/{uid}/checklists/{listId}
class ChecklistItem {
  final String listId;
  final String title;
  final bool isCompleted;
  final String? date;    // YYYY-MM-DD if date-specific, null if persistent
  final DateTime createdAt;

  const ChecklistItem({
    required this.listId,
    required this.title,
    this.isCompleted = false,
    this.date,
    required this.createdAt,
  });

  factory ChecklistItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ChecklistItem(
      listId:      doc.id,
      title:       data['title']       as String?  ?? '',
      isCompleted: data['isCompleted'] as bool?    ?? false,
      date:        data['date']        as String?,
      createdAt:   (data['createdAt']  as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title':       title,
    'isCompleted': isCompleted,
    'date':        date,
    'createdAt':   Timestamp.fromDate(createdAt),
  };

  ChecklistItem copyWith({String? title, bool? isCompleted, String? date}) {
    return ChecklistItem(
      listId:      listId,
      title:       title       ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      date:        date        ?? this.date,
      createdAt:   createdAt,
    );
  }
}
