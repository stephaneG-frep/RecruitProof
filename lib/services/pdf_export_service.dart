import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity.dart';
import '../models/proof_file.dart';

class PdfExportService {
  Future<Uint8List> generate({
    required String personName,
    required DateTime start,
    required DateTime end,
    required List<Activity> activities,
    required List<ProofFile> proofs,
  }) async {
    final document = pw.Document(
      title: 'Rapport RecruitProof',
      author: personName,
    );
    final date = DateFormat('dd/MM/yyyy');
    final total = activities.fold<Duration>(
      Duration.zero,
      (sum, item) => sum + item.duration,
    );
    final platforms = activities
        .map((item) => item.platform.label)
        .toSet()
        .join(', ');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'RecruitProof',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text('Rapport de recherche d’emploi'),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (_) => [
          pw.SizedBox(height: 20),
          pw.Text(
            personName.isEmpty ? 'Nom non renseigné' : personName,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Période : ${date.format(start)} – ${date.format(end)}'),
          pw.Text('Généré le ${date.format(DateTime.now())}'),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _metric('Actions', '${activities.length}'),
                _metric('Durée totale', _formatDuration(total)),
                _metric('Preuves', '${proofs.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Plateformes utilisées : ${platforms.isEmpty ? '—' : platforms}',
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Activités',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headers: const ['Date', 'Action', 'Plateforme', 'Durée', 'Statut'],
            data: activities
                .map(
                  (item) => [
                    date.format(item.date),
                    '${item.title}\n${item.notes}',
                    item.platform.label,
                    _formatDuration(item.duration),
                    item.status.label,
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Preuves jointes',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (proofs.isEmpty)
            pw.Text('Aucune preuve jointe pour cette période.')
          else
            ...proofs.map(
              (proof) => pw.Bullet(text: '${proof.name} (${proof.sizeLabel})'),
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Ce rapport regroupe uniquement les informations et fichiers ajoutés volontairement par l’utilisateur.',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _metric(String label, String value) => pw.Column(
    children: [
      pw.Text(
        value,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
    ],
  );

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
  }
}
