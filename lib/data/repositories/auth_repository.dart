import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_client.dart';
import '../models/user_model.dart';

/// Handles all authentication and user profile operations.
class AuthRepository {
  final SupabaseClient _client = AppSupabase.client;

  /// Current logged-in user (null if not authenticated)
  User? get currentAuthUser => _client.auth.currentUser;
  String? get currentUserId => currentAuthUser?.id;
  bool get isLoggedIn => currentAuthUser != null;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email + password.
  /// The DB trigger `handle_new_user` auto-creates the profile row.
  /// We wait briefly then fetch the profile to confirm it worked.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign up failed — no user returned');
    }

    // If email confirmation is enabled, session will be null.
    // The user exists in auth.users and the trigger created the profile,
    // but they need to confirm email before they can sign in.
    if (response.session == null) {
      // Return a temporary model — user must confirm email first
      return UserModel(
        id: user.id,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );
    }

    // Session exists (email confirmation disabled) — fetch the profile
    // Give the trigger a moment to fire
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      return await getProfile(user.id);
    } catch (_) {
      // If the trigger hasn't fired yet or profile doesn't exist,
      // create it manually as a fallback
      final profile = UserModel(
        id: user.id,
        email: email,
        name: name,
        createdAt: DateTime.now(),
      );
      await _client.from(AppSupabase.usersTable).upsert(profile.toJson());
      return profile;
    }
  }

  /// Sign in with email + password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign in failed');
    }

    return getProfile(response.user!.id);
  }

  /// Fetch user profile from the profiles table
  Future<UserModel> getProfile(String userId) async {
    final data = await _client
        .from(AppSupabase.usersTable)
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(data);
  }

  /// Update profile name
  Future<void> updateName(String userId, String name) async {
    await _client
        .from(AppSupabase.usersTable)
        .update({'name': name})
        .eq('id', userId);
  }

  /// Set role (stitch / angel / solo)
  Future<UserModel> updateRole(String userId, String role) async {
    await _client
        .from(AppSupabase.usersTable)
        .update({'role': role})
        .eq('id', userId);
    return getProfile(userId);
  }

  Future<UserModel> updatePreferredCurrency(
    String userId,
    String currencyCode,
  ) async {
    await _client
        .from(AppSupabase.usersTable)
        .update({'preferred_currency': currencyCode})
        .eq('id', userId);
    return getProfile(userId);
  }

  /// Update avatar URL
  Future<UserModel> updateAvatar(String userId, String avatarUrl) async {
    await _client
        .from(AppSupabase.usersTable)
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
    return getProfile(userId);
  }

  Future<UserModel> clearAvatar(String userId) async {
    await _client
        .from(AppSupabase.usersTable)
        .update({'avatar_url': null})
        .eq('id', userId);
    return getProfile(userId);
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
