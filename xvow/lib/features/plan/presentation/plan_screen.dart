import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  String _segment = 'plan';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final snapshot = appState.snapshot;
    final activeObjectives = snapshot.activeObjectives;
    final plannedVows = snapshot.objectives
        .expand(
          (objective) => objective.plannedVows.map(
            (vow) => _PlannedVowTileData(
              objectiveId: objective.id,
              objectiveTitle: objective.title,
              plannedVowId: vow.id,
              title: vow.title,
            ),
          ),
        )
        .toList();
    final canCreate =
        activeObjectives.length < AppConstants.maxActiveObjectives;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          TextButton(
            onPressed: canCreate
                ? () => context.push('/app/plan/create-objective')
                : null,
            child: const Text('Créer un Objectif'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'plan', label: Text('Plan')),
              ButtonSegment(value: 'deploy', label: Text('Déployer')),
            ],
            selected: {_segment},
            onSelectionChanged: (values) =>
                setState(() => _segment = values.first),
          ),
          const SizedBox(height: 16),
          if (_segment == 'plan') ...[
            if (!canCreate)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: EmptyStateView(
                  title: 'Limite atteinte',
                  message:
                      'Vous devez terminer un objectif actif avant d’en créer un nouveau.',
                ),
              ),
            if (activeObjectives.isEmpty)
              const EmptyStateView(
                title: 'Aucun objectif actif',
                message:
                    'Créez votre premier objectif pour bâtir votre discipline.',
              ),
            if (activeObjectives.isNotEmpty)
              ...activeObjectives.map(
                (objective) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _showObjectiveDetails(context, objective),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            objective.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            objective.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: objective.progressRatio,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${objective.plannedVowCount} vœux planifiés · 5 semaines',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
          if (_segment == 'deploy') ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choisissez jusqu’à 3 promesses pour cette semaine.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Une semaine réussie nécessite au moins 3 jours de validation.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Verrouiller et Lancer',
                    onPressed: plannedVows.isEmpty
                        ? null
                        : () => context.push('/app/plan/launch'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (plannedVows.isEmpty)
              const EmptyStateView(
                title: 'Aucune promesse planifiée',
                message: 'Ajoutez d’abord des vœux à vos objectifs.',
              ),
            if (plannedVows.isNotEmpty)
              ...plannedVows.map(
                (tile) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tile.title,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                tile.objectiveTitle,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showObjectiveDetails(BuildContext context, dynamic objective) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                objective.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(objective.description),
              const SizedBox(height: 12),
              Text(
                'Progression: ${objective.completedWeeks} / ${AppConstants.objectiveDurationWeeks}',
              ),
              const SizedBox(height: 8),
              Text('Santé: ${objective.health} / 100'),
            ],
          ),
        );
      },
    );
  }
}

class _PlannedVowTileData {
  const _PlannedVowTileData({
    required this.objectiveId,
    required this.objectiveTitle,
    required this.plannedVowId,
    required this.title,
  });
  final String objectiveId;
  final String objectiveTitle;
  final String plannedVowId;
  final String title;
}
