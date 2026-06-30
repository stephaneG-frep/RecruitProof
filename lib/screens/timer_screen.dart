import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../providers/activity_provider.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  ActionType _type = ActionType.offerSearch;
  int _minutes = 30;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Temps estimé',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Déclarez simplement le temps passé par tranches de 10 minutes, sans mesure automatique.',
        ),
        const SizedBox(height: 22),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<ActionType>(
                      initialValue: _type,
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
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _title,
                      decoration: InputDecoration(
                        labelText: 'Titre du complément',
                        hintText: _type.label,
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _DurationPicker(
                      minutes: _minutes,
                      onChanged: (value) => setState(() => _minutes = value),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _notes,
                      minLines: 4,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'Note pour le dossier',
                        hintText:
                            'Ex. Mise à jour CV, veille technologique, apprentissage autodidacte…',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Ajouter au dossier'),
                      ),
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
            title: Text('Estimation volontaire'),
            subtitle: Text(
              'RecruitProof ne surveille aucune application. Vous déclarez vous-même un temps raisonnable pour compléter votre dossier.',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final start = now.subtract(Duration(minutes: _minutes));
    final title = _title.text.trim().isEmpty ? _type.label : _title.text.trim();
    await context.read<ActivityProvider>().save(
      Activity(
        id: const Uuid().v4(),
        title: title,
        type: _type,
        date: now,
        startTime: start,
        endTime: now,
        platform: ActivityPlatform.other,
        notes: _notes.text.trim(),
        status: ActivityStatus.draft,
      ),
    );
    if (!mounted) return;
    _title.clear();
    _notes.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complément ajouté avec ${_formatMinutes(_minutes)}.'),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'Temps déclaré',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _formatMinutes(minutes),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: minutes <= 10
                      ? null
                      : () => onChanged(minutes - 10),
                  icon: const Icon(Icons.remove),
                  label: const Text('-10 min'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onChanged(minutes + 10),
                  icon: const Icon(Icons.add),
                  label: const Text('+10 min'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [10, 20, 30, 60, 90, 120]
                .map(
                  (value) => ChoiceChip(
                    label: Text(_formatMinutes(value)),
                    selected: minutes == value,
                    onSelected: (_) => onChanged(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

String _formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '$minutes min';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining.toString().padLeft(2, '0')}';
}
