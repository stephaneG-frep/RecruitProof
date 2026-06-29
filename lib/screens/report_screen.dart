import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../models/imported_report_file.dart';
import '../models/imported_report_item.dart';
import '../models/proof_file.dart';
import '../providers/activity_provider.dart';
import '../providers/imported_data_provider.dart';
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
  final _contextLabel = TextEditingController();
  final _applicationsCount = TextEditingController();
  final _followUpsCount = TextEditingController();
  final _interviewsCount = TextEditingController();
  final _reportHours = TextEditingController();
  final _reportMinutes = TextEditingController();
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
    _contextLabel.dispose();
    _applicationsCount.dispose();
    _followUpsCount.dispose();
    _interviewsCount.dispose();
    _reportHours.dispose();
    _reportMinutes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<ActivityProvider>().activities;
    final selected = _selectedActivities(all);
    final importedProvider = context.watch<ImportedDataProvider>();
    final imported = importedProvider.forPeriod(_start, _end);
    final importedFiles = importedProvider.files;
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
        const Text(
          'Préparez un dossier PDF ou une archive ZIP solide avec vos compléments et plusieurs rapports preuves.',
        ),
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
                    TextField(
                      controller: _contextLabel,
                      decoration: const InputDecoration(
                        labelText: 'Entreprise / contexte du rapport',
                        hintText:
                            'Ex. recherches France Travail, secteur visé…',
                        prefixIcon: Icon(Icons.business_outlined),
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
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.calendar_view_month),
                          label: const Text('Mois en cours'),
                          onPressed: _selectCurrentMonth,
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.view_week_outlined),
                          label: const Text('Semaine en cours'),
                          onPressed: _selectCurrentWeek,
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.all_inclusive),
                          label: const Text('Tout inclure'),
                          onPressed: () => _selectAllPeriod(
                            activities: all,
                            proofs: context.read<ProofProvider>().proofs,
                            importedItems: importedProvider.items,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _ManualCounters(
                      applications: _applicationsCount,
                      followUps: _followUpsCount,
                      interviews: _interviewsCount,
                      reportHours: _reportHours,
                      reportMinutes: _reportMinutes,
                    ),
                    const SizedBox(height: 20),
                    _Summary(
                      actions: selected.length,
                      imported: imported.length,
                      proofs: proofs.length,
                      importedProofs:
                          imported.fold(
                            0,
                            (sum, item) => sum + item.proofCount,
                          ) +
                          importedFiles.length,
                      duration:
                          selected.fold(
                            Duration.zero,
                            (sum, item) => sum + item.duration,
                          ) +
                          Duration(
                            minutes: imported.fold(
                              0,
                              (sum, item) => sum + item.durationMinutes,
                            ),
                          ) +
                          _manualReportDuration(),
                    ),
                    const SizedBox(height: 14),
                    _IncludedPreview(
                      complements: selected,
                      proofs: proofs,
                      totalComplements: all.length,
                      totalProofs: context.watch<ProofProvider>().proofs.length,
                    ),
                    const SizedBox(height: 18),
                    _SourceImportsCard(
                      jobTimeCount: importedProvider.countForSource(
                        ImportedSourceType.jobTimeProof,
                      ),
                      jobTimeFileCount: importedProvider.fileCountForSource(
                        ImportedSourceType.jobTimeProof,
                      ),
                      jobTrackerCount: importedProvider.countForSource(
                        ImportedSourceType.jobTracker,
                      ),
                      jobTrackerFileCount: importedProvider.fileCountForSource(
                        ImportedSourceType.jobTracker,
                      ),
                      reportFiles: importedFiles,
                      onImport: _importSource,
                      onClear: _clearSource,
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
              'Les imports sont manuels. Le rapport et l’archive sont générés sur cet appareil. Aucun fichier n’est envoyé à un serveur.',
            ),
          ),
        ),
      ],
    );
  }

  List<Activity> _selectedActivities(List<Activity> all) =>
      all
          .where(
            (item) =>
                !_startOfDay(item.date).isBefore(_startOfDay(_start)) &&
                !_startOfDay(item.date).isAfter(_startOfDay(_end)),
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
                  activities.any((item) => item.id == proof.activityId)) ||
              (proof.activityId == null &&
                  !proof.addedAt.isBefore(_start) &&
                  !proof.addedAt.isAfter(_end)),
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

  void _selectCurrentMonth() {
    final now = DateTime.now();
    setState(() {
      _start = DateTime(now.year, now.month);
      _end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    });
  }

  void _selectCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _start = today.subtract(Duration(days: now.weekday - 1));
      _end = _start.add(const Duration(days: 6, hours: 23, minutes: 59));
    });
  }

  void _selectAllPeriod({
    required List<Activity> activities,
    required List<ProofFile> proofs,
    required List<ImportedReportItem> importedItems,
  }) {
    final dates = <DateTime>[
      ...activities.map((item) => item.date),
      ...proofs.map((item) => item.addedAt),
      ...importedItems.map((item) => item.date),
      DateTime.now(),
    ];
    dates.sort();
    final first = dates.first;
    final last = dates.last;
    setState(() {
      _start = DateTime(first.year, first.month, first.day);
      _end = DateTime(last.year, last.month, last.day, 23, 59, 59);
    });
  }

  DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

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
      final importedItems = context.read<ImportedDataProvider>().forPeriod(
        _start,
        _end,
      );
      final importedFiles = context.read<ImportedDataProvider>().files;
      final pdf = await PdfExportService().generate(
        personName: _name.text.trim(),
        start: _start,
        end: _end,
        activities: activities,
        importedItems: importedItems,
        importedFiles: importedFiles,
        proofs: proofs,
        contextLabel: _contextLabel.text.trim(),
        manualApplications: _optionalInt(_applicationsCount.text),
        manualFollowUps: _optionalInt(_followUpsCount.text),
        manualInterviews: _optionalInt(_interviewsCount.text),
        manualReportDuration: _manualReportDuration(),
      );
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final bytes = zip
          ? ZipExportService().generate(
              report: pdf,
              proofs: proofs,
              importedFiles: importedFiles,
            )
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

  Future<void> _importSource(ImportedSourceType source) async {
    try {
      final summary = await context.read<ImportedDataProvider>().importFromFile(
        source,
      );
      if (!mounted || summary == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            summary.files > 0
                ? '${summary.files} rapport(s) preuve(s) ajouté(s) depuis ${summary.source.label}.'
                : '${summary.imported} lignes importées depuis ${summary.source.label}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import impossible : $error')));
    }
  }

  Future<void> _clearSource(ImportedSourceType source) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer les imports ${source.label} ?'),
        content: const Text(
          'Cela retire seulement les données importées dans RecruitProof. Le fichier source et les autres applications ne sont pas modifiés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await context.read<ImportedDataProvider>().clearSource(source);
  }

  int? _optionalInt(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  Duration _manualReportDuration() {
    final hours = _optionalInt(_reportHours.text) ?? 0;
    final minutes = _optionalInt(_reportMinutes.text) ?? 0;
    return Duration(hours: hours, minutes: minutes);
  }
}

class _ManualCounters extends StatelessWidget {
  const _ManualCounters({
    required this.applications,
    required this.followUps,
    required this.interviews,
    required this.reportHours,
    required this.reportMinutes,
  });

  final TextEditingController applications;
  final TextEditingController followUps;
  final TextEditingController interviews;
  final TextEditingController reportHours;
  final TextEditingController reportMinutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compteurs manuels du rapport',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Laissez vide pour calcul automatique. Remplissez si les chiffres viennent de rapports preuves PDF.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CounterField(
                controller: applications,
                label: 'Candidatures',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CounterField(controller: followUps, label: 'Relances'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CounterField(controller: interviews, label: 'Entretiens'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Temps déclaré dans les rapports preuves',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'À remplir quand les PDF JobTime/JobTracker contiennent du temps, car RecruitProof ne lit pas automatiquement le contenu des PDF.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CounterField(controller: reportHours, label: 'Heures'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CounterField(controller: reportMinutes, label: 'Minutes'),
            ),
          ],
        ),
      ],
    );
  }
}

class _IncludedPreview extends StatelessWidget {
  const _IncludedPreview({
    required this.complements,
    required this.proofs,
    required this.totalComplements,
    required this.totalProofs,
  });

  final List<Activity> complements;
  final List<ProofFile> proofs;
  final int totalComplements;
  final int totalProofs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final missingComplements = totalComplements - complements.length;
    final missingProofs = totalProofs - proofs.length;
    return Card(
      color: complements.isEmpty && totalComplements > 0
          ? scheme.errorContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inclus dans ce PDF',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${complements.length} complément(s) • ${proofs.length} preuve(s)',
            ),
            if (missingComplements > 0 || missingProofs > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Hors période actuelle : $missingComplements complément(s), $missingProofs preuve(s). Utilisez “Tout inclure” si besoin.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
            if (complements.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...complements
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.note_alt_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            if (proofs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...proofs
                  .take(3)
                  .map(
                    (proof) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.attachment_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proof.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CounterField extends StatelessWidget {
  const _CounterField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.actions,
    required this.imported,
    required this.proofs,
    required this.importedProofs,
    required this.duration,
  });

  final int actions;
  final int imported;
  final int proofs;
  final int importedProofs;
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
          _item(context, '$imported', 'lignes importées'),
          _item(context, _durationLabel(duration), 'déclarées'),
          _item(context, '${proofs + importedProofs}', 'preuves jointes'),
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

  String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours == 0 && minutes == 0 && seconds > 0) return '${seconds}s';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }
}

class _SourceImportsCard extends StatelessWidget {
  const _SourceImportsCard({
    required this.jobTimeCount,
    required this.jobTimeFileCount,
    required this.jobTrackerCount,
    required this.jobTrackerFileCount,
    required this.reportFiles,
    required this.onImport,
    required this.onClear,
  });

  final int jobTimeCount;
  final int jobTimeFileCount;
  final int jobTrackerCount;
  final int jobTrackerFileCount;
  final List<ImportedReportFile> reportFiles;
  final ValueChanged<ImportedSourceType> onImport;
  final ValueChanged<ImportedSourceType> onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sources consolidées',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Importez manuellement les exports de vos autres applis. RecruitProof sert alors de classeur final pour la semaine ou le mois.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            _SourceTile(
              icon: Icons.timer_outlined,
              title: 'JobTime Proof',
              subtitle:
                  '$jobTimeCount ligne(s), $jobTimeFileCount rapport(s) preuve(s)',
              importLabel: 'Ajouter PDF/JSON',
              files: reportFiles
                  .where(
                    (file) => file.source == ImportedSourceType.jobTimeProof,
                  )
                  .toList(),
              onImport: () => onImport(ImportedSourceType.jobTimeProof),
              onClear: jobTimeCount == 0 && jobTimeFileCount == 0
                  ? null
                  : () => onClear(ImportedSourceType.jobTimeProof),
            ),
            const SizedBox(height: 12),
            _SourceTile(
              icon: Icons.work_outline,
              title: 'JobTracker',
              subtitle:
                  '$jobTrackerCount ligne(s), $jobTrackerFileCount rapport(s) preuve(s)',
              importLabel: 'Ajouter PDF/CSV',
              files: reportFiles
                  .where((file) => file.source == ImportedSourceType.jobTracker)
                  .toList(),
              onImport: () => onImport(ImportedSourceType.jobTracker),
              onClear: jobTrackerCount == 0 && jobTrackerFileCount == 0
                  ? null
                  : () => onClear(ImportedSourceType.jobTracker),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.importLabel,
    required this.files,
    required this.onImport,
    required this.onClear,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String importLabel;
  final List<ImportedReportFile> files;
  final VoidCallback onImport;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (files.isEmpty)
            Text(
              'Aucun rapport preuve ajouté pour cette source.',
              style: TextStyle(color: scheme.onSurfaceVariant),
            )
          else ...[
            Text(
              'Rapports preuves ajoutés',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...files.map(
              (file) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 18,
                      color: scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${file.name} • ${file.sizeLabel}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(importLabel),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Retirer cette source'),
          ),
        ],
      ),
    );
  }
}
