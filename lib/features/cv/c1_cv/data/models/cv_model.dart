/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_model.dart
/// Purpose: Declares `CvModel` — the `cvs/{uid}` document shape.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// Field names are snake_case like every other document in this app, even
/// though ENGX wrote camelCase — one convention per database beats matching a
/// different app's spelling. The VALUES are ENGX's field for field.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/helper/main_helper/firestore_mapper.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/domain/enums/cv_status.dart';

abstract final class CvModel {
  const CvModel._();

  static const String fullName = 'full_name';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String location = 'location';
  static const String militaryStatus = 'military_status';
  static const String graduationYear = 'graduation_year';
  static const String specialization = 'specialization';
  static const String role = 'job_role';
  static const String proSkills = 'pro_skills';
  static const String softSkills = 'soft_skills';
  static const String languages = 'languages';
  static const String bio = 'bio';
  static const String photoUrl = 'photo_url';
  static const String photoPath = 'photo_path';
  static const String facebookLink = 'facebook_link';
  static const String linkedinLink = 'linkedin_link';
  static const String cvFileUrl = 'cv_file_url';
  static const String cvFilePath = 'cv_file_path';
  static const String cvFileName = 'cv_file_name';
  static const String cvFileSize = 'cv_file_size';
  static const String portfolioLink = 'portfolio_link';
  static const String status = 'status';

  static CvProfile fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.safeData;

    return CvProfile(
      uid: doc.id,
      fullName: data.str(fullName),
      email: data.str(email),
      phone: data.str(phone),
      location: data.str(location),
      militaryStatus: data.str(militaryStatus),
      graduationYear: data.str(graduationYear),
      specialization: data.str(specialization),
      role: data.str(role),
      proSkills: data.stringList(proSkills),
      softSkills: data.stringList(softSkills),
      languages: data.stringList(languages),
      bio: data.str(bio),
      photoUrl: data.str(photoUrl),
      photoPath: data.str(photoPath),
      facebookLink: data.str(facebookLink),
      linkedinLink: data.str(linkedinLink),
      cvFileUrl: data.str(cvFileUrl),
      cvFilePath: data.str(cvFilePath),
      cvFileName: data.str(cvFileName),
      cvFileSize: data.integer(cvFileSize),
      portfolioLink: data.str(portfolioLink),
      status: CvStatus.fromKey(data.str(status)),
      createdAt: data.date(FirebaseCollections.createdAtField),
      updatedAt: data.date(FirebaseCollections.updatedAtField),
    );
  }

  /// Everything the OWNER writes. The status is not here: the member must not
  /// be able to mark their own CV shortlisted, and the rules enforce that by
  /// refusing any write that touches the field.
  static Map<String, dynamic> toMap(CvProfile cv, {bool isCreate = false}) {
    return <String, dynamic>{
      fullName: cv.fullName.trim(),
      email: cv.email.trim().toLowerCase(),
      phone: cv.phone.trim(),
      location: cv.location,
      militaryStatus: cv.militaryStatus,
      graduationYear: cv.graduationYear,
      specialization: cv.specialization,
      role: cv.role,
      proSkills: cv.proSkills,
      softSkills: cv.softSkills,
      languages: cv.languages,
      bio: cv.bio.trim(),
      photoUrl: cv.photoUrl,
      photoPath: cv.photoPath,
      facebookLink: cv.facebookLink.trim(),
      linkedinLink: cv.linkedinLink.trim(),
      cvFileUrl: cv.cvFileUrl,
      cvFilePath: cv.cvFilePath,
      cvFileName: cv.cvFileName,
      cvFileSize: cv.cvFileSize,
      portfolioLink: cv.portfolioLink.trim(),
      if (isCreate) status: CvStatus.pending.key,
      if (isCreate)
        FirebaseCollections.createdAtField: FieldValue.serverTimestamp(),
      FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
    };
  }

  /// What the ADMIN may change: the review state, and nothing else.
  static Map<String, dynamic> toStatusMap(CvStatus value) => <String, dynamic>{
        status: value.key,
        FirebaseCollections.updatedAtField: FieldValue.serverTimestamp(),
      };
}
