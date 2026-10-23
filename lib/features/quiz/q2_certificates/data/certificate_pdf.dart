/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_pdf.dart
/// Purpose: Declares `CertificatePdf` — draws the ASEC certificate as an A4
///          landscape PDF and hands it to the system to save / share / print
///          (the `printing` package: a share sheet on phones and the Mac, a
///          download on the web).
/// Author: ASEC team
/// Created: 1/10/2026
///
/// The layout mirrors `CertificateView` (the on-screen certificate). Cairo is
/// used for every line because it has both Latin and Arabic letters, so an
/// Arabic name or course prints correctly.

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';

abstract final class CertificatePdf {
  static const PdfColor _navy = PdfColor.fromInt(0xFF1F2A6B);
  static const PdfColor _blue = PdfColor.fromInt(0xFF3355D6);
  static const PdfColor _red = PdfColor.fromInt(0xFFD6002A);
  static const PdfColor _ink = PdfColor.fromInt(0xFF2B2F3A);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _paper = PdfColor.fromInt(0xFFFFFDF8);

  static Future<Uint8List> build(CertificateData d) async {
    final pw.Font regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Regular.ttf'));
    final pw.Font bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/fonts_english/Cairo/Cairo-Bold.ttf'));
    final pw.MemoryImage logo = pw.MemoryImage(
        (await rootBundle.load('assets/certificate/asec_logo.png')).buffer.asUint8List());

    final pw.Document doc = pw.Document(
      title: 'ASEC Certificate — ${d.course}',
      author: 'ASEC',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    pw.Widget line(String text, double size,
        {PdfColor color = _ink, bool isBold = false, double spacing = 0}) {
      final bool ar = CertificateData.isArabic(text);
      return pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        style: pw.TextStyle(
          fontSize: size,
          color: color,
          font: isBold ? bold : regular,
          letterSpacing: spacing,
        ),
      );
    }

    pw.Widget footerItem(String label, String labelAr, String value) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: <pw.Widget>[
            line(value, 12, color: _navy, isBold: true),
            pw.Container(width: 150, height: 0.8, color: _muted, margin: const pw.EdgeInsets.symmetric(vertical: 4)),
            line(label, 9, color: _muted),
            line(labelAr, 9, color: _muted),
          ],
        );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) => pw.Container(
          color: _paper,
          padding: const pw.EdgeInsets.all(18),
          child: pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _navy, width: 5)),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: _red, width: 1.2)),
              padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 22),
              child: pw.Column(
                children: <pw.Widget>[
                  pw.Image(logo, width: 40, height: 43),
                  pw.SizedBox(height: 4),
                  line('ASEC', 12, color: _navy, isBold: true, spacing: 6),
                  pw.SizedBox(height: 6),
                  line('CERTIFICATE OF COMPLETION', 24, color: _navy, isBold: true, spacing: 2),
                  line('شهادة إتمام', 15, color: _red, isBold: true),
                  pw.SizedBox(height: 8),
                  line('This is to certify that', 11, color: _muted),
                  line('نشهد بأن', 10, color: _muted),
                  line(d.name, 26, color: _blue, isBold: true),
                  pw.Container(width: 360, height: 1, color: _red, margin: const pw.EdgeInsets.only(top: 2, bottom: 10)),
                  line('has successfully completed the course', 11, color: _muted),
                  line('قد أتمّ بنجاح كورس', 10, color: _muted),
                  line(d.course, 18, color: _red, isBold: true),
                  pw.SizedBox(height: 6),
                  if (d.percent != null) ...<pw.Widget>[
                    line('and passed the final exam with a score of ${d.percent}%', 11, color: _ink),
                    line('واجتاز الاختبار النهائي بنسبة ${d.percent}%', 11, color: _ink),
                  ],
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: <pw.Widget>[
                      footerItem('Date', 'التاريخ', d.dateLabel),
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: _red, width: 2.5),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: <pw.Widget>[
                            line('ASEC', 13, color: _red, isBold: true, spacing: 2),
                            line('CERTIFIED', 6, color: _red, spacing: 1.5),
                          ],
                        ),
                      ),
                      footerItem('Certificate No.', 'رقم الشهادة', d.number),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return doc.save();
  }

  /// Builds the PDF and opens the system's save / share sheet.
  static Future<void> share(CertificateData d) async {
    final Uint8List bytes = await build(d);
    await Printing.sharePdf(bytes: bytes, filename: d.fileName);
  }
}
