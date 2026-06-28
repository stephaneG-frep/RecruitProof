import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/activity.dart';
import '../models/imported_report_file.dart';
import '../models/imported_report_item.dart';
import '../models/proof_file.dart';

class PdfExportService {
  Future<Uint8List> generate({
    required String personName,
    required DateTime start,
    required DateTime end,
    required List<Activity> activities,
    required List<ImportedReportItem> importedItems,
    required List<ImportedReportFile> importedFiles,
    required List<ProofFile> proofs,
    String contextLabel = '',
    int? manualApplications,
    int? manualFollowUps,
    int? manualInterviews,
  }) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );
    final pdfTheme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      italic: regularFont,
      boldItalic: boldFont,
    );
    final document = pw.Document(
      title: 'Rapport RecruitProof',
      author: personName,
    );
    final date = DateFormat('dd/MM/yyyy');
    final total =
        activities.fold<Duration>(
          Duration.zero,
          (sum, item) => sum + item.duration,
        ) +
        Duration(
          minutes: importedItems.fold<int>(
            0,
            (sum, item) => sum + item.durationMinutes,
          ),
        );
    final platforms = activities
        .map((item) => item.platform.label)
        .followedBy(
          importedItems
              .map((item) => item.platform)
              .where((platform) => platform.trim().isNotEmpty),
        )
        .toSet()
        .join(', ');
    final calculatedApplicationCount =
        activities.where((item) => item.type == ActionType.application).length +
        importedItems
            .where(
              (item) =>
                  item.category.toLowerCase().contains('candidature') ||
                  item.status.toLowerCase().contains('envoy') ||
                  item.status.toLowerCase().contains('candidature'),
            )
            .length;
    final calculatedFollowUpCount =
        activities.where((item) => item.type == ActionType.followUp).length +
        importedItems
            .where(
              (item) =>
                  item.status.toLowerCase().contains('relance') ||
                  item.category.toLowerCase().contains('relance'),
            )
            .length;
    final calculatedInterviewCount =
        activities.where((item) => item.type == ActionType.interview).length +
        importedItems
            .where(
              (item) =>
                  item.status.toLowerCase().contains('entretien') ||
                  item.category.toLowerCase().contains('entretien'),
            )
            .length;
    final applicationCount = manualApplications ?? calculatedApplicationCount;
    final followUpCount = manualFollowUps ?? calculatedFollowUpCount;
    final interviewCount = manualInterviews ?? calculatedInterviewCount;

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pdfTheme,
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
          if (contextLabel.isNotEmpty) pw.Text('Contexte : $contextLabel'),
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
                _metric('Actions RecruitProof', '${activities.length}'),
                _metric('Lignes sources', '${importedItems.length}'),
                _metric('Durée totale', _formatDuration(total)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue100),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _metric('Candidatures', '$applicationCount'),
                _metric('Relances', '$followUpCount'),
                _metric('Entretiens', '$interviewCount'),
                _metric('Preuves', '${proofs.length}'),
                _metric('Rapports preuves', '${importedFiles.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Plateformes utilisées : ${platforms.isEmpty ? '—' : platforms}',
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Activités RecruitProof'),
          pw.SizedBox(height: 8),
          if (activities.isEmpty)
            pw.Text('Aucune activité RecruitProof sur cette période.')
          else
            ...activities.map((item) => _activityBlock(item, date)),
          if (importedItems.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Données consolidées importées'),
            pw.SizedBox(height: 8),
            ...importedItems.map((item) => _importedBlock(item, date)),
          ],
          if (importedFiles.isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _sectionTitle('Rapports preuves joints'),
            pw.SizedBox(height: 8),
            ...importedFiles.map(
              (file) => pw.Bullet(
                text: '${file.source.label} — ${file.name} (${file.sizeLabel})',
              ),
            ),
          ],
          pw.SizedBox(height: 18),
          _sectionTitle('Autres preuves RecruitProof jointes'),
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

  pw.Widget _sectionTitle(String title) => pw.Text(
    title,
    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
  );

  pw.Widget _activityBlock(Activity item, DateFormat date) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          item.title,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _smallInfo('Date', date.format(item.date)),
            _smallInfo('Type', item.type.label),
            _smallInfo('Plateforme', item.platform.label),
            _smallInfo('Durée', _formatDuration(item.duration)),
            _smallInfo('Statut', item.status.label),
          ],
        ),
        if (item.reference.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Référence : ${item.reference}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
        if (item.notes.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(item.notes, style: const pw.TextStyle(fontSize: 9)),
        ],
      ],
    ),
  );

  pw.Widget _importedBlock(ImportedReportItem item, DateFormat date) {
    final organization = [
      item.platform,
      item.company,
    ].where((part) => part.trim().isNotEmpty).join(' / ');
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.title,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _smallInfo('Date', date.format(item.date)),
              _smallInfo('Source', item.source.label),
              if (organization.isNotEmpty)
                _smallInfo('Entreprise / plateforme', organization),
              if (item.durationMinutes > 0)
                _smallInfo(
                  'Durée',
                  _formatDuration(Duration(minutes: item.durationMinutes)),
                ),
              if (item.status.trim().isNotEmpty)
                _smallInfo('Statut', item.status),
            ],
          ),
          if (item.reference.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Référence : ${item.reference}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          if (item.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(item.notes, style: const pw.TextStyle(fontSize: 9)),
          ],
        ],
      ),
    );
  }

  pw.Widget _smallInfo(String label, String value) => pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$label : ',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 9)),
      ],
    ),
  );

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
  }
}
