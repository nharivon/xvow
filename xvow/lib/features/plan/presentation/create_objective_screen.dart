import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/state/app_controller.dart';
import '../../../shared/widgets/xvow_widgets.dart';

class CreateObjectiveScreen extends ConsumerStatefulWidget {
  const CreateObjectiveScreen({super.key});

  @override
  ConsumerState<CreateObjectiveScreen> createState() =>
      _CreateObjectiveScreenState();
}

class _CreateObjectiveScreenState extends ConsumerState<CreateObjectiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _motivationController = TextEditingController();
  final List<TextEditingController> _vowControllers = List.generate(
    AppConstants.maxPlannedVowsPerObjective,
    (_) => TextEditingController(),
  );
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _motivationController.dispose();
    for (final controller in _vowControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un Objectif')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Étape 1 · Donnez une direction claire.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de l’objectif',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Le titre est obligatoire.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'La description est obligatoire.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _motivationController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Motivation (optionnelle)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '5 semaines',
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Durée'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Étape 2 · Ajoutez jusqu’à 5 vœux planifiés.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    AppConstants.maxPlannedVowsPerObjective,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _vowControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Promesse ${index + 1}',
                        ),
                        validator: index == 0
                            ? (value) => (value == null || value.trim().isEmpty)
                                  ? 'Ajoutez au moins une promesse.'
                                  : null
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Enregistrer l’Objectif',
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vows = _vowControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      await ref
          .read(appControllerProvider.notifier)
          .createObjective(
            title: _titleController.text,
            description: _descriptionController.text,
            motivation: _motivationController.text,
            plannedVows: vows,
          );
      if (!mounted || !context.mounted) {
        return;
      }
      context.pop();
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
