import 'package:flutter/foundation.dart';

import '../models/proof_file.dart';
import '../services/file_picker_service.dart';
import '../services/local_database_service.dart';

class ProofProvider extends ChangeNotifier {
  ProofProvider(this._database);
  final LocalDatabaseService _database;
  final FilePickerService _picker = FilePickerService();

  List<ProofFile> _proofs = [];
  List<ProofFile> get proofs => List.unmodifiable(_proofs);

  Future<void> load() async {
    _proofs = _database.getProofs();
    notifyListeners();
  }

  Future<List<ProofFile>> pickAndSave({String? activityId}) async {
    final picked = await _picker.pickProofs(activityId: activityId);
    for (final proof in picked) {
      _proofs.add(proof);
      await _database.saveProof(proof);
    }
    notifyListeners();
    return picked;
  }

  Future<void> delete(String id) async {
    _proofs.removeWhere((proof) => proof.id == id);
    await _database.deleteProof(id);
    notifyListeners();
  }

  List<ProofFile> forActivity(String activityId) =>
      _proofs.where((proof) => proof.activityId == activityId).toList();
}
