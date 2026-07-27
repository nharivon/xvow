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
        title: Text(
              toBeginningOfSentenceCase(today, 'en_US'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
            ),
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
            const SizedBox(height: 20),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child:
                        Text(
                          'Niveau ${snapshot.level}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        )
                  ),
                  Text(
                          '${snapshot.xpIntoLevel} / ${snapshot.xpForNextLevel} XP',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF64748B)),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const SectionHeader(
              title: 'Défis en cours:',
              subtitle: 'Suivez vos engagements du jour',
            ),
            const SizedBox(height: 20),
            if (snapshot.activeWeeklyVows.isEmpty)
              const EmptyStateView(
                title: 'Aucun défi actif',
                message:
                    'Lancez votre semaine pour afficher vos engagements de focus.',
              )
            else
              ...snapshot.activeWeeklyVows.map((vow) {
                final checked = vow.checkedToday(DateTime.now());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: GestureDetector(
                                onTap: () => ref
                                    .read(appControllerProvider.notifier)
                                    .toggleCheckIn(vow.id),

                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: 32,
                                  height: 32,

                                  decoration: BoxDecoration(
                                    color: checked
                                        ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.08),

                                    borderRadius: BorderRadius.circular(10),

                                    border: Border.all(
                                      color: checked
                                          ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                  ),

                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),

                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      );
                                    },

                                    child: checked
                                        ? const Icon(
                                            Icons.check_rounded,
                                            key: ValueKey(true),
                                            size: 21,
                                            color: Color(0xFF16A34A),
                                          )
                                        : Icon(
                                            Icons.circle_outlined,
                                            key: const ValueKey(false),
                                            size: 17,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vow.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
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
                            // StatusBadge(
                            //   label: checked ? 'OK' : 'À faire',
                            //   success: checked,
                            // ),
                            
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 40),
            const SectionHeader(
              title: 'Vos Objectifs',
              subtitle: 'Affichés à partir des défis actives',
            ),
            const SizedBox(height: 20),
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
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w500, color: const Color(0xFF1F4E5F)),
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
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Health',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${objective.health} %',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
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
