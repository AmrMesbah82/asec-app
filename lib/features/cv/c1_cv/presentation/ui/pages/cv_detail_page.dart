/// Module: cv / c1_cv
///
///*************************** FILE INFO ****************************///
/// File Name: cv_detail_page.dart
/// Purpose: Declares `CvDetailPage` — one CV, laid out as a CV.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// THIS PAGE IS A DOCUMENT, NOT A PROFILE SCREEN.
///
/// The first version was a stack of rounded cards under a purple banner —
/// which is what an app screen looks like, not what a CV looks like. A person
/// reading twenty of these is comparing candidates, and the layout that does
/// that job is the one the printed page settled on a century ago: one sheet,
/// a name block at the top, a narrow left column of facts, a wide right column
/// of substance, section headings that are rules rather than boxes.
///
/// So the body is a SHEET: a single surface with real margins, sections
/// separated by a hairline and a small uppercase heading, and nothing nested
/// inside anything else. On a phone the two columns stack and the sheet keeps
/// its margins — a CV read on a phone is still a CV.
///
/// Two things sit OUTSIDE the sheet, because they are not part of the
/// document: the download button and, for the admin, the review chips.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/cv/c1_cv/data/repository/cv_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/base_repository/cv_base_repository.dart';
import 'package:asec/features/cv/c1_cv/domain/entities/cv_profile.dart';
import 'package:asec/features/cv/c1_cv/domain/enums/cv_status.dart';
import 'package:asec/features/cv/c1_cv/presentation/ui/widgets/cv_card.dart';
import 'package:asec/generated/l10n.dart';

class CvDetailPage extends StatelessWidget {
  CvDetailPage({super.key, required this.cv, this.isAdmin = false});

  final CvProfile cv;
  final bool isAdmin;

  final CvBaseRepository _repository = CvRepository();

  /// Below this the sheet's two columns stack.
  static const double _splitWidth = 760;

  Future<void> _open(String url) async {
    if (url.trim().isEmpty) return;
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final S s = S.of(context);
    final NavigatorState navigator = Navigator.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.deleteQuestion(cv.fullName),
      subtitle: s.deleteCvBody,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      onConfirm: () async {
        await _repository.delete(cv);
        navigator.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool split = MediaQuery.sizeOf(context).width >= _splitWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(cv.fullName, style: StyleText.fontSize18Weight600),
        actions: <Widget>[
          if (cv.hasCvFile)
            IconButton(
              tooltip: s.downloadCv,
              onPressed: () => _open(cv.cvFileUrl),
              icon: const AppIcon(Icons.download_rounded),
            ),
          if (isAdmin)
            IconButton(
              tooltip: s.delete,
              onPressed: () => _confirmDelete(context),
              icon: AppIcon(Icons.delete_outline_rounded, color: AppColors.red),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          // Roughly A4 proportions at a comfortable reading measure.
          constraints: BoxConstraints(maxWidth: 820.w),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppPadding.h,
              16.h,
              AppPadding.h,
              28.h,
            ),
            children: <Widget>[
              // Outside the sheet: the admin's verdict.
              if (isAdmin) ...<Widget>[
                _ReviewCard(cv: cv, repository: _repository),
                SizedBox(height: 16.h),
              ],

              _Sheet(cv: cv, split: split, onOpen: _open),

              if (cv.hasCvFile) ...<Widget>[
                SizedBox(height: 16.h),
                AppButton(
                  label: s.downloadCv,
                  icon: Icons.download_rounded,
                  expand: true,
                  onPressed: () => _open(cv.cvFileUrl),
                ),
              ],
              if (cv.updatedAt != null) ...<Widget>[
                SizedBox(height: 14.h),
                Text(
                  s.cvUpdatedOn(AppDates.day(context, cv.updatedAt)),
                  textAlign: TextAlign.center,
                  style: StyleText.fontSize11Weight400
                      .copyWith(color: AppColors.secondaryText),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── The sheet ────────────────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.cv,
    required this.split,
    required this.onOpen,
  });

  final CvProfile cv;
  final bool split;
  final Future<void> Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    final Widget aside = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Section(
          title: s.contactDetails,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Line(icon: Icons.alternate_email_rounded, value: cv.email),
              _Line(icon: Icons.phone_iphone_rounded, value: cv.phone),
              _Line(icon: Icons.location_on_outlined, value: cv.location),
            ],
          ),
        ),
        _Section(
          title: s.cvEducation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _Pair(label: s.cvSpecialization, value: cv.specialization),
              _Pair(label: s.graduationYear, value: cv.graduationYear),
              _Pair(label: s.militaryStatus, value: cv.militaryStatus),
            ],
          ),
        ),
        if (cv.languages.isNotEmpty)
          _Section(
            title: s.languagesLabel,
            child: _Chips(values: cv.languages, color: AppColors.green),
          ),
        if (cv.hasLinks)
          _Section(
            title: s.cvLinks,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (cv.linkedinLink.isNotEmpty)
                  _LinkLine(
                    icon: Icons.open_in_new_rounded,
                    label: s.linkedinLabel,
                    onTap: () => onOpen(cv.linkedinLink),
                  ),
                if (cv.portfolioLink.isNotEmpty)
                  _LinkLine(
                    icon: Icons.insights_rounded,
                    label: s.portfolioLabel,
                    onTap: () => onOpen(cv.portfolioLink),
                  ),
                if (cv.facebookLink.isNotEmpty)
                  _LinkLine(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: s.facebookLabel,
                    onTap: () => onOpen(cv.facebookLink),
                  ),
              ],
            ),
          ),
      ],
    );

    final Widget main = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (cv.bio.trim().isNotEmpty)
          _Section(
            title: s.cvSummary,
            child: Text(
              cv.bio.trim(),
              style: StyleText.fontSize14Weight400.copyWith(height: 1.6),
            ),
          ),
        if (cv.proSkills.isNotEmpty)
          _Section(
            title: s.proSkills,
            child: _Chips(values: cv.proSkills, color: AppColors.primary),
          ),
        if (cv.softSkills.isNotEmpty)
          _Section(
            title: s.softSkillsLabel,
            child: _Chips(
              values: cv.softSkills,
              color: AppColors.secondaryPrimary,
            ),
          ),
        if (cv.hasCvFile)
          _Section(
            title: s.driveLabel,
            child: _FileLine(cv: cv, onTap: () => onOpen(cv.cvFileUrl)),
          ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderGrey),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.blackShadow.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _NameBlock(cv: cv),

          // The margins of the page.
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 22.h),
            child: split
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1 : 2 — the narrow column carries facts, the wide one
                      // carries what the person actually wants read.
                      Expanded(flex: 4, child: aside),
                      SizedBox(width: 24.w),
                      Container(
                        width: 1,
                        constraints: BoxConstraints(minHeight: 220.h),
                        color: AppColors.borderGrey,
                      ),
                      SizedBox(width: 24.w),
                      Expanded(flex: 6, child: main),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[main, aside],
                  ),
          ),
        ],
      ),
    );
  }
}

/// The letterhead: a thin accent bar, the photo, the name, the title, and the
/// one-line status. Restrained on purpose — the name is what should be loud.
class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.cv});

  final CvProfile cv;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The one flash of brand colour on the page.
        Container(
          height: 6.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 18.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CvAvatar(cv: cv, size: 76),
              SizedBox(width: 18.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      cv.fullName,
                      style: StyleText.fontSize24Weight600.copyWith(
                        letterSpacing: 0.2,
                        height: 1.15,
                      ),
                    ),
                    if (cv.role.isNotEmpty) ...<Widget>[
                      SizedBox(height: 4.h),
                      Text(
                        cv.role.toUpperCase(),
                        style: StyleText.fontSize12Weight600.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                    if (cv.specialization.isNotEmpty) ...<Widget>[
                      SizedBox(height: 4.h),
                      Text(
                        cv.specialization,
                        style: StyleText.fontSize13Weight400
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: AppColors.borderGrey),
      ],
    );
  }
}

/// A heading that is a RULE, not a box: small, uppercase, tracked out, with a
/// short accent underline. Cheap to scan, and it does not fight the content
/// for attention the way a nested card does.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: StyleText.fontSize11Weight700.copyWith(
              color: AppColors.text,
              letterSpacing: 1.6,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: 28.w,
            height: 2.h,
            color: AppColors.primary,
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }
}

/// One contact line: an icon and the value. No label — "email" beside an
/// address is a word that tells the reader nothing the address does not.
class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: AppIcon(icon, size: 15.sp, color: AppColors.primary),
          ),
          SizedBox(width: 9.w),
          Expanded(
            child: SelectableText(
              value,
              style: StyleText.fontSize13Weight500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A labelled fact, stacked rather than side by side: in a narrow column a
/// label and a value on one row turn into two cramped ellipses.
class _Pair extends StatelessWidget {
  const _Pair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 11.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: StyleText.fontSize11Weight400
                .copyWith(color: AppColors.secondaryText),
          ),
          SizedBox(height: 2.h),
          Text(value, style: StyleText.fontSize13Weight600),
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.values, required this.color});

  final List<String> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7.w,
      runSpacing: 7.h,
      children: <Widget>[
        for (final String value in values)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.chip,
              borderRadius: AppRadius.buttonR,
            ),
            child: Text(
              value,
              style: StyleText.fontSize11Weight600.copyWith(color: AppColors.onChip),
            ),
          ),
      ],
    );
  }
}

class _LinkLine extends StatelessWidget {
  const _LinkLine({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.buttonR,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: Row(
            children: <Widget>[
              AppIcon(icon, size: 15.sp, color: AppColors.primary),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  label,
                  style: StyleText.fontSize13Weight500
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The attached document, shown as the file it is — name, size, and a tap
/// that downloads it.
class _FileLine extends StatelessWidget {
  const _FileLine({required this.cv, required this.onTap});

  final CvProfile cv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.buttonR,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: AppRadius.buttonR,
        ),
        child: Row(
          children: <Widget>[
            AppIcon(
              Icons.picture_as_pdf_rounded,
              size: 20.sp,
              color: AppColors.primary,
            ),
            SizedBox(width: 11.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    cv.cvFileName.isEmpty ? s.driveLabel : cv.cvFileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StyleText.fontSize13Weight600,
                  ),
                  Text(
                    cv.cvFileSizeLabel.isEmpty
                        ? s.downloadCv
                        : '${s.downloadCv} · ${cv.cvFileSizeLabel}',
                    style: StyleText.fontSize11Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
            ),
            AppIcon(
              Icons.download_rounded,
              size: 18.sp,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Admin only: the four review states, one tap each. Kept OUTSIDE the sheet —
/// it is a control, not part of the document.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.cv, required this.repository});

  final CvProfile cv;
  final CvBaseRepository repository;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return AppCard(
      title: s.reviewState,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: <Widget>[
          for (final CvStatus status in CvStatus.values)
            AppStatusChip(
              label: status.label(context),
              color: status.color,
              active: cv.status == status,
              onTap: () => repository.setStatus(cv.uid, status),
            ),
        ],
      ),
    );
  }
}
