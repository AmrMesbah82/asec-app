/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: 111-app_svg_icon.dart
/// Purpose: `AppIcon` — the app's drop-in replacement for Flutter's `Icon`.
///          It draws the matching SVG from `assets/icons_assets/` (tinted
///          with the icon colour, no background) and only falls back to the
///          Material glyph when no SVG has been mapped for that icon.
/// Author: Manger Plus team
/// Created: 18/9/2026
///
/// TO SWAP AN ICON: change its path in [AppSvgIcons._map]. To give a new
/// Material icon an SVG, add a line there — every screen picks it up.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcons {
  AppSvgIcons._();

  static const String _main = 'assets/icons_assets/main_icons_assets/';
  static const String _crm = 'assets/icons_assets/crm_icons_assets/';
  static const String _form = 'assets/icons_assets/form_builder_assets/';
  static const String _home = 'assets/icons_assets/home_assets/';
  static const String _msg = 'assets/icons_assets/messaging_assets/';
  static const String _roles = 'assets/icons_assets/roles_assets/';
  static const String _settings = 'assets/icons_assets/settings_assets/';

  static final Map<IconData, String> _map = <IconData, String>{
    // Checks & status
    Icons.check_rounded: '${_crm}check_box_filed.svg',
    Icons.check_circle_rounded: '${_crm}check_box_filed.svg',
    Icons.done_all_rounded: '${_form}select_all_group_check.svg',
    Icons.verified_user_rounded: '${_main}approval_badge_check.svg',
    Icons.close_rounded: '${_msg}vectors_close.svg',
    Icons.cancel_rounded: '${_msg}vectors_close.svg',
    Icons.remove_circle_outline: '${_main}cancel_minus_circle.svg',
    Icons.error_outline_rounded: '${_main}warning_triangle_red.svg',
    Icons.info_outline_rounded: '${_crm}how-it-work.svg',
    Icons.pending_actions_rounded: '${_home}hourglass_pending.svg',
    Icons.radio_button_unchecked_rounded: '${_form}radio_circle_empty.svg',
    Icons.rule_rounded: '${_main}bullet_list.svg',
    // Navigation
    Icons.chevron_right_rounded: '${_main}chevron_right.svg',
    Icons.chevron_left_rounded: '${_main}chevron_left.svg',
    Icons.keyboard_arrow_down_rounded: '${_main}chevron_down.svg',
    Icons.arrow_back_rounded: '${_main}mobile_arrow_back.svg',
    Icons.arrow_forward_rounded: '${_main}vectors_arrowForward.svg',
    Icons.open_in_new_rounded: '${_main}export_arrow.svg',
    Icons.home_rounded: '${_roles}home.svg',
    Icons.home_outlined: '${_roles}home.svg',
    Icons.settings_rounded: '${_roles}settings_gear.svg',
    Icons.settings_outlined: '${_roles}settings_gear.svg',
    Icons.logout_rounded: '${_main}logout_door_arrow.svg',
    Icons.power_settings_new_rounded: '${_home}logout_arrow.svg',
    Icons.search: '${_main}search_magnifier_alt.svg',
    Icons.filter_alt_outlined: '${_main}filter_sliders.svg',
    // Actions
    Icons.add_rounded: '${_main}plus.svg',
    Icons.edit_outlined: '${_main}assets_edit.svg',
    Icons.edit_rounded: '${_main}assets_edit.svg',
    Icons.edit_note_rounded: '${_main}edit_pencil_square.svg',
    Icons.delete_outline_rounded: '${_crm}trush.svg',
    Icons.delete_sweep_outlined: '${_form}delete_trash_red.svg',
    Icons.send_rounded: '${_msg}vectors_send.svg',
    Icons.cloud_upload_outlined: '${_main}cloud_upload.svg',
    // People
    Icons.person_outline_rounded: '${_main}person_outline.svg',
    Icons.person_rounded: '${_main}person_outline.svg',
    Icons.groups_2_rounded: '${_main}users_group_three.svg',
    Icons.groups_2_outlined: '${_main}users_group_three.svg',
    Icons.family_restroom_rounded: '${_msg}people.svg',
    Icons.family_restroom_outlined: '${_msg}people.svg',
    Icons.co_present_outlined: '${_settings}bio_person_spotlight.svg',
    Icons.co_present_rounded: '${_settings}bio_person_spotlight.svg',
    Icons.admin_panel_settings_outlined: '${_roles}roles_people_gear.svg',
    Icons.school_rounded: '${_main}graduation_cap.svg',
    Icons.school_outlined: '${_main}graduation_cap.svg',
    Icons.backpack_rounded: '${_settings}academic_history_graduation.svg',
    Icons.backpack_outlined: '${_settings}academic_history_graduation.svg',
    // Time
    Icons.event_rounded: '${_main}images_Calendar.svg',
    Icons.event_outlined: '${_main}images_Calendar.svg',
    Icons.schedule_rounded: '${_main}clock_circle.svg',
    Icons.timer_outlined: '${_roles}time_tracking_dashed_clock.svg',
    Icons.fact_check_outlined: '${_main}calendar_attendance_marks.svg',
    Icons.fact_check_rounded: '${_main}calendar_attendance_marks.svg',
    // Content & media
    Icons.video_library_rounded: '${_main}knowledgeVideo.svg',
    Icons.video_library_outlined: '${_main}knowledgeVideo.svg',
    Icons.play_circle_fill_rounded: '${_main}knowledgeVideo.svg',
    Icons.play_circle_outline_rounded: '${_msg}play.svg',
    Icons.play_circle_outline: '${_msg}play.svg',
    Icons.play_arrow_rounded: '${_msg}play.svg',
    Icons.pause_circle_outline: '${_msg}pause.svg',
    Icons.pause_circle_filled_rounded: '${_msg}pause.svg',
    Icons.picture_as_pdf_rounded: '${_main}assets_pdf.svg',
    Icons.picture_as_pdf_outlined: '${_main}assets_pdf.svg',
    Icons.photo_rounded: '${_main}image_photo_rounded.svg',
    Icons.image_outlined: '${_main}image_photo_rounded.svg',
    Icons.broken_image_outlined: '${_main}image_placeholder_large.svg',
    Icons.assignment_outlined: '${_form}summary_document_list.svg',
    Icons.assignment_rounded: '${_form}summary_document_list.svg',
    Icons.quiz_outlined: '${_main}approval_badge_check.svg',
    Icons.bolt_rounded: '${_main}approval_badge_check.svg',
    Icons.format_quote_rounded: '${_home}quotation_marks.svg',
    // Insights & grades
    Icons.insights_rounded: '${_home}analytics_charts.svg',
    Icons.insights_outlined: '${_home}analytics_charts.svg',
    Icons.grade_rounded: '${_msg}vectors_star.svg',
    Icons.grade_outlined: '${_msg}vectors_star.svg',
    Icons.star_outline_rounded: '${_msg}vectors_star.svg',
    // Messages & contact
    Icons.chat_bubble_outline_rounded: '${_main}chat_bubble_dots.svg',
    Icons.chat_bubble_rounded: '${_main}chat_bubble_dots.svg',
    Icons.alternate_email_rounded: '${_main}email_envelope.svg',
    Icons.phone_iphone_rounded: '${_main}phone_number.svg',
    // Settings
    Icons.translate_rounded: '${_settings}language_translate_bubbles.svg',
    Icons.light_mode_rounded: '${_home}picker_light_mode.svg',
    Icons.dark_mode_rounded: '${_home}picker_dark_mode.svg',
    Icons.vibration_rounded: '${_settings}haptic_vibration_phone.svg',
    Icons.lock_outline_rounded: '${_home}user_access_lock.svg',
    Icons.desktop_mac_rounded: '${_main}employee_desk_computer.svg',
  };

  /// The SVG mapped to [icon], or null to keep the Material glyph.
  static String? assetFor(IconData? icon) => icon == null ? null : _map[icon];
}

/// Same constructor as `Icon`, so `Icon(...)` -> `AppIcon(...)` is a rename.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final IconThemeData theme = IconTheme.of(context);
    final double box = size ?? theme.size ?? 24;
    Color? ink = color ?? theme.color;
    if (color == null && ink != null && theme.opacity != null && theme.opacity! < 1) {
      ink = ink.withOpacity(ink.opacity * theme.opacity!);
    }

    final String? asset = AppSvgIcons.assetFor(icon);
    if (asset == null) {
      return Icon(icon, size: box, color: ink, semanticLabel: semanticLabel);
    }

    // Material glyphs leave ~2px of air inside their 24px box; the SVGs are
    // drawn edge to edge, so they are inset to the same visual weight.
    final double glyph = box * 0.84;
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: SvgPicture.asset(
          asset,
          width: glyph,
          height: glyph,
          semanticsLabel: semanticLabel,
          colorFilter:
              ink == null ? null : ColorFilter.mode(ink, BlendMode.srcIn),
        ),
      ),
    );
  }
}
