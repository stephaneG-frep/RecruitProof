enum ImportedSourceType {
  jobTimeProof('JobTime Proof'),
  jobTracker('JobTracker'),
  manual('RecruitProof');

  const ImportedSourceType(this.label);
  final String label;
}

class ImportedReportItem {
  const ImportedReportItem({
    required this.id,
    required this.source,
    required this.title,
    required this.date,
    required this.category,
    this.platform = '',
    this.company = '',
    this.status = '',
    this.reference = '',
    this.notes = '',
    this.durationMinutes = 0,
    this.proofCount = 0,
  });

  final String id;
  final ImportedSourceType source;
  final String title;
  final DateTime date;
  final String category;
  final String platform;
  final String company;
  final String status;
  final String reference;
  final String notes;
  final int durationMinutes;
  final int proofCount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'source': source.name,
    'title': title,
    'date': date.toIso8601String(),
    'category': category,
    'platform': platform,
    'company': company,
    'status': status,
    'reference': reference,
    'notes': notes,
    'durationMinutes': durationMinutes,
    'proofCount': proofCount,
  };

  factory ImportedReportItem.fromMap(Map<dynamic, dynamic> map) =>
      ImportedReportItem(
        id: map['id'] as String,
        source: ImportedSourceType.values.byName(map['source'] as String),
        title: map['title'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        category: map['category'] as String? ?? '',
        platform: map['platform'] as String? ?? '',
        company: map['company'] as String? ?? '',
        status: map['status'] as String? ?? '',
        reference: map['reference'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        durationMinutes: map['durationMinutes'] as int? ?? 0,
        proofCount: map['proofCount'] as int? ?? 0,
      );
}

class ImportSummary {
  const ImportSummary({
    required this.source,
    required this.imported,
    required this.files,
    required this.replaced,
  });

  final ImportedSourceType source;
  final int imported;
  final int files;
  final int replaced;
}
