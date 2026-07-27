import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xvow/shared/widgets/text_input.dart';

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
      appBar: AppBar(title: const Text('Créer un Objectif', style: TextStyle(fontSize: 14))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const SizedBox(height: 17),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 7,
                children: [
                  Text(
                    'Étape 1 · Votre objectif dans 5 semaines',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F4E5F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextInput(
                    controller: _titleController, 
                    labelText: 'Titre de l’objectif',
                    hintText: 'Ex: apprendre à coder en Dart',
                  ),
                  const SizedBox(height: 20),
                  TextInput(
                    controller: _descriptionController,
                    labelText: 'Description',
                    hintText: 'Dart est un langage de programmation orienté objet, développé par Google, qui est utilisé pour créer des applications mobiles, web et de bureau. Il est souvent utilisé avec le framework Flutter pour développer des applications multiplateformes.',
                    maxLines: 3,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'La description est obligatoire.'
                        : null,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Étape 2 · Ajoutez au maximum 5 défis',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F4E5F),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    AppConstants.maxPlannedVowsPerObjective,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: TextInput(
                        controller: _vowControllers[index],
                        labelText: 'Défi ${index + 1}',
                        hintText: switch (index) {
                          0 => 'Ex: faire 10 pompes par jour',
                          1 => 'Ex: courir 3 km tous les matins',
                          2 => 'Ex: méditer 15 minutes chaque soir',
                          3 => 'Ex: lire un chapitre d’un livre chaque jour',
                          4 => 'Ex: écrire un journal de gratitude chaque soir',
                          _ => '',
                        },
                        validator: index == 0
                            ? (value) => (value == null || value.trim().isEmpty)
                                  ? 'Ajoutez au moins un défi.'
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
              label: 'Créer',
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
