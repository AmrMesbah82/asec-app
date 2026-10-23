/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_view.dart
/// Purpose: Declares `CertificateView` — the ASEC certificate on screen. Drawn
///          on a fixed A4-landscape canvas and scaled to fit, so it looks the
///          same on a phone and a desktop, and matches the PDF.
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:flutter/material.dart';

import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class CertificateView extends StatelessWidget {
  const CertificateView({super.key, required this.data});

  final CertificateData data;

  static const Color _navy = Color(0xFF1F2A6B);
  static const Color _blue = Color(0xFF3355D6);
  static const Color _red = Color(0xFFD6002A);
  static const Color _ink = Color(0xFF2B2F3A);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _paper = Color(0xFFFFFDF8);

  Widget _line(String text, double size,
      {Color color = _ink, bool bold = false, double spacing = 0}) {
    return Text(
      FormatHelper.capitalize(text),
      textAlign: TextAlign.center,
      textDirection: CertificateData.isArabic(text) ? TextDirection.rtl : TextDirection.ltr,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        letterSpacing: spacing,
        height: 1.35,
      ),
    );
  }

  Widget _footer(String label, String labelAr, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _line(value, 13, color: _navy, bold: true),
          Container(width: 160, height: 1, color: _muted, margin: const EdgeInsets.symmetric(vertical: 4)),
          _line(label, 10, color: _muted),
          _line(labelAr, 10, color: _muted),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 842 / 595,
      child: FittedBox(
        child: SizedBox(
          width: 842,
          height: 595,
          child: Container(
            color: _paper,
            padding: const EdgeInsets.all(18),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: _navy, width: 5)),
              padding: const EdgeInsets.all(6),
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: _red, width: 1.2)),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                child: Column(
                  children: <Widget>[
                    Image.asset('assets/certificate/asec_logo.png', width: 40, height: 43),
                    _line('ASEC', 13, color: _navy, bold: true, spacing: 6),
                    const SizedBox(height: 4),
                    _line('CERTIFICATE OF COMPLETION', 26, color: _navy, bold: true, spacing: 2),
                    _line('شهادة إتمام', 16, color: _red, bold: true),
                    const SizedBox(height: 6),
                    _line('This is to certify that', 12, color: _muted),
                    _line('نشهد بأن', 11, color: _muted),
                    _line(data.name, 28, color: _blue, bold: true),
                    Container(width: 380, height: 1.2, color: _red, margin: const EdgeInsets.only(bottom: 6)),
                    _line('has successfully completed the course', 12, color: _muted),
                    _line('قد أتمّ بنجاح كورس', 11, color: _muted),
                    _line(data.course, 19, color: _red, bold: true),
                    const SizedBox(height: 2),
                    // Issued by the admin (no exam) → no score line.
                    if (data.percent != null) ...<Widget>[
                      _line('and passed the final exam with a score of ${data.percent}%', 12),
                      _line('واجتاز الاختبار النهائي بنسبة ${data.percent}%', 12),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        _footer('Date', 'التاريخ', data.dateLabel),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _red, width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              _line('ASEC', 14, color: _red, bold: true, spacing: 2),
                              _line('CERTIFIED', 7, color: _red, spacing: 1.5),
                            ],
                          ),
                        ),
                        _footer('Certificate No.', 'رقم الشهادة', data.number),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
