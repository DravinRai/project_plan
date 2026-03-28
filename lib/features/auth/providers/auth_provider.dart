import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// NOTE: Auth providers must NOT use .autoDispose — they are app-lifetime streams.
// Disposing them mid-navigation causes Firestore to run without auth → permission-denied.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUserModel();
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> initializeProfile() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).upsertUserDocument(user);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);



