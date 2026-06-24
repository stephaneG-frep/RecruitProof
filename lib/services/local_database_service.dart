import 'package:hive_flutter/hive_flutter.dart';

import '../models/activity.dart';
import '../models/proof_file.dart';

class LocalDatabaseService {
  static const _activitiesBoxName = 'activities';
  static const _proofsBoxName = 'proofs';
  static const _settingsBoxName = 'settings';

  late Box<dynamic> _activities;
  late Box<dynamic> _proofs;
  late Box<dynamic> _settings;

  Future<void> initialize() async {
    _activities = await Hive.openBox<dynamic>(_activitiesBoxName);
    _proofs = await Hive.openBox<dynamic>(_proofsBoxName);
    _settings = await Hive.openBox<dynamic>(_settingsBoxName);
    await _seedDemoData();
  }

  List<Activity> getActivities() => _activities.values
      .map(
        (value) => Activity.fromMap(Map<dynamic, dynamic>.from(value as Map)),
      )
      .toList();

  Future<void> saveActivity(Activity activity) =>
      _activities.put(activity.id, activity.toMap());

  Future<void> deleteActivity(String id) => _activities.delete(id);

  List<ProofFile> getProofs() => _proofs.values
      .map(
        (value) => ProofFile.fromMap(Map<dynamic, dynamic>.from(value as Map)),
      )
      .toList();

  Future<void> saveProof(ProofFile proof) =>
      _proofs.put(proof.id, proof.toMap());

  Future<void> deleteProof(String id) => _proofs.delete(id);

  String? get lastReportDate => _settings.get('lastReportDate') as String?;

  Future<void> setLastReportDate(DateTime date) =>
      _settings.put('lastReportDate', date.toIso8601String());

  Future<void> _seedDemoData() async {
    if (_activities.isNotEmpty || _settings.get('demoSeeded') == true) return;
    final now = DateTime.now();
    final demos = [
      _demo(
        'demo-1',
        'Candidature – Chargé de communication',
        ActionType.application,
        ActivityPlatform.franceTravail,
        now,
        50,
      ),
      _demo(
        'demo-2',
        'Recherche d’offres ciblées',
        ActionType.offerSearch,
        ActivityPlatform.indeed,
        now.subtract(const Duration(days: 1)),
        75,
      ),
      _demo(
        'demo-3',
        'Relance après candidature',
        ActionType.followUp,
        ActivityPlatform.email,
        now.subtract(const Duration(days: 3)),
        20,
      ),
      _demo(
        'demo-4',
        'Mise à jour du CV',
        ActionType.cvUpdate,
        ActivityPlatform.other,
        now.subtract(const Duration(days: 5)),
        90,
      ),
    ];
    for (final activity in demos) {
      await saveActivity(activity);
    }
    await _settings.put('demoSeeded', true);
  }

  Activity _demo(
    String id,
    String title,
    ActionType type,
    ActivityPlatform platform,
    DateTime date,
    int minutes,
  ) {
    final start = DateTime(date.year, date.month, date.day, 9);
    return Activity(
      id: id,
      title: title,
      type: type,
      date: date,
      startTime: start,
      endTime: start.add(Duration(minutes: minutes)),
      platform: platform,
      notes: 'Activité de démonstration, modifiable ou supprimable.',
      status: ActivityStatus.validated,
    );
  }
}
