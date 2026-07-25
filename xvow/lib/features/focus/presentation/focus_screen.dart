import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(appControllerProvider.notifier).refreshWeekLifecycle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final snapshot = appState.snapshot;
    final today = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour ${snapshot.displayName.split(' ').first} 👋',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              today,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(appControllerProvider.notifier).refreshWeekLifecycle(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Niveau ${snapshot.level}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${snapshot.xpIntoLevel} / ${snapshot.xpForNextLevel} XP',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${snapshot.level}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Vos Promesses',
              subtitle: '${snapshot.activeWeeklyVows.length} / 3 terminées',
            ),
            const SizedBox(height: 12),
            if (snapshot.activeWeeklyVows.isEmpty)
              const EmptyStateView(
                title: 'Aucune promesse active',
                message:
                    'Lancez votre semaine pour afficher vos engagements de focus.',
              )
            else
              ...snapshot.activeWeeklyVows.map((vow) {
                final checked = vow.checkedToday(DateTime.now());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.track_changes_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vow.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vow.sourceObjectiveTitle,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF64748B),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${vow.checkInCount} / 7 jours',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(value: vow.checkInCount / 7),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () => ref
                                .read(appControllerProvider.notifier)
                                .toggleCheckIn(vow.id),
                            style: FilledButton.styleFrom(
                              backgroundColor: checked
                                  ? const Color(0xFF16A34A)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                checked
                                    ? 'Check-in validé'
                                    : 'Valider le check-in',
                                key: ValueKey(checked),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Vos Objectifs',
              subtitle: 'Affichés à partir des promesses actives',
            ),
            const SizedBox(height: 12),
            if (snapshot.activeObjectives.isEmpty)
              const EmptyStateView(
                title: 'Aucun objectif actif',
                message: 'Créez un objectif dans l’onglet Plan pour commencer.',
              )
            else
              ...snapshot.activeObjectives.map(
                (objective) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                            Text(
                              '${objective.remainingWeeks} sem. restantes',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: objective.progressRatio),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progression',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${(objective.progressRatio * 100).round()} %',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Santé',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${objective.health} / 100',
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
          ],
        ),
      ),
    );
  }
}
