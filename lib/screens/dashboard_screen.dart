import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../providers/activity_provider.dart';
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
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final thisWeek = activities
        .where((item) => !item.date.isBefore(weekStart))
        .length;
    final total = activities.fold<Duration>(
      Duration.zero,
      (sum, item) => sum + item.duration,
    );
    final latest = [...activities]..sort((a, b) => b.date.compareTo(a.date));
    final lastReport = activityProvider.lastReportDate;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de bord',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Votre recherche d’emploi, documentée clairement.',
                  ),
                ],
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
        const SizedBox(height: 20),
        LayoutBuilder(
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
                    label: 'Actions totales',
                    value: '${activities.length}',
                    icon: Icons.task_alt,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Actions cette semaine',
                    value: '$thisWeek',
                    icon: Icons.date_range,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Temps déclaré',
                    value: _duration(total),
                    icon: Icons.schedule,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Preuves ajoutées',
                    value: '${proofs.length}',
                    icon: Icons.attachment,
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Candidatures envoyées',
                    value: '${_count(activities, ActionType.application)}',
                    icon: Icons.send_outlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: StatCard(
                    label: 'Relances',
                    value: '${_count(activities, ActionType.followUp)}',
                    icon: Icons.replay,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Dernier rapport généré'),
            subtitle: Text(
              lastReport == null
                  ? 'Aucun rapport généré'
                  : DateFormat(
                      'dd/MM/yyyy à HH:mm',
                    ).format(DateTime.parse(lastReport)),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Activités récentes',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (latest.isEmpty)
          const _EmptyDashboard()
        else
          ...latest.take(3).map((item) => ActivityCard(activity: item)),
      ],
    );
  }

  int _count(List<Activity> items, ActionType type) =>
      items.where((item) => item.type == type).length;

  String _duration(Duration value) =>
      '${value.inHours}h ${value.inMinutes.remainder(60).toString().padLeft(2, '0')}';
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: Text('Aucune activité pour le moment.')),
    ),
  );
}
