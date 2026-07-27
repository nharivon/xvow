import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class LaunchWeekScreen extends ConsumerStatefulWidget {
  const LaunchWeekScreen({super.key});

  @override
  ConsumerState<LaunchWeekScreen> createState() => _LaunchWeekScreenState();
}

class _LaunchWeekScreenState extends ConsumerState<LaunchWeekScreen> {
  final Set<String> _selected = <String>{};
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(appControllerProvider).snapshot;
    final vows = snapshot.objectives
        .expand(
          (objective) => objective.plannedVows.map(
            (vow) => _VowSelection(
              objectiveTitle: objective.title,
              plannedVowId: vow.id,
              title: vow.title,
            ),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Lancer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          AppCard(
            child: Text(
              'Choisissez jusqu’à 3 promesses pour cette semaine. Une semaine réussie nécessite au moins 3 jours de validation.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          if (vows.isEmpty)
            const EmptyStateView(
              title: 'Aucune promesse disponible',
              message: 'Créez d’abord des objectifs et leurs vœux planifiés.',
            ),
          if (vows.isNotEmpty)
            ...vows.map(
              (vow) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CheckboxListTile(
                  value: _selected.contains(vow.plannedVowId),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        if (_selected.length <
                            AppConstants.maxActiveWeeklyVows) {
                          _selected.add(vow.plannedVowId);
                        }
                      } else {
                        _selected.remove(vow.plannedVowId);
                      }
                    });
                  },
                  title: Text(vow.title),
                  subtitle: Text(vow.objectiveTitle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sélection actuelle',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _selected.isEmpty
                      ? 'Aucune promesse sélectionnée'
                      : '${_selected.length} promesse(s) prêtes à être verrouillées.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Verrouiller et Lancer',
            loading: _loading,
            onPressed: _selected.isEmpty ? null : _confirmLaunch,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLaunch() async {
    final currentContext = context;
    final confirmed = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Paiement virtuel'),
        content: const Text(
          'Vous vous engagez via un dépôt fictif de 2 \$. Aucune transaction réelle ne sera effectuée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(appControllerProvider.notifier)
          .launchWeek(_selected.toList());
      if (!mounted || !currentContext.mounted) {
        return;
      }
      currentContext.go('/app/focus');
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _VowSelection {
  const _VowSelection({
    required this.objectiveTitle,
    required this.plannedVowId,
    required this.title,
  });
  final String objectiveTitle;
  final String plannedVowId;
  final String title;
}
