import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../models/quote.dart';
import '../models/user.dart';
import '../utils/constants.dart';

class PdfService {
  Future<Uint8List> generateQuotePdf(Quote quote, UserModel user) async {
    final pdf = pw.Document();

    // Charger police
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    // Logo placeholder
    pw.ImageProvider? logo;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      logo = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logo, user, fontBold),
              pw.SizedBox(height: 30),
              _buildQuoteInfo(quote, fontBold, font),
              pw.SizedBox(height: 30),
              _buildRoomsTable(quote, fontBold, font),
              pw.SizedBox(height: 30),
              _buildTotal(quote, fontBold),
              pw.Spacer(),
              _buildFooter(font),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.ImageProvider? logo, UserModel user, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(logo),
              ),
              pw.SizedBox(height: 10),
            ],
            pw.Text(
              user.entreprise,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 20,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '${user.prenom} ${user.nom}',
              style: pw.TextStyle(font: fontBold, fontSize: 14),
            ),
            pw.Text(
              'Tél: ${user.telephone}',
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue800, width: 2),
          ),
          child: pw.Text(
            'DEVIS',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 24,
              color: PdfColors.blue800,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildQuoteInfo(Quote quote, pw.Font fontBold, pw.Font font) {
    final dateStr = "${quote.createdAt.day.toString().padLeft(2, '0')}/"
        "${quote.createdAt.month.toString().padLeft(2, '0')}/"
        "${quote.createdAt.year}";

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Numéro de devis:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.Text('#${quote.id.toString().padLeft(6, '0')}', style: pw.TextStyle(font: font, fontSize: 14)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Date:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.Text(dateStr, style: pw.TextStyle(font: font, fontSize: 14)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Nombre de pièces:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              pw.Text('${quote.rooms.length}', style: pw.TextStyle(font: font, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRoomsTable(Quote quote, pw.Font fontBold, pw.Font font) {
    final headers = ['Pièce', 'Superficie (m²)', 'Surface/carton (m²)', 'Cartons'];
    final data = quote.rooms.map((room) => [
      room.nom,
      room.superficie.toStringAsFixed(1),
      room.surfaceParCarton?.toStringAsFixed(2) ?? '-',
      room.cartons?.toString() ?? '-',
    ]).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Détail des pièces à carreler',
          style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue800),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          context: null,
          data: data,
          headers: headers,
          headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          cellStyle: pw.TextStyle(font: font, fontSize: 9),
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
          },
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        ),
      ],
    );
  }

  pw.Widget _buildTotal(Quote quote, pw.Font fontBold) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue800,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL CARTONS NÉCESSAIRES',
              style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.white),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '${quote.totalCartons} cartons',
              style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.white),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400, width: 1)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Ce devis est valable 30 jours à compter de la date d\'émission.',
            style: pw.TextStyle(font: font, fontSize: 10, fontStyle: pw.FontStyle.italic),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Devis généré par ${Constants.appName} v${Constants.appVersion}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  Future<void> sharePdf(Quote quote, UserModel user) async {
    try {
      final pdfBytes = await generateQuotePdf(quote, user);
      
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'devis_${quote.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF: $e');
    }
  }

  Future<void> previewPdf(Quote quote, UserModel user) async {
    try {
      final pdfBytes = await generateQuotePdf(quote, user);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Erreur lors de la prévisualisation du PDF: $e');
    }
  }
}