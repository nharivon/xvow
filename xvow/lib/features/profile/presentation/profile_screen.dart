import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);
    final snapshot = ref.watch(appControllerProvider).snapshot;
    final initials = snapshot.displayName.isNotEmpty
        ? snapshot.displayName
              .split(' ')
              .take(2)
              .map((part) => part.isNotEmpty ? part[0] : '')
              .join()
              .toUpperCase()
        : 'XV';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1F4E5F),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  snapshot.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Membre depuis ${snapshot.createdAt.year}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(label: 'Niveau', value: '${snapshot.level}'),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(label: 'XP', value: '${snapshot.xp}'),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(
                  label: 'Streak',
                  value: '${snapshot.currentStreak}',
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(
                  label: 'Objectifs',
                  value: '${snapshot.completedObjectivesCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Économie',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('Total économisé: ${snapshot.totalSavings} \$'),
                const SizedBox(height: 4),
                Text('Total pénalités: ${snapshot.totalPenalties} \$'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Paiements · Information'),
            subtitle: const Text('Détails du dépôt virtuel et des pénalités. '),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/app/payment-info'),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: snapshot.pushEnabled,
            onChanged: (value) => controller.setPushEnabled(value),
            title: const Text('Push Notification'),
            subtitle: const Text('Firebase Cloud Messaging'),
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Se déconnecter'),
            leading: const Icon(Icons.logout_rounded),
            onTap: () async => controller.signOut(),
          ),
          const SizedBox(height: 12),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Supprimer le compte',
              style: TextStyle(color: Colors.redAccent),
            ),
            leading: const Icon(
              Icons.delete_forever_rounded,
              color: Colors.redAccent,
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer le compte ?'),
                  content: const Text(
                    'Cette action supprimera vos données locales et fermera votre session.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await controller.deleteAccount();
              }
            },
          ),
        ],
      ),
    );
  }
}
