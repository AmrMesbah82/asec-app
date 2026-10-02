/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: certificate_data.dart
/// Purpose: Declares `CertificateData` — what an ASEC certificate says, taken
///          from a passed certificate quiz attempt. One source for the
///          on-screen certificate and the PDF, so the two never disagree.
/// Author: ASEC team
/// Created: 1/10/2026

import 'package:intl/intl.dart';

import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_attempt.dart';

class CertificateData {
  const CertificateData({
    required this.name,
    required this.course,
    required this.examTitle,
    required this.percent,
    required this.date,
    required this.number,
  });

  factory CertificateData.from(Quiz quiz, QuizAttempt attempt) {
    final String course =
        quiz.course.trim().isNotEmpty ? quiz.course.trim() : quiz.title.trim();
    return CertificateData(
      name: attempt.userName.trim().isNotEmpty
          ? attempt.userName.trim()
          : attempt.userEmail.split('@').first,
      course: course,
      examTitle: quiz.title.trim(),
      percent: attempt.percent.round(),
      date: attempt.submittedAt ?? DateTime.now(),
      number: numberFor('${quiz.id}_${attempt.userId}'),
    );
  }

  final String name;
  final String course;
  final String examTitle;
  final int percent;
  final DateTime date;

  /// "ASEC-7K2Q9XA" — stable for one member and one exam.
  final String number;

  String get dateLabel => DateFormat('d MMMM yyyy', 'en').format(date);

  String get fileName => 'ASEC-Certificate-$number.pdf';

  static bool isArabic(String text) => RegExp(r'[؀-ۿ]').hasMatch(text);

  /// FNV-1a of the attempt id, in base 36.
  static String numberFor(String key) {
    int hash = 0x811c9dc5;
    for (final int unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return 'ASEC-${hash.toRadixString(36).toUpperCase().padLeft(7, '0')}';
  }
}
