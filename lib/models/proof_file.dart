import 'dart:typed_data';

class ProofFile {
  const ProofFile({
    required this.id,
    required this.name,
    required this.extension,
    required this.bytes,
    required this.addedAt,
    this.activityId,
  });

  final String id;
  final String name;
  final String extension;
  final Uint8List bytes;
  final DateTime addedAt;
  final String? activityId;

  String get sizeLabel {
    final kb = bytes.length / 1024;
    return kb < 1024
        ? '${kb.toStringAsFixed(0)} Ko'
        : '${(kb / 1024).toStringAsFixed(1)} Mo';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'extension': extension,
    'bytes': bytes,
    'addedAt': addedAt.toIso8601String(),
    'activityId': activityId,
  };

  factory ProofFile.fromMap(Map<dynamic, dynamic> map) => ProofFile(
    id: map['id'] as String,
    name: map['name'] as String,
    extension: map['extension'] as String? ?? '',
    bytes: Uint8List.fromList(List<int>.from(map['bytes'] as List)),
    addedAt: DateTime.parse(map['addedAt'] as String),
    activityId: map['activityId'] as String?,
  );
}
