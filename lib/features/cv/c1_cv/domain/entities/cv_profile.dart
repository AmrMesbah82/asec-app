/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_profile.dart
/// Purpose: Declares `CvProfile` — one member's CV.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// The field list is ENGX's. One deliberate difference: there is no
/// `deviceId`. ENGX identified a CV by the device that wrote it; here a CV
/// belongs to an ACCOUNT, and the document id IS that account's uid — so one
/// member has exactly one CV, on every device they sign in from.

import 'package:asec/features/cv/c1_cv/domain/enums/cv_status.dart';

class CvProfile {
  /// The owner's uid, which is also the document id.
  final String uid;

  // ── Identity ──────────────────────────────────────────────────────────────
  final String fullName;
  final String email;
  final String phone;
  final String location;
  final String militaryStatus;
  final String graduationYear;

  // ── Profession ────────────────────────────────────────────────────────────
  final String specialization;
  final String role;
  final List<String> proSkills;
  final List<String> softSkills;
  final List<String> languages;
  final String bio;

  // ── Links ─────────────────────────────────────────────────────────────────
  final String photoUrl;
  final String photoPath;
  final String facebookLink;
  final String linkedinLink;
  final String portfolioLink;

  // ── The CV file itself ────────────────────────────────────────────────────
  //
  // A REAL UPLOADED FILE, not a link to one. A Drive link breaks the moment
  // the owner changes its sharing, and it asks whoever reads the CV to trust
  // a third-party page. The PDF lives in this app's own Cloud Storage, under
  // the owner's uid, and is served from a download URL that cannot expire
  // behind a permission the app does not control.
  final String cvFileUrl;

  /// The Storage object, so replacing or deleting the CV removes the old file
  /// instead of leaving it behind, paid for and unreachable.
  final String cvFilePath;

  /// The name the member picked it with, shown instead of a Storage path.
  final String cvFileName;

  final int cvFileSize;

  // ── Review ────────────────────────────────────────────────────────────────
  final CvStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CvProfile({
    required this.uid,
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.militaryStatus = '',
    this.graduationYear = '',
    this.specialization = '',
    this.role = '',
    this.proSkills = const <String>[],
    this.softSkills = const <String>[],
    this.languages = const <String>[],
    this.bio = '',
    this.photoUrl = '',
    this.photoPath = '',
    this.facebookLink = '',
    this.linkedinLink = '',
    this.portfolioLink = '',
    this.cvFileUrl = '',
    this.cvFilePath = '',
    this.cvFileName = '',
    this.cvFileSize = 0,
    this.status = CvStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  static const CvProfile empty = CvProfile(uid: '');

  bool get isEmpty => uid.isEmpty;
  bool get hasPhoto => photoUrl.isNotEmpty;
  bool get hasCvFile => cvFileUrl.isNotEmpty;

  /// "1.4 MB". Zero bytes reads as empty rather than "0.0 MB", because a file
  /// whose size was never recorded is not a file of no size.
  String get cvFileSizeLabel => cvFileSize <= 0
      ? ''
      : '${(cvFileSize / (1024 * 1024)).toStringAsFixed(1)} MB';

  /// The one line under the name in a directory card.
  String get headline {
    if (role.isNotEmpty && specialization.isNotEmpty) {
      return '$role · $specialization';
    }
    return role.isNotEmpty ? role : specialization;
  }

  bool get hasLinks =>
      facebookLink.isNotEmpty ||
      linkedinLink.isNotEmpty ||
      portfolioLink.isNotEmpty;

  /// Everything the directory searches on, lowercased once.
  String get searchIndex => <String>[
        fullName,
        email,
        role,
        specialization,
        location,
        ...proSkills,
        ...softSkills,
      ].join(' ').toLowerCase();

  /// The form's own completeness check: the fields a CV is useless without.
  /// Links, photo and bio are optional by design — a CV with none of them is
  /// still a CV.
  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      location.isNotEmpty &&
      militaryStatus.isNotEmpty &&
      graduationYear.isNotEmpty &&
      specialization.isNotEmpty &&
      role.isNotEmpty;

  CvProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? location,
    String? militaryStatus,
    String? graduationYear,
    String? specialization,
    String? role,
    List<String>? proSkills,
    List<String>? softSkills,
    List<String>? languages,
    String? bio,
    String? photoUrl,
    String? photoPath,
    String? facebookLink,
    String? linkedinLink,
    String? portfolioLink,
    String? cvFileUrl,
    String? cvFilePath,
    String? cvFileName,
    int? cvFileSize,
    CvStatus? status,
  }) {
    return CvProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      militaryStatus: militaryStatus ?? this.militaryStatus,
      graduationYear: graduationYear ?? this.graduationYear,
      specialization: specialization ?? this.specialization,
      // A new specialization does not clear the role, but a new ROLE clears
      // the pro skills — they were picked from the old role's list. The cubit
      // does that; this stays a plain copy.
      role: role ?? this.role,
      proSkills: proSkills ?? this.proSkills,
      softSkills: softSkills ?? this.softSkills,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      facebookLink: facebookLink ?? this.facebookLink,
      linkedinLink: linkedinLink ?? this.linkedinLink,
      portfolioLink: portfolioLink ?? this.portfolioLink,
      cvFileUrl: cvFileUrl ?? this.cvFileUrl,
      cvFilePath: cvFilePath ?? this.cvFilePath,
      cvFileName: cvFileName ?? this.cvFileName,
      cvFileSize: cvFileSize ?? this.cvFileSize,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
