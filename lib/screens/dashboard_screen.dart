import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../models/imported_report_file.dart';
import '../models/imported_report_item.dart';
import '../providers/activity_provider.dart';
import '../providers/imported_data_provider.dart';
import '../providers/proof_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/stat_card.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activityProvider = context.watch<ActivityProvider>();
    final activities = activityProvider.activities;
    final proofs = context.watch<ProofProvider>().proofs;
    final importedProvider = context.watch<ImportedDataProvider>();
    final importedItems = importedProvider.items;
    final reportFiles = importedProvider.files;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final monthActivities = activities
        .where(
          (item) =>
              !item.date.isBefore(monthStart) && !item.date.isAfter(monthEnd),
        )
        .toList();
    final monthImports = importedItems
        .where(
          (item) =>
              !item.date.isBefore(monthStart) && !item.date.isAfter(monthEnd),
        )
        .toList();
    final total =
        monthActivities.fold<Duration>(
          Duration.zero,
          (sum, item) => sum + item.duration,
        ) +
        Duration(
          minutes: monthImports.fold(
            0,
            (sum, item) => sum + item.durationMinutes,
          ),
        );
    final latest = [...activities]..sort((a, b) => b.date.compareTo(a.date));
    final lastReport = activityProvider.lastReportDate;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _HeroHeader(
          period:
              '${DateFormat('dd/MM/yyyy').format(monthStart)} – ${DateFormat('dd/MM/yyyy').format(monthEnd)}',
          reportCount: reportFiles.length,
          lastReport: lastReport,
        ),
        const SizedBox(height: 18),
        _StatsGrid(
          activities: monthActivities,
          importedItems: monthImports,
          reportFiles: reportFiles,
          proofCount: proofs.length,
          total: total,
        ),
        const SizedBox(height: 22),
        _WorkflowCard(
          jobTimeReports: reportFiles
              .where((file) => file.source == ImportedSourceType.jobTimeProof)
              .length,
          jobTrackerReports: reportFiles
              .where((file) => file.source == ImportedSourceType.jobTracker)
              .length,
        ),
        const SizedBox(height: 22),
        _ReportsCard(reportFiles: reportFiles),
        const SizedBox(height: 22),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Dernier dossier généré'),
            subtitle: Text(
              lastReport == null
                  ? 'Aucun dossier généré'
                  : DateFormat(
                      'dd/MM/yyyy à HH:mm',
                    ).format(DateTime.parse(lastReport)),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Compléments récents',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsScreen())),
              icon: const Icon(Icons.bar_chart),
              label: const Text('Statistiques'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (latest.isEmpty)
          const _EmptyDashboard()
        else
          ...latest.take(3).map((item) => ActivityCard(activity: item)),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.activities,
    required this.importedItems,
    required this.reportFiles,
    required this.proofCount,
    required this.total,
  });

  final List<Activity> activities;
  final List<ImportedReportItem> importedItems;
  final List<ImportedReportFile> reportFiles;
  final int proofCount;
  final Duration total;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Rapports preuves',
                value: '${reportFiles.length}',
                icon: Icons.picture_as_pdf_outlined,
                color: Colors.red,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Sources importées',
                value: '${importedItems.length}',
                icon: Icons.source_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Compléments du mois',
                value: '${activities.length}',
                icon: Icons.task_alt,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Temps du mois',
                value: _duration(total),
                icon: Icons.schedule,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Preuves RecruitProof',
                value: '$proofCount',
                icon: Icons.attachment,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Candidatures',
                value: '${_applicationCount()}',
                icon: Icons.send_outlined,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Relances',
                value: '${_followUpCount()}',
                icon: Icons.replay,
              ),
            ),
            SizedBox(
              width: width,
              child: StatCard(
                label: 'Entretiens',
                value: '${_interviewCount()}',
                icon: Icons.record_voice_over_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  int _applicationCount() =>
      _count(ActionType.application) +
      importedItems
          .where(
            (item) =>
                item.category.toLowerCase().contains('candidature') ||
                item.status.toLowerCase().contains('envoy') ||
                item.status.toLowerCase().contains('candidature'),
          )
          .length;

  int _followUpCount() =>
      _count(ActionType.followUp) +
      importedItems
          .where(
            (item) =>
                item.category.toLowerCase().contains('relance') ||
                item.status.toLowerCase().contains('relance'),
          )
          .length;

  int _interviewCount() =>
      _count(ActionType.interview) +
      importedItems
          .where(
            (item) =>
                item.category.toLowerCase().contains('entretien') ||
                item.status.toLowerCase().contains('entretien'),
          )
          .length;

  int _count(ActionType type) =>
      activities.where((item) => item.type == type).length;

  String _duration(Duration value) =>
      '${value.inHours}h ${value.inMinutes.remainder(60).toString().padLeft(2, '0')}';
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.period,
    required this.reportCount,
    required this.lastReport,
  });

  final String period;
  final int reportCount;
  final String? lastReport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.folder_copy_outlined, color: scheme.primary, size: 42),
          const SizedBox(height: 12),
          Text(
            'Dossier de preuves',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Période du mois : $period'),
          const SizedBox(height: 10),
          Text(
            reportCount == 0
                ? 'Ajoutez vos rapports preuves pour construire un dossier solide.'
                : '$reportCount rapport(s) preuve(s) prêt(s) à être joint(s).',
          ),
          const SizedBox(height: 12),
          Text(
            lastReport == null
                ? 'Aucun dossier généré pour le moment.'
                : 'Dernier dossier généré : ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(lastReport!))}',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.jobTimeReports,
    required this.jobTrackerReports,
  });

  final int jobTimeReports;
  final int jobTrackerReports;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Méthode du dossier solide',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _StepLine(
              number: '1',
              title: 'Ajouter les rapports preuves',
              detail:
                  'JobTime Proof : $jobTimeReports • JobTracker : $jobTrackerReports',
            ),
            const _StepLine(
              number: '2',
              title: 'Vérifier les compteurs',
              detail:
                  'Candidatures, relances et entretiens peuvent être corrigés à la main dans Rapport.',
            ),
            const _StepLine(
              number: '3',
              title: 'Exporter le ZIP complet',
              detail:
                  'Le PDF sert de sommaire, le ZIP contient les rapports preuves originaux.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsCard extends StatelessWidget {
  const _ReportsCard({required this.reportFiles});

  final List<ImportedReportFile> reportFiles;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapports preuves ajoutés',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (reportFiles.isEmpty)
              const Text(
                'Aucun rapport preuve pour le moment. Ajoutez les PDF de JobTime Proof ou JobTracker dans l’onglet Rapport.',
              )
            else
              ...reportFiles
                  .take(5)
                  .map(
                    (file) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(file.name, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${file.source.label} • ${file.sizeLabel}',
                      ),
                    ),
                  ),
            if (reportFiles.length > 5)
              Text('+ ${reportFiles.length - 5} autre(s) rapport(s) preuve(s)'),
          ],
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            child: Text(number),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(detail, style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: Text('Aucun complément pour le moment.')),
    ),
  );
}
