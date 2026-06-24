import 'package:flutter/material.dart';

import '../models/activity.dart';

class ActionTypeChip extends StatelessWidget {
  const ActionTypeChip({required this.type, super.key});
  final ActionType type;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_icon(type), size: 17),
      label: Text(type.label),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _icon(ActionType type) => switch (type) {
    ActionType.application => Icons.send_outlined,
    ActionType.offerSearch => Icons.search,
    ActionType.followUp => Icons.replay_outlined,
    ActionType.interview => Icons.groups_outlined,
    ActionType.platformRegistration => Icons.person_add_alt,
    ActionType.training => Icons.school_outlined,
    ActionType.workshop => Icons.handyman_outlined,
    ActionType.cvUpdate => Icons.article_outlined,
    ActionType.other => Icons.more_horiz,
  };
}
