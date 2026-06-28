import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import 'action_type_chip.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.activity,
    this.onTap,
    this.onDelete,
    super.key,
  });

  final Activity activity;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusBadge(status: activity.status),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionTypeChip(type: activity.type),
                  Chip(
                    avatar: const Icon(Icons.public, size: 17),
                    label: Text(activity.platform.label),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    avatar: const Icon(Icons.schedule, size: 17),
                    label: Text('Temps ${_duration(activity.duration)}'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                DateFormat(
                  'EEEE d MMMM yyyy · HH:mm',
                  'fr',
                ).format(activity.startTime),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (activity.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  activity.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (activity.proofIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${activity.proofIds.length} preuve(s) associée(s)',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    if (hours == 0 && minutes == 0 && seconds > 0) return '${seconds}s';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ActivityStatus.validated => Colors.green,
      ActivityStatus.toCheck => Colors.orange,
      ActivityStatus.draft => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
