import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Stream<User?> authUserChanges(SupabaseClient client) async* {
  yield client.auth.currentUser;
  await for (final state in client.auth.onAuthStateChange) {
    yield state.session?.user;
  }
}

final authUserProvider = StreamProvider<User?>((ref) async* {
  final client = Supabase.instance.client;
  yield* authUserChanges(client);
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

/// Provider to ensure user profile exists in Supabase
final ensureProfileExistsProvider = FutureProvider.family<void, User>((
  ref,
  user,
) async {
  final authService = ref.read(authServiceProvider);
  await authService.ensureProfileExists(user: user);
});

class AuthService {
  AuthService(this.client);

  final SupabaseClient client;

  /// Sign in with Google OAuth and ensure profile is created
  Future<void> signInWithGoogle() async {
    try {
      final result = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );

      // On successful OAuth, ensure profile exists
      if (result) {
        await ensureProfileExists();
      }
    } catch (e) {
      throw XvowAuthException('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Ensure user profile exists in Supabase after OAuth login
  Future<void> ensureProfileExists({User? user}) async {
    try {
      final resolvedUser = user ?? client.auth.currentUser;
      if (resolvedUser == null) return;

      final userId = resolvedUser.id;
      final fullName = (resolvedUser.userMetadata?['full_name'] ??
        resolvedUser.userMetadata?['name'] ??
          'User') as String;
      final email = resolvedUser.email ?? '';

      // Check if profile already exists
      final existingProfile = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile with Google OAuth data
        await client.from('profiles').insert({
          'id': userId,
          'full_name': fullName,
          'email': email,
          'push_enabled': true,
          'discipline': 100,
          'project_health': 100,
          'current_streak': 0,
          'total_xp': 0,
          'total_penalties': 0,
          'total_savings': 0,
        });
      } else {
        // Update existing profile with latest Google data
        await client.from('profiles').update({
          'full_name': fullName.isEmpty ? existingProfile['full_name'] : fullName,
          'email': email.isEmpty ? existingProfile['email'] : email,
        }).eq('id', userId);
      }
    } catch (e) {
      // Log but don't throw - profile creation should not block auth
      print('Error ensuring profile exists: $e');
    }
  }

  Future<void> signOut() => client.auth.signOut();

  Future<void> deleteLocalSession() async {
    await client.auth.signOut();
  }
}

class XvowAuthException implements Exception {
  XvowAuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
