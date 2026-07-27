import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _loading = false;
  String? _error;
  ProviderSubscription<AsyncValue<User?>>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AsyncValue<User?>>(authUserProvider, (
      previous,
      next,
    ) {
      final user = next.asData?.value;
      if (user != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/app/focus');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Bienvenue.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Une nouvelle occasion de reprendre le contrôle.',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 24),
              const _IntroIllustration(),
              const SizedBox(height: 40),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XVOW vous aide à vous engager avec clarté, pas avec surcharge.',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Définissez quelques défis puissants, verrouillez votre semaine et avancez avec une discipline mesurable.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 30),
                    PrimaryButton(
                      label: 'Continuer avec Google',
                      loading: _loading,
                      onPressed: _signIn,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/auth/signup'),
                  child: const Text('Nouveau sur l’app ? Créer un compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (_loading) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Router will automatically redirect on successful auth
    } on XvowAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de connexion: ${e.message}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              'Connexion impossible pour le moment. Vérifiez votre configuration Google OAuth.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _IntroIllustration extends StatelessWidget {
  const _IntroIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF1F4E5F), Color(0xFF8FB9A8)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 64),
      ),
    );
  }
}
