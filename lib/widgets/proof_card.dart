import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/proof_file.dart';

class ProofCard extends StatelessWidget {
  const ProofCard({required this.proof, required this.onDelete, super.key});
  final ProofFile proof;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isImage = {'png', 'jpg', 'jpeg', 'webp'}.contains(proof.extension);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 52,
            height: 52,
            child: isImage
                ? Image.memory(proof.bytes, fit: BoxFit.cover)
                : ColoredBox(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      proof.extension == 'pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.description_outlined,
                    ),
                  ),
          ),
        ),
        title: Text(proof.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${proof.sizeLabel} · ${DateFormat('dd/MM/yyyy').format(proof.addedAt)}',
        ),
        trailing: IconButton(
          tooltip: 'Supprimer',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
