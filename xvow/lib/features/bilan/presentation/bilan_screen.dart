import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class BilanScreen extends ConsumerWidget {
  const BilanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(appControllerProvider).snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Bilan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résumé de votre parcours',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visualisez votre progression et l’impact de vos semaines.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
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
                child: StatChip(
                  label: 'Objectifs complétés',
                  value: '${snapshot.completedObjectivesCount}',
                  icon: Icons.flag_rounded,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(
                  label: 'Discipline',
                  value: '${snapshot.discipline}',
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(
                  label: 'Santé du projet',
                  value: '${snapshot.projectHealth}',
                  icon: Icons.favorite_rounded,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(
                  label: 'Streak',
                  value: '${snapshot.currentStreak}',
                  icon: Icons.auto_graph_rounded,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(
                  label: 'XP gagné',
                  value: '${snapshot.xp}',
                  icon: Icons.bolt_rounded,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 52) / 2,
                child: StatChip(
                  label: 'Pénalités',
                  value: '${snapshot.totalPenalties}',
                  icon: Icons.payments_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Historique', subtitle: 'Vos semaines passées'),
          const SizedBox(height: 12),
          if (snapshot.history.isEmpty)
            const EmptyStateView(
              title: 'Aucun historique',
              message:
                  'Les semaines apparaîtront ici après vos premiers lancements.',
            ),
          if (snapshot.history.isNotEmpty)
            ...snapshot.history.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.badgeLabel,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          StatusBadge(
                            label: entry.badgeLabel,
                            success: entry.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'XP gagné: ${entry.xpGained} · Pénalité: ${entry.penaltyPaid}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...entry.vowStats.map(
                        (stat) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${stat.vowTitle} · ${stat.checkedDays} / 7 jours',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
