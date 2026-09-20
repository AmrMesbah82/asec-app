/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_status.dart
/// Purpose: Declares `CvStatus` — where a CV stands in the admin's review.
/// Author: ASEC team
/// Created: 20/9/2026

import 'package:flutter/widgets.dart';

import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/generated/l10n.dart';

/// Set by the ADMIN, never by the owner — the member writes the CV, the admin
/// says what happened to it. Same four states ENGX uses.
enum CvStatus {
  pending('Pending'),
  reviewed('Reviewed'),
  shortlisted('Shortlisted'),
  rejected('Rejected');

  const CvStatus(this.key);

  final String key;

  static CvStatus fromKey(String? key) {
    for (final CvStatus status in CvStatus.values) {
      if (status.key == key) return status;
    }
    return CvStatus.pending;
  }

  Color get color {
    switch (this) {
      case CvStatus.pending:
        return AppColors.statusPending;
      case CvStatus.reviewed:
        return AppColors.primary;
      case CvStatus.shortlisted:
        return AppColors.green;
      case CvStatus.rejected:
        return AppColors.red;
    }
  }

  String label(BuildContext context) {
    final S s = S.of(context);
    switch (this) {
      case CvStatus.pending:
        return s.cvPending;
      case CvStatus.reviewed:
        return s.cvReviewed;
      case CvStatus.shortlisted:
        return s.cvShortlisted;
      case CvStatus.rejected:
        return s.cvRejected;
    }
  }
}
