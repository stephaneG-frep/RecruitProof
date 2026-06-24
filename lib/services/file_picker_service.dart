import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/proof_file.dart';

class FilePickerService {
  Future<List<ProofFile>> pickProofs({String? activityId}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: [
        'png',
        'jpg',
        'jpeg',
        'webp',
        'pdf',
        'doc',
        'docx',
        'odt',
        'txt',
      ],
    );
    if (result == null) return [];

    return result.files
        .where((file) => file.bytes != null)
        .map(
          (file) => ProofFile(
            id: const Uuid().v4(),
            name: file.name,
            extension: file.extension?.toLowerCase() ?? '',
            bytes: file.bytes!,
            addedAt: DateTime.now(),
            activityId: activityId,
          ),
        )
        .toList();
  }

  Future<String?> saveBytes({
    required String fileName,
    required Uint8List bytes,
  }) {
    return FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
  }
}
