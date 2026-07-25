import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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
              const SizedBox(height: 28),
              Text(
                'Un engagement solide commence ici.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choisissez peu, mais choisissez fort. XVOW vous aide à transformer vos promesses en preuves.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SignupIllustration(),
                    const SizedBox(height: 20),
                    Text(
                      'Créez votre espace d’auto-responsabilité.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Une interface minimaliste, des promesses verrouillées et une semaine à la fois.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'S’inscrire avec Google',
                      loading: _loading,
                      onPressed: _signUp,
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
                  onPressed: () => context.go('/auth/signin'),
                  child: const Text('J’ai déjà un compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // Router wil automatically redirect on successful auth
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur d\'inscription: ${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              "Impossible de démarrer l'inscription. Vérifiez la configuration Google OAuth.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _SignupIllustration extends StatelessWidget {
  const _SignupIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF6D365), Color(0xFFFDA085)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.flag_rounded, color: Colors.white, size: 54),
      ),
    );
  }
}