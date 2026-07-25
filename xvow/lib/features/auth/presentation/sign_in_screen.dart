import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aujourd’hui est une nouvelle occasion de tenir vos promesses.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 24),
              const _IntroIllustration(),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XVOW vous aide à vous engager avec clarté, pas avec surcharge.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Définissez quelques vœux puissants, verrouillez votre semaine et avancez avec une discipline mesurable.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Continuer avec Google',
                      loading: _loading,
                      onPressed: _signIn,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (error) {
      setState(
        () => _error =
            'Connexion impossible pour le moment. Vérifiez votre configuration Google OAuth.',
      );
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
