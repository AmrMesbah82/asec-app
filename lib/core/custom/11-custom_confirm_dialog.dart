/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 11-custom_confirm_dialog.dart
/// Purpose: Declares `showConfirmDialog`, `showSuccessDialog`,
///          `showErrorDialog`, `showWarningDialog` and `showCommentDialog`.
/// Author: Manger Plus team
/// Updated: 4/9/2026 - Replaced by the knowticed_plus dialog set. The previous
///          version was a Material `Icon` in a tinted disc with a bool return;
///          this is the Lottie shell the rest of the product uses.
///
/// THESE ARE THE ONLY WAY THE APP SPEAKS
/// -------------------------------------
/// No `SnackBar`, anywhere, for anything. A snackbar auto-dismisses after a few
/// seconds, can be covered by the keyboard or a bottom sheet, and on a wide
/// console window it lands in a corner far from the control the user just
/// pressed. Every outcome the user has to see — a failure, a validation guard,
/// a confirmation — goes through one of these and stays until acknowledged.
///
///   showConfirmDialog  → "are you sure", two buttons
///   showSuccessDialog  → it worked; dismisses on a barrier tap, since nothing
///                        is required of the user
///   showErrorDialog    → it failed; explicit Close, because acknowledging a
///                        failure should be a deliberate act
///   showWarningDialog  → nothing broke, the form is simply incomplete
///   showCommentDialog  → a reason / justification text area
///
/// The upload dialog from knowticed is NOT ported: it needs `file_picker`, and
/// nothing in this app uploads a file yet. Add the dependency and bring it
/// across when something does.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import 'package:asec/core/constants/app_assets.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/custom/32-custom_svg.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/core/theme/haptic_controller.dart';

// ─────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────

/// Rounded dialog shell used by every dialog.
class _DialogShell extends StatelessWidget {
  final Widget child;
  final double? width;

  const _DialogShell({required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 24.h),
      child: Container(
        width: width ?? 420.w,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? AppColors.card
              : AppColors.background,
          borderRadius: AppRadius.containerR,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.totalBlack.withOpacity(0.08),
              blurRadius: 20.sp,
              offset: const Offset(-3, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: AppPadding.h, vertical: 16.r),
        child: child,
      ),
    );
  }
}

/// Brand primary button (#FFDE59).
Widget _primaryBtn({
  required String label,
  required VoidCallback onTap,
  double? width,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 36.sp,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.containerR,
        ),
        child: Center(
          child: Text(
            label,
            style: StyleText.fontSize14Weight500
                .copyWith(color: AppColors.textButton),
          ),
        ),
      ),
    ),
  );
}

/// Neutral secondary button.
Widget _secondaryBtn({
  required String label,
  required VoidCallback onTap,
  double? width,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 36.sp,
        decoration: BoxDecoration(
          color: AppColors.greyDark,
          borderRadius: AppRadius.containerR,
        ),
        child: Center(
          child: Text(
            label,
            style:
                StyleText.fontSize14Weight500.copyWith(color: AppColors.text),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  1.  CONFIRM DIALOG
// ─────────────────────────────────────────────
///
/// ```dart
/// showConfirmDialog(
///   context: context,
///   title: 'Cancel #A4K7QP?',
///   subtitle: 'The customer will see this order as cancelled.',
///   onConfirm: () => cubit.cancel(order),
/// );
/// ```
Future<void> showConfirmDialog({
  required BuildContext context,
  String title = 'Confirm',
  String subtitle = 'Are you sure you want to proceed?',
  String confirmLabel = 'Yes',
  String cancelLabel = 'No',
  VoidCallback? onConfirm,
  VoidCallback? onCancel,

  /// Optional custom Lottie path. Defaults to the confirmation animation.
  String? lottieAsset,

  /// Whether the Lottie animation loops. Defaults to true.
  bool repeat = true,

  /// Fallback widget if you want to bypass Lottie entirely.
  Widget? iconWidget,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.totalBlack.withOpacity(0.4),
    builder: (_) => _ConfirmDialog(
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      onCancel: onCancel,
      lottieAsset: lottieAsset,
      repeat: repeat,
      iconWidget: iconWidget,
    ),
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final String? lottieAsset;
  final bool repeat;
  final Widget? iconWidget;

  const _ConfirmDialog({
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.lottieAsset,
    this.repeat = true,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 411.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 8.h),
          _buildIcon(),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: StyleText.fontSize12Weight400.copyWith(
              color: AppColors.text.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: <Widget>[
              Expanded(
                child: _secondaryBtn(
                  label: cancelLabel,
                  onTap: () {
                    HapticController.low();
                    Navigator.of(context).pop();
                    onCancel?.call();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _primaryBtn(
                  label: confirmLabel,
                  onTap: () {
                    HapticController.high();
                    Navigator.of(context).pop();
                    onConfirm?.call();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    if (iconWidget != null) return iconWidget!;
    return Lottie.asset(
      lottieAsset ?? AppAssets.lottieConfirmation,
      width: 90.r,
      height: 90.r,
      repeat: repeat,
    );
  }
}

// ─────────────────────────────────────────────
//  2.  SUCCESS DIALOG
// ─────────────────────────────────────────────
Future<void> showSuccessDialog({
  required BuildContext context,
  String title = 'Success',
  String subtitle = 'Operation completed successfully.',
  String closeLabel = 'Close',
  VoidCallback? onClose,
  String? lottieAsset,

  /// Plays once by default — a looping tick reads as "still working".
  bool repeat = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.totalBlack.withOpacity(0.4),
    builder: (_) => _SuccessDialog(
      title: title,
      subtitle: subtitle,
      closeLabel: closeLabel,
      onClose: onClose,
      lottieAsset: lottieAsset,
      repeat: repeat,
    ),
  ).then((_) => onClose?.call());
}

class _SuccessDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String closeLabel;
  final VoidCallback? onClose;
  final String? lottieAsset;
  final bool repeat;

  const _SuccessDialog({
    required this.title,
    required this.subtitle,
    required this.closeLabel,
    this.onClose,
    this.lottieAsset,
    this.repeat = false,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 410.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 16.h),
          Lottie.asset(
            lottieAsset ?? AppAssets.lottieSuccess,
            width: 90.r,
            height: 90.r,
            repeat: repeat,
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: StyleText.fontSize12Weight400.copyWith(
              color: AppColors.text.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  2b. ERROR / WARNING DIALOG
// ─────────────────────────────────────────────
///
/// The failure-side counterpart to [showSuccessDialog]. Success dismisses on a
/// barrier tap because nothing is required of the user; this one renders an
/// explicit Close for the same reason in reverse.
Future<void> showErrorDialog({
  required BuildContext context,
  String title = 'Something Went Wrong',
  String subtitle = 'The action could not be completed.',
  String closeLabel = 'Close',
  VoidCallback? onClose,
  String? lottieAsset,
  bool repeat = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.totalBlack.withOpacity(0.4),
    builder: (_) => _MessageDialog(
      title: title,
      subtitle: subtitle,
      closeLabel: closeLabel,
      onClose: onClose,
      lottieAsset: lottieAsset ?? AppAssets.lottieError,
      repeat: repeat,
    ),
  );
}

/// Same shell with the attention animation, for the "you cannot continue yet"
/// guards that are not errors — nothing broke, the form is simply incomplete.
Future<void> showWarningDialog({
  required BuildContext context,
  String title = 'Missing Information',
  String subtitle = 'Complete the highlighted fields to continue.',
  String closeLabel = 'Close',
  VoidCallback? onClose,
  String? lottieAsset,
  bool repeat = false,
}) {
  return showErrorDialog(
    context: context,
    title: title,
    subtitle: subtitle,
    closeLabel: closeLabel,
    onClose: onClose,
    lottieAsset: lottieAsset ?? AppAssets.lottieWarning,
    repeat: repeat,
  );
}

class _MessageDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String closeLabel;
  final VoidCallback? onClose;
  final String lottieAsset;
  final bool repeat;

  const _MessageDialog({
    required this.title,
    required this.subtitle,
    required this.closeLabel,
    required this.lottieAsset,
    this.onClose,
    this.repeat = false,
  });

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 410.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(height: 16.h),
          Lottie.asset(
            lottieAsset,
            width: 90.r,
            height: 90.r,
            repeat: repeat,
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                StyleText.fontSize16Weight600.copyWith(color: AppColors.text),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: StyleText.fontSize12Weight400.copyWith(
              color: AppColors.text.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 16.h),
          _primaryBtn(
            label: closeLabel,
            width: 140.w,
            onTap: () {
              HapticController.high();
              Navigator.of(context).pop();
              onClose?.call();
            },
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  3.  COMMENT / JUSTIFICATION DIALOG
// ─────────────────────────────────────────────
///
/// ```dart
/// showCommentDialog(
///   context: context,
///   title: 'Reason for cancellation',
///   fieldLabel: 'Justification',
///   onSubmit: (String text) { /* use text */ },
/// );
/// ```
Future<void> showCommentDialog({
  required BuildContext context,
  String title = 'Comment',
  String fieldLabel = 'Justification',
  String hint = 'Text here',
  String submitLabel = 'Submit',
  int maxLength = 500,
  TextDirection textDirection = TextDirection.ltr,

  /// SVG asset for the title badge.
  String? titleIconAsset,
  void Function(String comment)? onSubmit,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.totalBlack.withOpacity(0.4),
    builder: (_) => _CommentDialog(
      title: title,
      fieldLabel: fieldLabel,
      hint: hint,
      submitLabel: submitLabel,
      maxLength: maxLength,
      textDirection: textDirection,
      titleIconAsset: titleIconAsset,
      onSubmit: onSubmit,
    ),
  );
}

class _CommentDialog extends StatefulWidget {
  final String title;
  final String fieldLabel;
  final String hint;
  final String submitLabel;
  final int maxLength;
  final TextDirection textDirection;
  final String? titleIconAsset;
  final void Function(String)? onSubmit;

  const _CommentDialog({
    required this.title,
    required this.fieldLabel,
    required this.hint,
    required this.submitLabel,
    required this.maxLength,
    required this.textDirection,
    this.titleIconAsset,
    this.onSubmit,
  });

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _submitted = true);
    if (_controller.text.trim().isEmpty) return;
    HapticController.medium();
    Navigator.of(context).pop();
    widget.onSubmit?.call(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 539.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _TitleIcon(assetPath: widget.titleIconAsset),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  widget.title,
                  style: StyleText.fontSize14Weight600
                      .copyWith(color: AppColors.text),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: widget.fieldLabel,
            hint: widget.hint,
            controller: _controller,
            maxLines: 5,
            fillColor: AppColors.card,
            maxLength: widget.maxLength,
            required: _submitted,
            textDirection: widget.textDirection,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerRight,
            child: _primaryBtn(
              label: widget.submitLabel,
              onTap: _handleSubmit,
              width: 120.w,
            ),
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  4.  SINGLE-FIELD INPUT DIALOG
// ─────────────────────────────────────────────
///
/// One field and a confirm — the password re-prompt before enabling biometric
/// sign-in, and anything else shaped like it. Resolves to the trimmed text, or
/// null if the user backed out.
///
/// This exists so no screen has to reach for Material's `AlertDialog`, which
/// is the one piece of stock chrome that was still leaking into the app.
Future<String?> showInputDialog({
  required BuildContext context,
  String title = 'Confirm',
  String subtitle = '',
  String fieldLabel = '',
  String hint = '',
  String submitLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool obscureText = false,
  String? titleIconAsset,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: AppColors.totalBlack.withOpacity(0.4),
    builder: (_) => _InputDialog(
      title: title,
      subtitle: subtitle,
      fieldLabel: fieldLabel,
      hint: hint,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
      obscureText: obscureText,
      titleIconAsset: titleIconAsset,
    ),
  );
}

class _InputDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String fieldLabel;
  final String hint;
  final String submitLabel;
  final String cancelLabel;
  final bool obscureText;
  final String? titleIconAsset;

  const _InputDialog({
    required this.title,
    required this.subtitle,
    required this.fieldLabel,
    required this.hint,
    required this.submitLabel,
    required this.cancelLabel,
    required this.obscureText,
    this.titleIconAsset,
  });

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    setState(() => _submitted = true);
    if (_controller.text.trim().isEmpty) return;
    HapticController.medium();
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 430.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _TitleIcon(assetPath: widget.titleIconAsset ?? AppAssets.lock),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  widget.title,
                  style: StyleText.fontSize14Weight600
                      .copyWith(color: AppColors.text),
                ),
              ),
            ],
          ),
          if (widget.subtitle.isNotEmpty) ...<Widget>[
            SizedBox(height: 8.h),
            Text(
              widget.subtitle,
              style: StyleText.fontSize12Weight400.copyWith(
                color: AppColors.text.withOpacity(0.6),
              ),
            ),
          ],
          SizedBox(height: 16.h),
          CustomTextField(
            label: widget.fieldLabel.isEmpty ? null : widget.fieldLabel,
            hint: widget.hint,
            controller: _controller,
            obscureText: widget.obscureText,
            fillColor: AppColors.card,
            required: _submitted,
            // Enter submits. A one-field dialog that needs the mouse to
            // confirm is a dialog people fight with.
            onSubmitted: (_) => _handleSubmit(),
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: 16.h),
          Row(
            children: <Widget>[
              Expanded(
                child: _secondaryBtn(
                  label: widget.cancelLabel,
                  onTap: () {
                    HapticController.low();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _primaryBtn(
                  label: widget.submitLabel,
                  onTap: _handleSubmit,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED: Title row badge
// ─────────────────────────────────────────────
class _TitleIcon extends StatelessWidget {
  final String? assetPath;

  const _TitleIcon({this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.r,
      height: 30.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: CustomSvgImage(
        assetPath: assetPath ?? AppAssets.note,
        width: 18.r,
        height: 18.r,
        fit: BoxFit.scaleDown,
        color: AppColors.textButton,
      ),
    );
  }
}
