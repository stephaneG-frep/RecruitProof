import 'dart:typed_data';

import 'imported_report_item.dart';

class ImportedReportFile {
  const ImportedReportFile({
    required this.id,
    required this.source,
    required this.name,
    required this.extension,
    required this.bytes,
    required this.addedAt,
  });

  final String id;
  final ImportedSourceType source;
  final String name;
  final String extension;
  final Uint8List bytes;
  final DateTime addedAt;

  String get sizeLabel {
    final kb = bytes.length / 1024;
    return kb < 1024
        ? '${kb.toStringAsFixed(0)} Ko'
        : '${(kb / 1024).toStringAsFixed(1)} Mo';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'source': source.name,
    'name': name,
    'extension': extension,
    'bytes': bytes,
    'addedAt': addedAt.toIso8601String(),
  };

  factory ImportedReportFile.fromMap(Map<dynamic, dynamic> map) =>
      ImportedReportFile(
        id: map['id'] as String,
        source: ImportedSourceType.values.byName(map['source'] as String),
        name: map['name'] as String,
        extension: map['extension'] as String? ?? '',
        bytes: Uint8List.fromList(List<int>.from(map['bytes'] as List)),
        addedAt: DateTime.parse(map['addedAt'] as String),
      );
}
