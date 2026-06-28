import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/imported_report_file.dart';
import '../models/imported_report_item.dart';

class ImportResult {
  const ImportResult({required this.items, required this.files});

  final List<ImportedReportItem> items;
  final List<ImportedReportFile> files;
}

class ImportService {
  Future<ImportResult?> pickAndParse({
    required ImportedSourceType source,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'csv', 'pdf'],
      withData: true,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return null;
    if (result.files.length > 1 ||
        result.files.every((file) => file.extension?.toLowerCase() == 'pdf')) {
      return _buildPdfImportResult(source, result.files);
    }
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception(
        'Le fichier sélectionné est illisible sur cette plateforme.',
      );
    }
    final extension = file.extension?.toLowerCase();
    if (extension == 'pdf') {
      return _buildPdfImportResult(source, [file]);
    }
    final content = utf8.decode(bytes);
    if (extension == 'csv') {
      return ImportResult(items: _parseJobTrackerCsv(content), files: const []);
    }
    final items = switch (source) {
      ImportedSourceType.jobTimeProof => _parseJobTimeProofJson(content),
      ImportedSourceType.jobTracker => _parseJobTrackerJson(content),
      ImportedSourceType.manual => const <ImportedReportItem>[],
    };
    return ImportResult(items: items, files: const []);
  }

  ImportResult _buildPdfImportResult(
    ImportedSourceType source,
    List<PlatformFile> selectedFiles,
  ) {
    final files = <ImportedReportFile>[];
    final items = <ImportedReportItem>[];
    for (final file in selectedFiles) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Le fichier ${file.name} est illisible.');
      }
      if (file.extension?.toLowerCase() != 'pdf') {
        throw Exception('Sélection multiple : seuls les PDF sont acceptés.');
      }
      final importedFile = ImportedReportFile(
        id: const Uuid().v4(),
        source: source,
        name: file.name,
        extension: 'pdf',
        bytes: bytes,
        addedAt: DateTime.now(),
      );
      files.add(importedFile);
      items.add(
        ImportedReportItem(
          id: '${source.name}-pdf-${importedFile.id}',
          source: source,
          title: 'Rapport preuve : ${file.name}',
          date: DateTime.now(),
          category: 'Rapport preuve',
          platform: source.label,
          status: 'Preuve jointe',
          notes:
              'Rapport PDF ajouté manuellement comme preuve source du dossier.',
          proofCount: 1,
        ),
      );
    }
    return ImportResult(items: items, files: files);
  }

  List<ImportedReportItem> _parseJobTimeProofJson(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw Exception('Export JobTime Proof invalide.');
    }
    final sessions = decoded['sessions'];
    if (sessions is! List) {
      throw Exception('Aucune liste "sessions" trouvée dans le JSON.');
    }
    return sessions.map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final start = _date(map['startTime']) ?? DateTime.now();
      final durationSeconds = _int(map['durationSeconds']);
      final proofs = map['proofs'] is List ? map['proofs'] as List : const [];
      final notes = map['notes']?.toString() ?? '';
      final urlProofs = proofs
          .whereType<Map>()
          .map((proof) => proof['url']?.toString() ?? '')
          .where((url) => url.trim().isNotEmpty)
          .toList();
      return ImportedReportItem(
        id: 'jobtime-${map['id'] ?? const Uuid().v4()}',
        source: ImportedSourceType.jobTimeProof,
        title: map['actionType']?.toString().trim().isNotEmpty == true
            ? map['actionType'].toString()
            : 'Session JobTime Proof',
        date: start,
        category: map['actionType']?.toString() ?? 'Session',
        platform: map['platform']?.toString() ?? '',
        status: _bool(map['didApply']) ? 'Candidature indiquée' : '',
        reference: urlProofs.isNotEmpty ? urlProofs.first : '',
        notes: notes,
        durationMinutes: (durationSeconds / 60).round(),
        proofCount: proofs.length,
      );
    }).toList();
  }

  List<ImportedReportItem> _parseJobTrackerJson(String content) {
    final decoded = jsonDecode(content);
    final records = decoded is List
        ? decoded
        : decoded is Map && decoded['applications'] is List
        ? decoded['applications'] as List
        : decoded is Map && decoded['items'] is List
        ? decoded['items'] as List
        : null;
    if (records == null) {
      throw Exception(
        'JSON JobTracker invalide. Attendu: liste ou clé "applications".',
      );
    }
    return records
        .whereType<Map>()
        .map((raw) => _jobTrackerMapToItem(Map<String, dynamic>.from(raw)))
        .toList();
  }

  List<ImportedReportItem> _parseJobTrackerCsv(String content) {
    final rows = _parseCsv(content);
    if (rows.length < 2) return [];
    final headers = rows.first.map((cell) => cell.trim()).toList();
    return rows
        .skip(1)
        .where((row) => row.any((cell) => cell.trim().isNotEmpty))
        .map((row) {
          final map = <String, String>{};
          for (var i = 0; i < headers.length && i < row.length; i++) {
            map[headers[i]] = row[i];
          }
          return _jobTrackerMapToItem(map);
        })
        .toList();
  }

  ImportedReportItem _jobTrackerMapToItem(Map<String, dynamic> map) {
    final company =
        map['company']?.toString() ?? map['Entreprise']?.toString() ?? '';
    final title = map['title']?.toString() ?? map['Poste']?.toString() ?? '';
    final status = _statusLabel(map['status']);
    final appliedAt =
        _date(map['appliedAt']) ?? _date(map['Date']) ?? DateTime.now();
    final interviews = map['interviews'] is List
        ? map['interviews'] as List
        : const [];
    return ImportedReportItem(
      id: 'jobtracker-${map['id'] ?? const Uuid().v4()}',
      source: ImportedSourceType.jobTracker,
      title: title.isEmpty ? 'Candidature JobTracker' : title,
      date: appliedAt,
      category: 'Candidature',
      platform: 'JobTracker',
      company: company,
      status: status,
      reference: map['url']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
      durationMinutes: 0,
      proofCount: interviews.length,
    );
  }

  List<List<String>> _parseCsv(String content) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      final next = i + 1 < content.length ? content[i + 1] : '';
      if (char == '"') {
        if (inQuotes && next == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(current.toString());
        current.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && next == '\n') i++;
        currentRow.add(current.toString());
        current.clear();
        rows.add(List<String>.from(currentRow));
        currentRow.clear();
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(current.toString());
      rows.add(currentRow);
    }
    return rows;
  }

  DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _bool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }

  String _statusLabel(dynamic raw) {
    if (raw == null) return '';
    if (raw is int) {
      const labels = [
        'À préparer',
        'Envoyée',
        'Relance',
        'Entretien',
        'Refusée',
        'Acceptée',
      ];
      return raw >= 0 && raw < labels.length ? labels[raw] : raw.toString();
    }
    final value = raw.toString();
    return switch (value) {
      'ApplicationStatus.prepare' || 'prepare' => 'À préparer',
      'ApplicationStatus.sent' || 'sent' => 'Envoyée',
      'ApplicationStatus.followUp' || 'followUp' => 'Relance',
      'ApplicationStatus.interview' || 'interview' => 'Entretien',
      'ApplicationStatus.rejected' || 'rejected' => 'Refusée',
      'ApplicationStatus.accepted' || 'accepted' => 'Acceptée',
      _ => value,
    };
  }
}
