import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../models/proof_file.dart';
import '../providers/activity_provider.dart';
import '../providers/proof_provider.dart';
import '../services/file_picker_service.dart';
import '../services/pdf_export_service.dart';
import '../services/zip_export_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _name = TextEditingController();
  late DateTime _start;
  late DateTime _end;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<ActivityProvider>().activities;
    final selected = _selectedActivities(all);
    final proofs = _selectedProofs(
      selected,
      context.watch<ProofProvider>().proofs,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Rapport',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text('Préparez un dossier PDF ou une archive complète ZIP.'),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la personne',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _pickRange,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        '${DateFormat('dd/MM/yyyy').format(_start)} – ${DateFormat('dd/MM/yyyy').format(_end)}',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _Summary(
                      actions: selected.length,
                      proofs: proofs.length,
                      duration: selected.fold(
                        Duration.zero,
                        (sum, item) => sum + item.duration,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _generating ? null : () => _export(zip: false),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text('Exporter le rapport PDF'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _generating ? null : () => _export(zip: true),
                      icon: const Icon(Icons.folder_zip_outlined),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text('Exporter le dossier ZIP complet'),
                      ),
                    ),
                    if (_generating) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Card(
          child: ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Traitement entièrement local'),
            subtitle: Text(
              'Le rapport et l’archive sont générés sur cet appareil. Aucun fichier n’est envoyé à un serveur.',
            ),
          ),
        ),
      ],
    );
  }

  List<Activity> _selectedActivities(List<Activity> all) =>
      all
          .where(
            (item) => !item.date.isBefore(_start) && !item.date.isAfter(_end),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<ProofFile> _selectedProofs(
    List<Activity> activities,
    List<ProofFile> all,
  ) {
    final ids = activities.expand((item) => item.proofIds).toSet();
    return all
        .where(
          (proof) =>
              ids.contains(proof.id) ||
              (proof.activityId != null &&
                  activities.any((item) => item.id == proof.activityId)),
        )
        .toList();
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (range != null) {
      setState(() {
        _start = range.start;
        _end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  Future<void> _export({required bool zip}) async {
    setState(() => _generating = true);
    try {
      final activities = _selectedActivities(
        context.read<ActivityProvider>().activities,
      );
      final proofs = _selectedProofs(
        activities,
        context.read<ProofProvider>().proofs,
      );
      final pdf = await PdfExportService().generate(
        personName: _name.text.trim(),
        start: _start,
        end: _end,
        activities: activities,
        proofs: proofs,
      );
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final bytes = zip
          ? ZipExportService().generate(report: pdf, proofs: proofs)
          : pdf;
      final fileName = zip
          ? 'RecruitProof_rapport_$date.zip'
          : 'RecruitProof_rapport_$date.pdf';
      await FilePickerService().saveBytes(fileName: fileName, bytes: bytes);
      if (mounted) {
        await context.read<ActivityProvider>().markReportGenerated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fileName généré avec succès.')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export impossible : $error')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.actions,
    required this.proofs,
    required this.duration,
  });

  final int actions;
  final int proofs;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 20,
        runSpacing: 12,
        children: [
          _item(context, '$actions', 'actions'),
          _item(
            context,
            '${duration.inHours}h ${duration.inMinutes.remainder(60)}',
            'déclarées',
          ),
          _item(context, '$proofs', 'preuves jointes'),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, String value, String label) => Column(
    children: [
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(label),
    ],
  );
}
