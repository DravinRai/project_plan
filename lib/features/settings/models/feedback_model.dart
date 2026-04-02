import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_plan/core/utils/firestore_utils.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String subject;
  final String message;
  final DateTime createdAt;

  FeedbackModel({
    this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subject': subject,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
