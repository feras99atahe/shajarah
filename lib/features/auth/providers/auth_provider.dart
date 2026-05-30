import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('user_profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();
  return data?['role'] as String?;
});

final userFamilyIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('user_profiles')
      .select('family_id')
      .eq('id', user.id)
      .maybeSingle();
  return data?['family_id'] as String?;
});

class AuthNotifier extends AsyncNotifier<void> {
  SupabaseClient get _supabase => ref.read(supabaseProvider);

  @override
  Future<void> build() async {}

  /// Sign up with phone + password — throws on any error so the UI can catch it.
  /// Requires "Confirm phone" to be OFF in Supabase Auth settings.
  Future<void> signUpWithPhone(String phone, String password) async {
    final res = await _supabase.auth.signUp(
      phone: phone,
      password: password,
    );
    // If session is null after signUp it means phone confirmation is still ON
    if (res.session == null && res.user == null) {
      throw AuthException(
        'Account created but not confirmed. '
        'Go to Supabase → Auth → Providers → Phone → disable "Confirm phone".',
      );
    }
  }

  /// Sign in with phone + password — throws on any error so the UI can catch it.
  Future<void> signInWithPhone(String phone, String password) async {
    await _supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  /// Admin / auditor login via email + password.
  Future<void> signInWithEmailPassword(String email, String password) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> upsertProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? familyId,
    String role = 'viewer',
  }) async {
    await _supabase.from('user_profiles').upsert({
      'id': userId,
      'full_name': fullName,
      'phone': phone,
      'family_id': familyId,
      'role': role,
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
