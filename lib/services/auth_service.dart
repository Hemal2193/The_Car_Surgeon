import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// ---------------- LOGIN ----------------
  static Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Unable to login.');
      }

      return response.user;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  /// ---------------- REGISTER ----------------
  static Future<User?> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Unable to register.');
      }

      return response.user;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Register Error: $e');
      rethrow;
    }
  }

  /// ---------------- RESET PASSWORD ----------------
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }

  /// ---------------- LOGOUT ----------------
  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// ---------------- CURRENT USER ----------------
  static User? get currentUser => _supabase.auth.currentUser;

  /// ---------------- IS LOGGED IN ----------------
  static bool get isLoggedIn => currentUser != null;

  /// ---------------- AUTH STREAM ----------------
  static Stream<AuthState> get authState => _supabase.auth.onAuthStateChange;

  /// ---------------- ENSURE USER ROW ----------------
  static Future<void> ensureUserRow(User user) async {
    try {
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email,
          'is_approved': false,
        });
      }
    } catch (e) {
      debugPrint('Ensure user row error: $e');
    }
  }

  /// ---------------- GET USER APPROVAL STATUS ----------------
  static Future<bool> getUserApprovalStatus(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_approved')
          .eq('id', userId)
          .maybeSingle();

      return response != null && response['is_approved'] == true;
    } catch (e) {
      debugPrint('Get approval status error: $e');
      return false;
    }
  }

  /// ---------------- WATCH USER APPROVAL (REALTIME) ----------------
  static RealtimeChannel watchUserApproval(
    String userId,
    ValueChanged<bool> onApproved,
  ) {
    final channel = _supabase
        .channel('user_approval_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            column: 'id',
            value: userId,
            type: PostgresChangeFilterType.eq,
          ),
          callback: (payload) {
            final isApproved =
                payload.newRecord['is_approved'] as bool? ?? false;
            if (isApproved) {
              onApproved(true);
            }
          },
        )
        .subscribe();

    return channel;
  }
}
