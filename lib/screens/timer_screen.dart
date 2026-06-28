import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../providers/timer_provider.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerProvider>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Chronomètre',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Mesurez une session ponctuelle, puis ajoutez-la comme complément au dossier.',
        ),
        const SizedBox(height: 28),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    DropdownButtonFormField<ActionType>(
                      initialValue: timer.type,
                      decoration: const InputDecoration(
                        labelText: 'Type de complément',
                      ),
                      items: ActionType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: timer.hasSession
                          ? null
                          : (value) => timer.setType(value!),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      _clock(timer.elapsed),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timer.isRunning
                          ? 'Session en cours'
                          : timer.hasSession
                          ? 'Session en pause'
                          : 'Prêt à démarrer',
                    ),
                    const SizedBox(height: 30),
                    if (!timer.hasSession)
                      FilledButton.icon(
                        onPressed: timer.start,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Démarrer une session'),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: timer.isRunning
                                ? timer.pause
                                : timer.resume,
                            icon: Icon(
                              timer.isRunning ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              timer.isRunning ? 'Pause' : 'Reprendre',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _stop(context, timer),
                            icon: const Icon(Icons.stop),
                            label: const Text('Arrêter'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Card(
          child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Votre complément reste privé'),
            subtitle: Text(
              'Le chronomètre ne surveille aucune application. Il compte uniquement le temps après votre action explicite.',
            ),
          ),
        ),
      ],
    );
  }

  String _clock(Duration value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.inHours)}:${two(value.inMinutes.remainder(60))}:${two(value.inSeconds.remainder(60))}';
  }

  Future<void> _stop(BuildContext context, TimerProvider timer) async {
    final result = timer.stop();
    if (result == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune session à arrêter.')),
        );
      }
      return;
    }
    final notesController = TextEditingController();
    final titleController = TextEditingController(text: result.type.label);
    try {
      if (!context.mounted) return;
      final save = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Créer le complément'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Titre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Durée mesurée : ${_clock(result.elapsed)}',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Ignorer'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      );
      if (save == true && context.mounted) {
        await context.read<ActivityProvider>().save(
          Activity(
            id: const Uuid().v4(),
            title: titleController.text.trim().isEmpty
                ? result.type.label
                : titleController.text.trim(),
            type: result.type,
            date: result.start,
            startTime: result.start,
            endTime: result.end,
            platform: ActivityPlatform.other,
            notes: notesController.text.trim(),
            status: ActivityStatus.draft,
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complément ajouté au dossier.')),
          );
        }
      }
    } finally {
      titleController.dispose();
      notesController.dispose();
    }
  }
}
