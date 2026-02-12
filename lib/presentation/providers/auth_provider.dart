import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

/// Provides auth repository as a singleton
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth state: null = not logged in, UserModel = logged in
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      return AuthNotifier(ref.read(authRepositoryProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.data(null)) {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final authUser = _repo.currentAuthUser;
    if (authUser != null) {
      state = const AsyncValue.loading();
      try {
        final profile = await _repo.getProfile(authUser.id);
        state = AsyncValue.data(profile);
      } catch (e, st) {
        // Profile might not exist yet — sign them out cleanly
        state = AsyncValue.error(_friendlyError(e), st);
      }
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUp(
        email: email,
        password: password,
        name: name,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
    }
  }

  /// Set user's character role (stitch or angel)
  Future<void> setRole(String role) async {
    final user = state.valueOrNull;
    if (user == null) return;
    try {
      final updated = await _repo.updateRole(user.id, role);
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
    }
  }

  Future<void> setPreferredCurrency(String currencyCode) async {
    final user = state.valueOrNull;
    if (user == null) return;
    try {
      final updated = await _repo.updatePreferredCurrency(
        user.id,
        currencyCode,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(_friendlyError(e), st);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }

  /// Convert Supabase exceptions into user-friendly messages
  String _friendlyError(Object error) {
    final msg = error.toString().toLowerCase();

    if (error is AuthException) {
      if (error.message.contains('already registered')) {
        return 'This email is already registered. Try signing in.';
      }
      if (error.message.contains('Invalid login')) {
        return 'Incorrect email or password.';
      }
      if (error.message.contains('Email not confirmed')) {
        return 'Please check your email and confirm your account first.';
      }
      return error.message;
    }

    if (msg.contains('relation') && msg.contains('does not exist')) {
      return 'Database not set up yet. Run the SQL migration in Supabase.';
    }
    if (msg.contains('failed host lookup') || msg.contains('socketexception')) {
      return 'No internet connection. Check your network.';
    }
    if (msg.contains('row-level security') || msg.contains('rls')) {
      return 'Permission denied. Check Supabase RLS policies.';
    }

    return error.toString();
  }
}

/// Convenience: current user ID (non-null when logged in)
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.id;
});

final currentCurrencyProvider = Provider<String>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.preferredCurrency ?? 'JPY';
});
