import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';
import 'activity_form_screen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final activities = provider.filteredActivities;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle activité'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            'Journal d’activités',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: provider.setQuery,
            controller: TextEditingController(text: provider.query)
              ..selection = TextSelection.collapsed(
                offset: provider.query.length,
              ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher par titre, plateforme ou notes',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DropdownMenu<ActionType?>(
                width: 210,
                label: const Text('Type d’action'),
                initialSelection: provider.typeFilter,
                dropdownMenuEntries: [
                  const DropdownMenuEntry(value: null, label: 'Tous les types'),
                  ...ActionType.values.map(
                    (type) => DropdownMenuEntry(value: type, label: type.label),
                  ),
                ],
                onSelected: provider.setTypeFilter,
              ),
              DropdownMenu<ActivityStatus?>(
                width: 190,
                label: const Text('Statut'),
                initialSelection: provider.statusFilter,
                dropdownMenuEntries: [
                  const DropdownMenuEntry(
                    value: null,
                    label: 'Tous les statuts',
                  ),
                  ...ActivityStatus.values.map(
                    (status) =>
                        DropdownMenuEntry(value: status, label: status.label),
                  ),
                ],
                onSelected: provider.setStatusFilter,
              ),
              SegmentedButton<ActivitySort>(
                segments: const [
                  ButtonSegment(
                    value: ActivitySort.newest,
                    label: Text('Récentes'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: ActivitySort.oldest,
                    label: Text('Anciennes'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {provider.sort},
                onSelectionChanged: (value) => provider.setSort(value.first),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDateRange(context, provider),
                icon: const Icon(Icons.date_range),
                label: Text(
                  provider.dateFilter == null ? 'Période' : 'Période active',
                ),
              ),
              if (provider.typeFilter != null ||
                  provider.statusFilter != null ||
                  provider.dateFilter != null ||
                  provider.query.isNotEmpty)
                TextButton.icon(
                  onPressed: provider.clearFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Effacer'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('${activities.length} activité(s)'),
          const SizedBox(height: 8),
          if (activities.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Aucun résultat.')),
              ),
            )
          else
            ...activities.map(
              (activity) => ActivityCard(
                activity: activity,
                onTap: () => _openForm(context, activity),
                onDelete: () => _confirmDelete(context, activity),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, [Activity? activity]) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityFormScreen(activity: activity),
        ),
      );

  Future<void> _pickDateRange(
    BuildContext context,
    ActivityProvider provider,
  ) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (range != null) {
      provider.setDateFilter(
        DateTimeRangeFilter(
          range.start,
          DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette activité ?'),
        content: Text('« ${activity.title} » sera définitivement supprimée.'),
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
    if (confirmed == true && context.mounted) {
      await context.read<ActivityProvider>().delete(activity);
    }
  }
}
