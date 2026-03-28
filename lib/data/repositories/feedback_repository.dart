import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/feedback_model.dart';

class FeedbackRepository {
  final FirebaseFirestore _firestore;

  FeedbackRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> submitFeedback(FeedbackModel feedback) async {
    try {
      await _firestore.collection('feedback').add(feedback.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
}
