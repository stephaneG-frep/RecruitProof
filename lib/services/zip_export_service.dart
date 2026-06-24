import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/proof_file.dart';

class ZipExportService {
  Uint8List generate({
    required Uint8List report,
    required List<ProofFile> proofs,
  }) {
    final archive = Archive()
      ..addFile(ArchiveFile('rapport.pdf', report.length, report));
    for (final proof in proofs) {
      archive.addFile(
        ArchiveFile('preuves/${proof.name}', proof.bytes.length, proof.bytes),
      );
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
