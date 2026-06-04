import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../managers/session_manager.dart';

class ResumeCycleScreen extends StatelessWidget {
  final Map cycle;
  final List donnees;

  const ResumeCycleScreen({
    super.key,
    required this.cycle,
    required this.donnees,
  });

  // ── CALCULS ──
  int get _totalMorts => donnees.fold<int>(0,
      (s, d) => s + ((d['mortalite'] ?? 0) as num).toInt());

  double get _avgTemp => donnees.isEmpty ? 0 :
      donnees.fold<double>(0, (s, d) =>
          s + ((d['temperature'] ?? 0) as num).toDouble()) / donnees.length;

  double get _avgHum => donnees.isEmpty ? 0 :
      donnees.fold<double>(0, (s, d) =>
          s + ((d['humidite'] ?? 0) as num).toDouble()) / donnees.length;

  int get _totalProd => donnees.fold<int>(0,
      (s, d) => s + ((d['production'] ?? 0) as num).toInt());

  int get _sujets => ((cycle['nombre_sujets'] ?? 0) as num).toInt();

  double get _tauxSurvie => _sujets > 0
      ? ((_sujets - _totalMorts) / _sujets * 100) : 0;

  double get _tauxMort => _sujets > 0
      ? (_totalMorts / _sujets * 100) : 0;

  List get _donnesTries {
    final sorted = List.from(donnees);
    sorted.sort((a, b) =>
        (a['date_releve'] ?? '').compareTo(b['date_releve'] ?? ''));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cycle['nom'] ?? 'Résumé', style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 15)),
          Text('${donnees.length} relevés journaliers',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
            tooltip: 'Exporter PDF',
            onPressed: () => _exporterPDF(context),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_rounded, color: Colors.white),
            tooltip: 'Exporter Excel',
            onPressed: () => _exporterExcel(context),
          ),
        ],
      ),
      body: donnees.isEmpty
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Aucune donnée journalière pour ce cycle',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ]))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── KPI ──
          _kpiGrid(),
          const SizedBox(height: 16),

          // ── INFO CYCLE ──
          _cycleInfoCard(),
          const SizedBox(height: 16),

          // ── TABLEAU DONNÉES ──
          _tableauDonnees(context),
          const SizedBox(height: 16),

          // ── BOUTONS EXPORT ──
          _exportButtons(context),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ── KPI GRID ──
  Widget _kpiGrid() => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10,
    childAspectRatio: 1.8,
    children: [
      _kpiCard('🐔 Sujets initiaux', '$_sujets', kBlue),
      _kpiCard('💀 Total morts', '$_totalMorts',
          _tauxMort > 5 ? kRed : kGreen),
      _kpiCard('✅ Taux survie', '${_tauxSurvie.toStringAsFixed(1)}%',
          _tauxSurvie > 95 ? kGreen : kOrange),
      _kpiCard('📊 Taux mortalité', '${_tauxMort.toStringAsFixed(1)}%',
          _tauxMort > 5 ? kRed : kGreen),
      _kpiCard('🌡️ Temp. moyenne', '${_avgTemp.toStringAsFixed(1)}°C',
          _avgTemp >= 25 && _avgTemp <= 32 ? kGreen : kOrange),
      _kpiCard('💧 Humidité moy.', '${_avgHum.toStringAsFixed(1)}%',
          _avgHum >= 50 && _avgHum <= 70 ? kGreen : kOrange),
      _kpiCard('📦 Total prod.', '$_totalProd', kPurple),
      _kpiCard('📅 Nb relevés', '${donnees.length}', kBlue),
    ],
  );

  Widget _kpiCard(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(label, style: const TextStyle(
          fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w900, color: color)),
    ]),
  );

  // ── INFO CYCLE ──
  Widget _cycleInfoCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('📋 Informations du Cycle', style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 14)),
      const SizedBox(height: 12),
      _infoRow('Nom', cycle['nom'] ?? '-'),
      _infoRow('Souche', cycle['souche'] ?? '-'),
      _infoRow('Bâtiment', cycle['batiment'] ?? '-'),
      _infoRow('Date début', cycle['date_debut'] ?? '-'),
      _infoRow('Date fin', cycle['date_fin'] ?? '-'),
      _infoRow('Statut', cycle['statut'] ?? '-'),
      _infoRow('Entreprise', SessionManager.nom),
    ]),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(
          color: Colors.grey, fontSize: 12))),
      Expanded(child: Text(value, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 12))),
    ]),
  );

  // ── TABLEAU DONNÉES ──
  Widget _tableauDonnees(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          const Text('📊 Données Journalières', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 14)),
          const Spacer(),
          Text('${_donnesTries.length} jours',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              const Color(0xFF0F172A)),
          headingTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700,
              fontSize: 11),
          dataTextStyle: const TextStyle(fontSize: 11),
          columnSpacing: 16,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: Text('Jour')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Morts'), numeric: true),
            DataColumn(label: Text('Temp °C'), numeric: true),
            DataColumn(label: Text('Hum %'), numeric: true),
            DataColumn(label: Text('Prod.'), numeric: true),
            DataColumn(label: Text('Poids (kg)'), numeric: true),
            DataColumn(label: Text('Homo %'), numeric: true),
          ],
          rows: _donnesTries.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            final morts = ((d['mortalite'] ?? 0) as num).toInt();
            final temp = ((d['temperature'] ?? 0) as num).toDouble();
            final hum = ((d['humidite'] ?? 0) as num).toDouble();
            final prod = ((d['production'] ?? 0) as num).toInt();
            // poids_moyen_global stocké en grammes → convertir en kg
            final poidsG = ((d['poids_moyen_global'] ?? 0) as num).toDouble();
            final poidsKg = poidsG > 0 ? poidsG / 1000 : 0.0;
            // homogeneite en pourcentage
            final homo = ((d['homogeneite'] ?? 0) as num).toDouble();
            final date = (d['date_releve'] ?? '').toString();
            final dateStr = date.length >= 10 ? date.substring(0, 10) : date;

            return DataRow(
              color: WidgetStateProperty.all(
                  i.isEven ? Colors.white : const Color(0xFFF8FAFC)),
              cells: [
                DataCell(Text('J${i + 1}', style: const TextStyle(
                    fontWeight: FontWeight.w700, color: kBlue))),
                DataCell(Text(dateStr)),
                DataCell(Text('$morts', style: TextStyle(
                    color: morts > 5 ? kRed : kGreen,
                    fontWeight: FontWeight.w700))),
                DataCell(Text(temp.toStringAsFixed(1), style: TextStyle(
                    color: temp >= 25 && temp <= 32 ? kGreen : kOrange))),
                DataCell(Text(hum.toStringAsFixed(1), style: TextStyle(
                    color: hum >= 50 && hum <= 70 ? kGreen : kOrange))),
                DataCell(Text('$prod', style: const TextStyle(
                    color: kPurple, fontWeight: FontWeight.w600))),
                DataCell(Text(
                  poidsKg > 0 ? poidsKg.toStringAsFixed(3) : '-',
                  style: const TextStyle(color: kBlue, fontWeight: FontWeight.w600),
                )),
                DataCell(Text(
                  homo > 0 ? '${homo.toStringAsFixed(1)}%' : '-',
                  style: TextStyle(
                    color: homo >= 80 ? kGreen : homo >= 60 ? kOrange : kRed,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 8),
    ]),
  );

  // ── BOUTONS EXPORT ──
  Widget _exportButtons(BuildContext context) => Row(children: [
    Expanded(child: ElevatedButton.icon(
        onPressed: () => _exporterPDF(context),
        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
        label: const Text('Exporter PDF',
            style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
            backgroundColor: kRed, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0))),
    const SizedBox(width: 12),
    Expanded(child: ElevatedButton.icon(
        onPressed: () => _exporterExcel(context),
        icon: const Icon(Icons.table_chart_rounded, size: 18),
        label: const Text('Exporter Excel',
            style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
            backgroundColor: kGreen, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0))),
  ]);

  // ── EXPORT PDF ──
  Future<void> _exporterPDF(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final sorted = _donnesTries;

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          // En-tête
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey900,
                borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Text('🐔 Kewere Aissa Smart — Rapport Cycle',
                  style: pw.TextStyle(color: PdfColors.white,
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Cycle: ${cycle['nom'] ?? ''} | '
                  'Souche: ${cycle['souche'] ?? ''} | '
                  'Bâtiment: ${cycle['batiment'] ?? ''}',
                  style: const pw.TextStyle(
                      color: PdfColors.grey200, fontSize: 10)),
              pw.Text('Généré le: ${DateTime.now().toString().substring(0, 10)} '
                  'par ${SessionManager.nom}',
                  style: const pw.TextStyle(
                      color: PdfColors.grey400, fontSize: 9)),
            ]),
          ),
          pw.SizedBox(height: 16),

          // KPIs
          pw.Row(children: [
            _pdfKpi('Sujets', '$_sujets'),
            _pdfKpi('Total morts', '$_totalMorts'),
            _pdfKpi('Taux survie', '${_tauxSurvie.toStringAsFixed(1)}%'),
            _pdfKpi('Taux mort.', '${_tauxMort.toStringAsFixed(1)}%'),
            _pdfKpi('T° moy.', '${_avgTemp.toStringAsFixed(1)}°C'),
            _pdfKpi('Hum. moy.', '${_avgHum.toStringAsFixed(1)}%'),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _pdfKpi('Poids moy. final', () {
              final dernierPoids = sorted.isNotEmpty
                  ? ((sorted.last['poids_moyen_global'] ?? 0) as num).toDouble()
                  : 0.0;
              return dernierPoids > 0
                  ? '${(dernierPoids / 1000).toStringAsFixed(3)} kg'
                  : 'N/A';
            }()),
            _pdfKpi('Homogénéité moy.', () {
              final vals = sorted.where((d) =>
                  (d['homogeneite'] ?? 0) as num > 0).toList();
              if (vals.isEmpty) return 'N/A';
              final avg = vals.fold<double>(0, (s, d) =>
                  s + ((d['homogeneite'] ?? 0) as num).toDouble()) / vals.length;
              return '${avg.toStringAsFixed(1)}%';
            }()),
          ]),
          pw.SizedBox(height: 16),

          // Tableau
          pw.Text('Données Journalières',
              style: pw.TextStyle(fontSize: 13,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                    color: PdfColors.blueGrey900),
                children: ['Jour', 'Date', 'Morts',
                  'Temp (°C)', 'Hum (%)', 'Production',
                  'Poids (kg)', 'Homo (%)']
                    .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold))))
                    .toList(),
              ),
              ...sorted.asMap().entries.map((e) {
                final i = e.key;
                final d = e.value;
                final date = (d['date_releve'] ?? '').toString();
                final dateStr = date.length >= 10
                    ? date.substring(0, 10) : date;
                final bg = i.isEven ? PdfColors.white
                    : PdfColors.grey100;
                // poids en grammes → kg
                final poidsG = ((d['poids_moyen_global'] ?? 0) as num).toDouble();
                final poidsStr = poidsG > 0
                    ? (poidsG / 1000).toStringAsFixed(3)
                    : '-';
                // homogeneite en %
                final homo = ((d['homogeneite'] ?? 0) as num).toDouble();
                final homoStr = homo > 0 ? '${homo.toStringAsFixed(1)}%' : '-';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    'J${i + 1}',
                    dateStr,
                    '${(d['mortalite'] ?? 0)}',
                    '${((d['temperature'] ?? 0) as num).toStringAsFixed(1)}',
                    '${((d['humidite'] ?? 0) as num).toStringAsFixed(1)}',
                    '${(d['production'] ?? 0)}',
                    poidsStr,
                    homoStr,
                  ].map((v) => pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(v,
                          style: const pw.TextStyle(fontSize: 8))))
                      .toList(),
                );
              }),
            ],
          ),
        ],
      ));

      final bytes = await pdf.save();
      if (kIsWeb) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'rapport_${cycle['nom'] ?? 'cycle'}.pdf',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/rapport_${cycle['nom'] ?? 'cycle'}.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Rapport cycle ${cycle['nom'] ?? ''}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur PDF: $e'),
          backgroundColor: kRed));
    }
  }

  pw.Widget _pdfKpi(String label, String value) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
          color: PdfColors.blueGrey50,
          borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(children: [
        pw.Text(value, style: pw.TextStyle(
            fontSize: 13, fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900)),
        pw.Text(label, style: const pw.TextStyle(
            fontSize: 7, color: PdfColors.grey)),
      ]),
    ),
  );

  // ── EXPORT EXCEL ──
  Future<void> _exporterExcel(BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Données Cycle'];

      // En-têtes
      final headers = ['Jour', 'Date', 'Mortalité',
        'Température (°C)', 'Humidité (%)', 'Production',
        'Poids moyen (kg)', 'Homogénéité (%)'];
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#0F172A'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Données
      final sorted = _donnesTries;
      for (var i = 0; i < sorted.length; i++) {
        final d = sorted[i];
        final date = (d['date_releve'] ?? '').toString();
        final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
        // poids_moyen_global stocké en grammes → convertir en kg
        final poidsG = ((d['poids_moyen_global'] ?? 0) as num).toDouble();
        final poidsKg = poidsG > 0 ? (poidsG / 1000).toStringAsFixed(3) : '';
        final homo = ((d['homogeneite'] ?? 0) as num).toDouble();
        final homoStr = homo > 0 ? homo.toStringAsFixed(1) : '';
        final rowData = [
          'J${i + 1}',
          dateStr,
          (d['mortalite'] ?? 0).toString(),
          ((d['temperature'] ?? 0) as num).toStringAsFixed(1),
          ((d['humidite'] ?? 0) as num).toStringAsFixed(1),
          (d['production'] ?? 0).toString(),
          poidsKg,
          homoStr,
        ];
        for (var j = 0; j < rowData.length; j++) {
          sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: j, rowIndex: i + 1))
            .value = TextCellValue(rowData[j]);
        }
      }

      // Feuille résumé
      final resume = excel['Résumé'];
      final resumeData = [
        ['Cycle', cycle['nom'] ?? ''],
        ['Souche', cycle['souche'] ?? ''],
        ['Bâtiment', cycle['batiment'] ?? ''],
        ['Date début', cycle['date_debut'] ?? ''],
        ['Date fin', cycle['date_fin'] ?? ''],
        ['Sujets initiaux', '$_sujets'],
        ['Total morts', '$_totalMorts'],
        ['Taux mortalité', '${_tauxMort.toStringAsFixed(2)}%'],
        ['Taux survie', '${_tauxSurvie.toStringAsFixed(2)}%'],
        ['Température moyenne', '${_avgTemp.toStringAsFixed(1)}°C'],
        ['Humidité moyenne', '${_avgHum.toStringAsFixed(1)}%'],
        ['Total production', '$_totalProd'],
        ['Nombre relevés', '${donnees.length}'],
      ];
      for (var i = 0; i < resumeData.length; i++) {
        resume.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i))
          .value = TextCellValue(resumeData[i][0]);
        resume.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i))
          .value = TextCellValue(resumeData[i][1]);
      }

      final bytes = excel.encode()!;
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/rapport_${cycle['nom'] ?? 'cycle'}.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Rapport cycle ${cycle['nom'] ?? ''}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur Excel: $e'),
          backgroundColor: kRed));
    }
  }
}
