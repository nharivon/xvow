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
  final Set<String> _selectedPlannedVowIds = <String>{};

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
            child: const Text('Créer un objectif'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planifiez votre semaine',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Structurez vos objectifs, puis déployez vos promesses.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded),
                    const SizedBox(width: 8),
                    Text(
                      'Mode',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'plan', label: Text('Plan')),
                    ButtonSegment(value: 'deploy', label: Text('Déployer')),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (values) =>
                      setState(() => _segment = values.first),
                ),
              ],
            ),
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
            if (activeObjectives.isNotEmpty) ...[
              const SectionHeader(
                title: 'Vos objectifs',
                subtitle: 'Sélectionnez un objectif pour voir ses détails',
              ),
              const SizedBox(height: 12),
              ...activeObjectives.map(
                (objective) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _showObjectiveDetails(context, objective),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  objective.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              StatusBadge(
                                label: 'Actif',
                                success: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${objective.plannedVowCount} vœux planifiés',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF64748B)),
                              ),
                              Text(
                                '${objective.completedWeeks}/${AppConstants.objectiveDurationWeeks} semaines',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (_segment == 'deploy') ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sélectionnez directement vos promesses pour cette semaine.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous pouvez lancer jusqu’à 3 promesses en une seule fois.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      StatusBadge(
                        label: '${_selectedPlannedVowIds.length}/3 sélectionnées',
                        success: true,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _selectedPlannedVowIds.isEmpty
                            ? null
                            : () => setState(_selectedPlannedVowIds.clear),
                        child: const Text('Tout effacer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(
              title: 'Promesses disponibles',
              subtitle: 'Cochez celles que vous voulez déployer',
            ),
            const SizedBox(height: 12),
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
                    child: CheckboxListTile.adaptive(
                      value: _selectedPlannedVowIds.contains(tile.plannedVowId),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            if (_selectedPlannedVowIds.length < 3) {
                              _selectedPlannedVowIds.add(tile.plannedVowId);
                            }
                          } else {
                            _selectedPlannedVowIds.remove(tile.plannedVowId);
                          }
                        });
                      },
                      title: Text(
                        tile.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        tile.objectiveTitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Lancer la semaine',
              loading: appState.isSyncing,
              onPressed: _selectedPlannedVowIds.isEmpty
                  ? null
                  : () async {
                      try {
                        final currentContext = context;
                        await ref
                            .read(appControllerProvider.notifier)
                            .launchWeek(_selectedPlannedVowIds.toList());
                        if (!mounted || !currentContext.mounted) return;
                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Semaine lancée et synchronisée. '),
                          ),
                        );
                      } catch (error) {
                        if (!mounted || !context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                objective.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(objective.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Progression',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${objective.completedWeeks} / ${AppConstants.objectiveDurationWeeks}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Santé',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${objective.health} / 100',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
