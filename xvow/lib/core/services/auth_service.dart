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

class AuthService {
  AuthService(this.client);

  final SupabaseClient client;

  Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? Uri.base.origin : null,
    );
  }

  Future<void> signOut() => client.auth.signOut();

  Future<void> deleteLocalSession() async {
    await client.auth.signOut();
  }
}
