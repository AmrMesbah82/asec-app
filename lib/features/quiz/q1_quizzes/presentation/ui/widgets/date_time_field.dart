/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: date_time_field.dart
/// Purpose: Declares `DateTimeField` — pick (or clear) one end of a quiz's
///          open window.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_radius.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/generated/l10n.dart';

/// A tappable field that opens the date picker and then the time picker.
/// Null is a first-class value here — "no bound that way" — so the field
/// always offers a way back to it.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.event_rounded,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final IconData icon;

  Future<void> _pick(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initial = value ?? now;

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial,
      // A window may legitimately be set in the past (a quiz that has closed),
      // so the range is wide on both sides rather than starting at today.
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !context.mounted) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!context.mounted) return;

    onChanged(DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final bool isSet = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: StyleText.fontSize13Weight600
              .copyWith(color: AppColors.secondaryText),
        ),
        SizedBox(height: 6.h),
        Material(
          color: AppColors.field,
          borderRadius: AppRadius.fieldR,
          child: InkWell(
            borderRadius: AppRadius.fieldR,
            onTap: () => _pick(context),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
              child: Row(
                children: <Widget>[
                  AppIcon(icon, size: 18.sp, color: AppColors.secondaryText),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      isSet ? AppDates.dateTime(context, value) : s.notSet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSet
                          ? StyleText.fontSize14Weight500
                          : StyleText.fontSize14Weight400
                              .copyWith(color: AppColors.secondaryText),
                    ),
                  ),
                  if (isSet)
                    InkWell(
                      onTap: () => onChanged(null),
                      borderRadius: AppRadius.buttonR,
                      child: Padding(
                        padding: EdgeInsets.all(4.r),
                        child: AppIcon(
                          Icons.close_rounded,
                          size: 16.sp,
                          color: AppColors.secondaryText,
                          semanticLabel: s.clearDate,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
