/// Module: quiz / q2_certificates
///
///*************************** FILE INFO ****************************///
/// File Name: issued_certificates.dart
/// Purpose: Declares `IssuedCertificate` and `IssuedCertificates` — ASEC
///          certificates the admin gives a member by hand (Members → Edit
///          access → Certificates), without the final exam.
///          `certificates/{uid}_{course key}`.
/// Author: ASEC team
/// Created: 20/10/2026
///
/// The member reads their own; an admin with Quizzes → Certificate quizzes
/// issues and takes them back (firestore.rules).

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/quiz/q2_certificates/data/certificate_data.dart';

class IssuedCertificate {
  const IssuedCertificate({
    required this.id,
    required this.uid,
    required this.name,
    required this.course,
    this.issuedAt,
  });

  final String id;
  final String uid;
  final String name;
  final String course;
  final DateTime? issuedAt;

  CertificateData get data =>
      CertificateData.issued(name: name, course: course, uid: uid, date: issuedAt);
}

abstract final class IssuedCertificates {
  const IssuedCertificates._();

  static CollectionReference<Map<String, dynamic>> get _col =>
      AppFirebase.db.collection(FirebaseCollections.certificates);

  /// One per member and course. The course is hashed: a course name may
  /// hold characters a document id cannot.
  static String idFor(String uid, String course) =>
      '${uid}_${CertificateData.numberFor(course.trim().toLowerCase()).replaceAll('ASEC-', '')}';

  static IssuedCertificate _of(DocumentSnapshot<Map<String, dynamic>> d) {
    final Map<String, dynamic> m = d.safeData;
    return IssuedCertificate(
      id: d.id,
      uid: m.str('user_id'),
      name: m.str('user_name'),
      course: m.str('course'),
      issuedAt: m.date('issued_at'),
    );
  }

  /// [uid]'s issued certificates. Errors (rules not deployed yet) give an
  /// empty list, so pages that show them still open.
  static Stream<List<IssuedCertificate>> watchFor(String uid) async* {
    yield const <IssuedCertificate>[];
    yield* _col
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> s) =>
            <IssuedCertificate>[for (final QueryDocumentSnapshot<Map<String, dynamic>> d in s.docs) _of(d)])
        .handleError((Object _) {});
  }

  static Future<void> issue(AppUser member, String course, {required String adminUid}) =>
      _col.doc(idFor(member.uid, course)).set(<String, dynamic>{
        'user_id': member.uid,
        'user_name': member.displayName,
        'user_email': member.email,
        'course': course.trim(),
        'issued_by': adminUid,
        'issued_at': FieldValue.serverTimestamp(),
      });

  static Future<void> revoke(String uid, String course) =>
      _col.doc(idFor(uid, course)).delete();
}
