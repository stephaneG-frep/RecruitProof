enum ActionType {
  application('Candidature envoyée'),
  offerSearch('Recherche d’offre'),
  followUp('Relance recruteur'),
  interview('Entretien'),
  platformRegistration('Inscription plateforme'),
  training('Formation suivie'),
  workshop('Atelier emploi'),
  cvUpdate('Mise à jour CV'),
  other('Autre');

  const ActionType(this.label);
  final String label;
}

enum ActivityPlatform {
  franceTravail('France Travail'),
  indeed('Indeed'),
  linkedIn('LinkedIn'),
  helloWork('Hellowork'),
  apec('Apec'),
  email('Email'),
  other('Autre');

  const ActivityPlatform(this.label);
  final String label;
}

enum ActivityStatus {
  draft('Brouillon'),
  validated('Validé'),
  toCheck('À vérifier');

  const ActivityStatus(this.label);
  final String label;
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.platform,
    required this.status,
    this.reference = '',
    this.notes = '',
    this.proofIds = const [],
  });

  final String id;
  final String title;
  final ActionType type;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final ActivityPlatform platform;
  final String reference;
  final String notes;
  final ActivityStatus status;
  final List<String> proofIds;

  Duration get duration => endTime.difference(startTime);

  Activity copyWith({
    String? title,
    ActionType? type,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    ActivityPlatform? platform,
    String? reference,
    String? notes,
    ActivityStatus? status,
    List<String>? proofIds,
  }) {
    return Activity(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      platform: platform ?? this.platform,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      proofIds: proofIds ?? this.proofIds,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type.name,
    'date': date.toIso8601String(),
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'platform': platform.name,
    'reference': reference,
    'notes': notes,
    'status': status.name,
    'proofIds': proofIds,
  };

  factory Activity.fromMap(Map<dynamic, dynamic> map) => Activity(
    id: map['id'] as String,
    title: map['title'] as String,
    type: ActionType.values.byName(map['type'] as String),
    date: DateTime.parse(map['date'] as String),
    startTime: DateTime.parse(map['startTime'] as String),
    endTime: DateTime.parse(map['endTime'] as String),
    platform: ActivityPlatform.values.byName(map['platform'] as String),
    reference: map['reference'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    status: ActivityStatus.values.byName(map['status'] as String),
    proofIds: List<String>.from(map['proofIds'] as List? ?? const []),
  );
}
