import 'package:flutter/foundation.dart';

import '../models/imported_report_file.dart';
import '../models/imported_report_item.dart';
import '../services/import_service.dart';
import '../services/local_database_service.dart';

class ImportedDataProvider extends ChangeNotifier {
  ImportedDataProvider(this._database);

  final LocalDatabaseService _database;
  final ImportService _importService = ImportService();

  List<ImportedReportItem> _items = [];
  List<ImportedReportFile> _files = [];

  List<ImportedReportItem> get items => List.unmodifiable(_items);
  List<ImportedReportFile> get files => List.unmodifiable(_files);

  Future<void> load() async {
    _items = _database.getImportedItems()
      ..sort((a, b) => b.date.compareTo(a.date));
    _files = _database.getImportedFiles()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    notifyListeners();
  }

  List<ImportedReportItem> forPeriod(DateTime start, DateTime end) =>
      _items
          .where(
            (item) => !item.date.isBefore(start) && !item.date.isAfter(end),
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  int countForSource(ImportedSourceType source) =>
      _items.where((item) => item.source == source).length;

  int fileCountForSource(ImportedSourceType source) =>
      _files.where((file) => file.source == source).length;

  Future<ImportSummary?> importFromFile(ImportedSourceType source) async {
    final parsed = await _importService.pickAndParse(source: source);
    if (parsed == null) return null;
    if (parsed.files.isNotEmpty) {
      await _database.addImportedItems(parsed.items);
      await _database.addImportedFiles(parsed.files);
      await load();
      return ImportSummary(
        source: source,
        imported: parsed.items.length,
        files: parsed.files.length,
        replaced: 0,
      );
    }
    final replacedItems = await _database.replaceImportedItems(
      source: source,
      items: parsed.items,
    );
    final replacedFiles = await _database.replaceImportedFiles(
      source: source,
      files: parsed.files,
    );
    await load();
    return ImportSummary(
      source: source,
      imported: parsed.items.length,
      files: parsed.files.length,
      replaced: replacedItems + replacedFiles,
    );
  }

  Future<void> clearSource(ImportedSourceType source) async {
    await _database.clearImportedSource(source);
    await load();
  }
}
