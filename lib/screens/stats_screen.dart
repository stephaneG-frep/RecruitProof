import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = context.watch<ActivityProvider>().activities;
    final byPlatform = <ActivityPlatform, Duration>{};
    final byType = <ActionType, Duration>{};
    for (final item in activities) {
      byPlatform[item.platform] =
          (byPlatform[item.platform] ?? Duration.zero) + item.duration;
      byType[item.type] = (byType[item.type] ?? Duration.zero) + item.duration;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 250,
                child: StatCard(
                  label: 'Candidatures',
                  value: '${_count(activities, ActionType.application)}',
                  icon: Icons.send_outlined,
                ),
              ),
              SizedBox(
                width: 250,
                child: StatCard(
                  label: 'Relances',
                  value: '${_count(activities, ActionType.followUp)}',
                  icon: Icons.replay,
                ),
              ),
              SizedBox(
                width: 250,
                child: StatCard(
                  label: 'Entretiens',
                  value: '${_count(activities, ActionType.interview)}',
                  icon: Icons.groups_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DurationSection(
            title: 'Temps passé par plateforme',
            values: {
              for (final entry in byPlatform.entries)
                entry.key.label: entry.value,
            },
          ),
          const SizedBox(height: 18),
          _DurationSection(
            title: 'Temps passé par type d’action',
            values: {
              for (final entry in byType.entries) entry.key.label: entry.value,
            },
          ),
          const SizedBox(height: 18),
          _WeeklySection(activities: activities),
        ],
      ),
    );
  }

  int _count(List<Activity> items, ActionType type) =>
      items.where((item) => item.type == type).length;
}

class _DurationSection extends StatelessWidget {
  const _DurationSection({required this.title, required this.values});
  final String title;
  final Map<String, Duration> values;

  @override
  Widget build(BuildContext context) {
    final max = values.values.fold<int>(
      1,
      (value, item) => item.inMinutes > value ? item.inMinutes : value,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            if (values.isEmpty)
              const Text('Pas encore de données.')
            else
              ...values.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(entry.key)),
                          Text(
                            '${entry.value.inHours}h '
                            '${entry.value.inMinutes.remainder(60)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                        value: entry.value.inMinutes / max,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeeklySection extends StatelessWidget {
  const _WeeklySection({required this.activities});
  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weeks = List.generate(6, (index) {
      final start = currentStart.subtract(Duration(days: 7 * (5 - index)));
      final end = start.add(const Duration(days: 7));
      final count = activities
          .where(
            (item) => !item.date.isBefore(start) && item.date.isBefore(end),
          )
          .length;
      return (label: '${start.day}/${start.month}', count: count);
    });
    final max = weeks.fold<int>(
      1,
      (value, item) => item.count > value ? item.count : value,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions par semaine',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: weeks
                    .map(
                      (week) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${week.count}'),
                              const SizedBox(height: 4),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: week.count == 0
                                      ? .02
                                      : week.count / max,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                week.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
