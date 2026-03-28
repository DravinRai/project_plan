import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/feedback_repository.dart';
import '../../../data/models/feedback_model.dart';
import '../../auth/providers/auth_provider.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

class FeedbackNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submitFeedback({
    required String subject,
    required String message,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('User must be logged in to send feedback');

    state = const AsyncLoading();
    try {
      final feedback = FeedbackModel(
        userId: user.uid,
        subject: subject,
        message: message,
        createdAt: DateTime.now(),
      );

      await ref.read(feedbackRepositoryProvider).submitFeedback(feedback);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final feedbackNotifierProvider =
    AsyncNotifierProvider<FeedbackNotifier, void>(FeedbackNotifier.new);
