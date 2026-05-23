import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../managers/session_manager.dart';

class ExportService {

  // ── EXPORT PDF ──
  static Future<void> exporterPDF({
    required BuildContext context,
    required String titre,
    required Map cycle,
    required List donnees,
    required List alertes,
  }) async {
    final pdf = pw.Document();

    final totalMorts = donnees.fold<int>(0, (s, d) =>
    s + ((d['mortalite'] ?? 0) as num).toInt());
    final avgTemp = donnees.isEmpty ? 0.0 : donnees.fold<double>(0, (s, d) =>
    s + ((d['temperature'] ?? 0) as num).toDouble()) / donnees.length;
    final avgHum = donnees.isEmpty ? 0.0 : donnees.fold<double>(0, (s, d) =>
    s + ((d['humidite'] ?? 0) as num).toDouble()) / donnees.length;
    final totalProd = donnees.fold<int>(0, (s, d) =>
    s + ((d['production'] ?? 0) as num).toInt());
    final sujets = ((cycle['nombre_sujets'] ?? 0) as num).toInt();
    final tauxMort = sujets > 0 ? (totalMorts / sujets * 100) : 0.0;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context ctx) => [
        // En-tête
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
              color: PdfColors.blueGrey900,
              borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('🐔 Kewere Aissa Smart',
                      style: pw.TextStyle(color: PdfColors.white,
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rapport Avicole Professionnel',
                      style: pw.TextStyle(color: PdfColors.white70, fontSize: 11)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(titre,
                      style: pw.TextStyle(color: PdfColors.white,
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: pw.TextStyle(color: PdfColors.white70, fontSize: 10)),
                ]),
              ]),
        ),
        pw.SizedBox(height: 20),

        // Informations cycle
        pw.Text('INFORMATIONS DU CYCLE',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800)),
        pw.Divider(color: PdfColors.blueGrey200),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _pdfInfoCard('Éleveur', SessionManager.nom),
          pw.SizedBox(width: 12),
          _pdfInfoCard('Cycle', cycle['nom'] ?? 'N/A'),
          pw.SizedBox(width: 12),
          _pdfInfoCard('Sujets', '$sujets poulets'),
          pw.SizedBox(width: 12),
          _pdfInfoCard('Statut', cycle['statut'] ?? 'N/A'),
        ]),
        pw.SizedBox(height: 20),

        // KPIs
        pw.Text('INDICATEURS CLÉS',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800)),
        pw.Divider(color: PdfColors.blueGrey200),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          _pdfKpi('Mortalité Totale', '$totalMorts', '${tauxMort.toStringAsFixed(1)}%',
              tauxMort > 5 ? PdfColors.red : PdfColors.green),
          pw.SizedBox(width: 12),
          _pdfKpi('Temp. Moyenne', '${avgTemp.toStringAsFixed(1)}°C',
              avgTemp > 32 ? 'Élevée' : 'Normale',
              avgTemp > 32 ? PdfColors.orange : PdfColors.green),
          pw.SizedBox(width: 12),
          _pdfKpi('Humidité Moy.', '${avgHum.toStringAsFixed(1)}%',
              avgHum > 70 ? 'Élevée' : 'Normale',
              avgHum > 70 ? PdfColors.orange : PdfColors.green),
          pw.SizedBox(width: 12),
          _pdfKpi('Production', '$totalProd', 'unités', PdfColors.blue),
        ]),
        pw.SizedBox(height: 20),

        // Tableau données
        if (donnees.isNotEmpty) ...[
          pw.Text('DONNÉES JOURNALIÈRES',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800)),
          pw.Divider(color: PdfColors.blueGrey200),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.blueGrey100),
            children: [
              // En-tête tableau
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                children: ['Date', 'Température', 'Humidité', 'Mortalité', 'Production']
                    .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9))))
                    .toList(),
              ),
              // Données
              ...donnees.take(20).map((d) => pw.TableRow(children: [
                _pdfCell(d['date_releve'] ?? '-'),
                _pdfCell('${((d['temperature'] ?? 0) as num).toStringAsFixed(1)}°C'),
                _pdfCell('${((d['humidite'] ?? 0) as num).toStringAsFixed(1)}%'),
                _pdfCell('${d['mortalite'] ?? 0}'),
                _pdfCell('${d['production'] ?? 0}'),
              ])),
            ],
          ),
        ],
        pw.SizedBox(height: 20),

        // Alertes
        if (alertes.isNotEmpty) ...[
          pw.Text('ALERTES',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red)),
          pw.Divider(color: PdfColors.red200),
          pw.SizedBox(height: 8),
          ...alertes.take(5).map((a) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Text(a['titre'] ?? a['message'] ?? '',
                style: pw.TextStyle(color: PdfColors.red900, fontSize: 10)),
          )),
        ],

        pw.SizedBox(height: 20),
        // Pied de page
        pw.Divider(),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('Kewere Aissa Smart — Rapport confidentiel',
              style: pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
          pw.Text('${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
        ]),
      ],
    ));

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // ── EXPORT EXCEL ──
  static Future<void> exporterExcel({
    required BuildContext context,
    required Map cycle,
    required List donnees,
  }) async {
    final excel = Excel.createExcel();

    // ── Feuille Données ──
    final Sheet donneesSheet = excel['Données Journalières'];
    excel.setDefaultSheet('Données Journalières');

    // En-têtes
    final headers = ['Date', 'Température (°C)', 'Humidité (%)',
      'Mortalité', 'Production', 'Cycle'];
    for (int i = 0; i < headers.length; i++) {
      final cell = donneesSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
          bold: true, backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white);
    }

    // Données
    for (int i = 0; i < donnees.length; i++) {
      final d = donnees[i];
      final row = i + 1;
      donneesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(d['date_releve'] ?? '-');
      donneesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = DoubleCellValue(((d['temperature'] ?? 0) as num).toDouble());
      donneesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = DoubleCellValue(((d['humidite'] ?? 0) as num).toDouble());
      donneesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = IntCellValue(((d['mortalite'] ?? 0) as num).toInt());
      donneesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = IntCellValue(((d['production'] ?? 0) as num).toInt());
      donneesSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(cycle['nom'] ?? '-');
    }

    // ── Feuille Résumé ──
    final Sheet resumeSheet = excel['Résumé'];
    final totalMorts = donnees.fold<int>(0, (s, d) =>
    s + ((d['mortalite'] ?? 0) as num).toInt());
    final avgTemp = donnees.isEmpty ? 0.0 : donnees.fold<double>(0, (s, d) =>
    s + ((d['temperature'] ?? 0) as num).toDouble()) / donnees.length;
    final totalProd = donnees.fold<int>(0, (s, d) =>
    s + ((d['production'] ?? 0) as num).toInt());
    final sujets = ((cycle['nombre_sujets'] ?? 0) as num).toInt();

    final resume = [
      ['Indicateur', 'Valeur'],
      ['Éleveur', SessionManager.nom],
      ['Cycle', cycle['nom'] ?? '-'],
      ['Nombre de sujets', '$sujets'],
      ['Mortalité totale', '$totalMorts'],
      ['Taux de mortalité', '${sujets > 0 ? (totalMorts / sujets * 100).toStringAsFixed(1) : 0}%'],
      ['Température moyenne', '${avgTemp.toStringAsFixed(1)}°C'],
      ['Production totale', '$totalProd'],
      ['Nombre de relevés', '${donnees.length}'],
    ];

    for (int i = 0; i < resume.length; i++) {
      for (int j = 0; j < resume[i].length; j++) {
        final cell = resumeSheet.cell(
            CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i));
        cell.value = TextCellValue(resume[i][j]);
        if (i == 0) cell.cellStyle = CellStyle(bold: true);
      }
    }

    // Sauvegarder et partager
    final bytes = excel.save();
    if (bytes != null) {
      final uint8List = Uint8List.fromList(bytes);
      final xFile = XFile.fromData(uint8List,
          name: 'rapport_${cycle['nom'] ?? 'cycle'}_${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      await Share.shareXFiles([xFile], text: 'Rapport Excel — ${cycle['nom']}');
    }
  }

  // ── HELPERS PDF ──
  static pw.Widget _pdfInfoCard(String label, String value) =>
      pw.Expanded(child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            color: PdfColors.blueGrey50,
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: pw.TextStyle(
              color: PdfColors.blueGrey500, fontSize: 8)),
          pw.Text(value, style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ]),
      ));

  static pw.Widget _pdfKpi(String label, String value, String sub, PdfColor color) =>
      pw.Expanded(child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
            border: pw.Border.all(color: color, width: 1.5),
            borderRadius: pw.BorderRadius.circular(4)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 14, color: color)),
          pw.Text(sub, style: pw.TextStyle(fontSize: 8, color: color)),
        ]),
      ));

  static pw.Widget _pdfCell(String value) => pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)));
}