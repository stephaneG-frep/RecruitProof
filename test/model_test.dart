import 'package:flutter_test/flutter_test.dart';
import 'package:recruit_proof/models/activity.dart';

void main() {
  test('calcule correctement la durée d’une activité', () {
    final start = DateTime(2026, 6, 24, 9);
    final activity = Activity(
      id: 'test',
      title: 'Test',
      type: ActionType.offerSearch,
      date: start,
      startTime: start,
      endTime: start.add(const Duration(hours: 1, minutes: 30)),
      platform: ActivityPlatform.franceTravail,
      status: ActivityStatus.validated,
    );

    expect(activity.duration, const Duration(hours: 1, minutes: 30));
  });

  test('sérialise et restaure une activité', () {
    final start = DateTime(2026, 6, 24, 9);
    final original = Activity(
      id: 'test',
      title: 'Candidature',
      type: ActionType.application,
      date: start,
      startTime: start,
      endTime: start.add(const Duration(minutes: 25)),
      platform: ActivityPlatform.email,
      reference: 'REF-42',
      notes: 'Message envoyé',
      status: ActivityStatus.toCheck,
      proofIds: const ['proof-1'],
    );

    final restored = Activity.fromMap(original.toMap());
    expect(restored.title, original.title);
    expect(restored.type, original.type);
    expect(restored.proofIds, original.proofIds);
  });
}
