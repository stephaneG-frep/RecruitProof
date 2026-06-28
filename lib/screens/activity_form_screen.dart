import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../providers/proof_provider.dart';
import '../widgets/proof_card.dart';

class ActivityFormScreen extends StatefulWidget {
  const ActivityFormScreen({this.activity, super.key});
  final Activity? activity;

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _reference;
  late final TextEditingController _notes;
  late final TextEditingController _durationMinutes;
  late ActionType _type;
  late ActivityPlatform _platform;
  late ActivityStatus _status;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _activityId;
  late List<String> _proofIds;

  @override
  void initState() {
    super.initState();
    final item = widget.activity;
    _activityId = item?.id ?? const Uuid().v4();
    _title = TextEditingController(text: item?.title);
    _reference = TextEditingController(text: item?.reference);
    _notes = TextEditingController(text: item?.notes);
    _durationMinutes = TextEditingController(
      text: item == null || item.duration.inMinutes == 0
          ? ''
          : item.duration.inMinutes.toString(),
    );
    _durationMinutes.addListener(() => setState(() {}));
    _type = item?.type ?? ActionType.other;
    _platform = item?.platform ?? ActivityPlatform.other;
    _status = item?.status ?? ActivityStatus.draft;
    _date = item?.date ?? DateTime.now();
    _start = item == null
        ? TimeOfDay.now()
        : TimeOfDay.fromDateTime(item.startTime);
    _end = item == null
        ? TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)))
        : TimeOfDay.fromDateTime(item.endTime);
    _proofIds = [...?item?.proofIds];
  }

  @override
  void dispose() {
    _title.dispose();
    _reference.dispose();
    _notes.dispose();
    _durationMinutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final proofs = context
        .watch<ProofProvider>()
        .proofs
        .where((proof) => _proofIds.contains(proof.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.activity == null
              ? 'Nouveau complément'
              : 'Modifier le complément',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.edit_note_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Un complément sert à préciser votre dossier : action oubliée, note au conseiller, preuve isolée, rendez-vous ou élément non présent dans les rapports importés.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _title,
              autofocus: widget.activity == null,
              decoration: const InputDecoration(
                labelText: 'Titre du complément *',
                hintText: 'Ex. Précision sur une candidature, document ajouté…',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Veuillez saisir un titre.'
                  : null,
            ),
            const SizedBox(height: 14),
            _twoColumns(
              DropdownButtonFormField<ActionType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type de complément',
                ),
                items: ActionType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _type = value!),
              ),
              DropdownButtonFormField<ActivityPlatform>(
                initialValue: _platform,
                decoration: const InputDecoration(
                  labelText: 'Contexte / plateforme',
                ),
                items: ActivityPlatform.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _platform = value!),
              ),
            ),
            const SizedBox(height: 14),
            _twoColumns(
              _PickerTile(
                icon: Icons.calendar_today,
                label: 'Date du complément',
                value:
                    '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                onTap: _pickDate,
              ),
              Row(
                children: [
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.login,
                      label: 'Début',
                      value: _start.format(context),
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.logout,
                      label: 'Fin',
                      value: _end.format(context),
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationMinutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Temps déclaré en minutes',
                hintText: 'Ex. 20 pour une mise à jour CV',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              validator: (value) {
                final cleaned = value?.trim() ?? '';
                if (cleaned.isEmpty) return null;
                final minutes = int.tryParse(cleaned);
                if (minutes == null || minutes < 1) {
                  return 'Saisissez un nombre de minutes positif.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Durée déclarée : ${_durationLabel()}'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _reference,
              decoration: const InputDecoration(
                labelText: 'URL, entreprise ou référence',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Note pour le dossier',
                hintText:
                    'Expliquez brièvement pourquoi ce complément est utile.',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ActivityStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: ActivityStatus.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Preuves associées',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _addProofs,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (proofs.isEmpty)
              const Text('Aucune preuve associée.')
            else
              ...proofs.map(
                (proof) => ProofCard(
                  proof: proof,
                  onDelete: () => setState(() => _proofIds.remove(proof.id)),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Enregistrer le complément'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _twoColumns(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(children: [first, const SizedBox(height: 14), second]);
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 14),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  DateTime _at(TimeOfDay time) =>
      DateTime(_date.year, _date.month, _date.day, time.hour, time.minute);

  String _durationLabel() {
    final explicitMinutes = _explicitDurationMinutes();
    if (explicitMinutes != null) {
      final value = Duration(minutes: explicitMinutes);
      return '${value.inHours}h ${value.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    }
    final value = _at(_end).difference(_at(_start));
    if (value.isNegative) return 'heure de fin invalide';
    return '${value.inHours}h ${value.inMinutes.remainder(60).toString().padLeft(2, '0')}';
  }

  int? _explicitDurationMinutes() {
    final cleaned = _durationMinutes.text.trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value != null) {
      setState(() => start ? _start = value : _end = value);
    }
  }

  Future<void> _addProofs() async {
    final picked = await context.read<ProofProvider>().pickAndSave(
      activityId: _activityId,
    );
    if (mounted) {
      setState(() => _proofIds.addAll(picked.map((proof) => proof.id)));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _at(_start);
    final explicitMinutes = _explicitDurationMinutes();
    final end = explicitMinutes == null
        ? _at(_end)
        : start.add(Duration(minutes: explicitMinutes));
    if (!end.isAfter(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L’heure de fin doit être après le début.'),
        ),
      );
      return;
    }
    final activity = Activity(
      id: _activityId,
      title: _title.text.trim(),
      type: _type,
      date: _date,
      startTime: start,
      endTime: end,
      platform: _platform,
      reference: _reference.text.trim(),
      notes: _notes.text.trim(),
      status: _status,
      proofIds: _proofIds,
    );
    await context.read<ActivityProvider>().save(activity);
    if (mounted) Navigator.pop(context);
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
