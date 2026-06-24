import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/proof_file.dart';
import '../providers/activity_provider.dart';
import '../providers/proof_provider.dart';
import '../widgets/proof_card.dart';

class ProofScreen extends StatelessWidget {
  const ProofScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final proofs = context.watch<ProofProvider>().proofs;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'proof_add_file',
        onPressed: () => context.read<ProofProvider>().pickAndSave(),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Ajouter une preuve'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text(
            'Preuves',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Captures, photos, PDF et documents ajoutés uniquement par vous.',
          ),
          const SizedBox(height: 20),
          if (proofs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(36),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 48),
                    SizedBox(height: 12),
                    Text('Aucune preuve ajoutée.'),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth >= 850
                    ? 400.0
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: proofs
                      .map(
                        (proof) => SizedBox(
                          width: cardWidth,
                          child: ProofCard(
                            proof: proof,
                            onDelete: () => _confirmDelete(context, proof),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ProofFile proof) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette preuve ?'),
        content: Text(
          'Le fichier « ${proof.name} » sera supprimé du stockage local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ProofProvider>().delete(proof.id);
      if (context.mounted) {
        await context.read<ActivityProvider>().detachProof(proof.id);
      }
    }
  }
}
