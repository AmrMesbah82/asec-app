/// Module: core
///
///*************************** FILE INFO ****************************///
/// File Name: app_assets.dart
/// Purpose: Declares `AppAssets` — the single source of truth for every asset
///          path the app loads.
/// Author: Manger Plus team
/// Created: 3/9/2026
///
/// WHY THIS EXISTS
/// ---------------
/// The console used to draw Material `Icon()` glyphs. It now draws the SVGs
/// vendored under `assets/`, exactly the way knowticed_plus does, so the two
/// apps share one visual vocabulary and one weight of line.
///
/// RULES
/// -----
///  * Nothing outside this file writes an `assets/...` string literal. A typo
///    in a literal is a silent grey box at runtime; a typo here is one place.
///  * Every constant below points at a file that EXISTS on disk and at a folder
///    declared in `pubspec.yaml`. Both were checked against the asset tree on
///    3/9/2026 — if you add one, check it the same way.
///  * SVGs are rendered through `CustomSvgImage` (32-custom_svg.dart), never
///    through `SvgPicture` directly, so tinting and sizing stay consistent.
///
/// A NOTE ON THE MAPPING
/// ---------------------
/// The vendored library is the knowticed icon set: it has no washing machine,
/// no iron and no delivery van. Each laundry concept below is therefore mapped
/// to the closest existing glyph, and grouped so a swap is a one-line edit once
/// purpose-drawn artwork arrives.
abstract class AppAssets {
  // ─────────────────────────── BRAND ────────────────────────────────────────
  static const String logo =
      'assets/icons_assets/main_icons_assets/logo_app.svg';
  static const String logoAlt =
      'assets/icons_assets/main_icons_assets/logo_app_2.svg';
  static const String appIcon =
      'assets/icons_assets/main_icons_assets/light_app_icon.svg';
  static const String splash =
      'assets/icons_assets/main_icons_assets/assets_splash.gif';
  static const String splashDark =
      'assets/icons_assets/main_icons_assets/assets_splash_dark.gif';

  // ──────────────────── CONSOLE SECTIONS (left rail) ────────────────────────
  static const String sectionOverview =
      'assets/icons_assets/home_assets/analytics_charts.svg';
  static const String sectionOrders =
      'assets/icons_assets/home_assets/service_requests_document.svg';
  static const String sectionClothes =
      'assets/icons_assets/home_assets/inventory_products_box.svg';
  static const String sectionOptions =
      'assets/icons_assets/crm_icons_assets/services.svg';
  static const String sectionCustomers =
      'assets/icons_assets/crm_icons_assets/clients.svg';
  static const String sectionSettings =
      'assets/icons_assets/roles_assets/settings_gear.svg';

  // ───────────────────────── TOOLBAR / ACTIONS ──────────────────────────────
  static const String search =
      'assets/icons_assets/main_icons_assets/search_magnifier_alt.svg';
  static const String filter =
      'assets/icons_assets/main_icons_assets/filter_sliders.svg';
  static const String sort =
      'assets/icons_assets/main_icons_assets/sort_lines.svg';
  static const String grid =
      'assets/icons_assets/main_icons_assets/grid_four_squares.svg';
  static const String listView =
      'assets/icons_assets/main_icons_assets/bullet_list.svg';
  static const String add = 'assets/icons_assets/main_icons_assets/plus.svg';
  static const String edit =
      'assets/icons_assets/main_icons_assets/edit_pencil_square.svg';
  static const String delete =
      'assets/icons_assets/form_builder_assets/delete_trash_red.svg';
  static const String more =
      'assets/icons_assets/main_icons_assets/vectors_more.svg';
  static const String close =
      'assets/icons_assets/form_builder_assets/close_circle_red.svg';
  static const String cancel =
      'assets/icons_assets/main_icons_assets/cancel_minus_circle.svg';

  /// The console's "reload this page" control. `undo` is a circular arrow —
  /// the nearest thing the library has to a refresh glyph.
  static const String refresh =
      'assets/icons_assets/crm_icons_assets/undo.svg';

  static const String export =
      'assets/icons_assets/main_icons_assets/export_arrow.svg';
  static const String download =
      'assets/icons_assets/form_builder_assets/download_arrow.svg';
  static const String upload =
      'assets/icons_assets/form_builder_assets/upload_arrow.svg';
  static const String save =
      'assets/icons_assets/main_icons_assets/assets_save.svg';
  static const String menu =
      'assets/icons_assets/roles_assets/menu_lines_bold.svg';
  static const String logout =
      'assets/icons_assets/main_icons_assets/logout_door_arrow.svg';
  static const String notification =
      'assets/icons_assets/main_icons_assets/notification_bell.svg';
  static const String notificationBadge =
      'assets/icons_assets/main_icons_assets/notification_bell_badge_yellow.svg';

  // ───────────────────────────── CHEVRONS ───────────────────────────────────
  static const String chevronDown =
      'assets/icons_assets/main_icons_assets/chevron_down.svg';
  static const String chevronLeft =
      'assets/icons_assets/main_icons_assets/chevron_left.svg';
  static const String chevronRight =
      'assets/icons_assets/main_icons_assets/chevron_right.svg';
  static const String arrowBack =
      'assets/icons_assets/main_icons_assets/mobile_arrow_back.svg';
  static const String arrowForward =
      'assets/icons_assets/main_icons_assets/vectors_arrowForward.svg';

  // ───────────────────────── OVERVIEW METRICS ───────────────────────────────
  static const String metricRevenue =
      'assets/icons_assets/crm_icons_assets/price.svg';
  static const String metricOrders =
      'assets/icons_assets/crm_icons_assets/deals.svg';
  static const String metricCustomers =
      'assets/icons_assets/crm_icons_assets/clients.svg';
  static const String metricAverage =
      'assets/icons_assets/crm_icons_assets/chart-line-solid.svg';
  static const String metricDiscount =
      'assets/icons_assets/crm_icons_assets/discount.svg';
  static const String metricTax = 'assets/icons_assets/crm_icons_assets/tax.svg';

  // ───────────────────────── RECORD FIELDS ──────────────────────────────────
  static const String person =
      'assets/icons_assets/main_icons_assets/person_outline.svg';
  static const String people =
      'assets/icons_assets/main_icons_assets/users_group_three.svg';
  static const String email =
      'assets/icons_assets/main_icons_assets/email_envelope.svg';
  static const String phone =
      'assets/icons_assets/services_assets/phone_handset.svg';
  static const String location =
      'assets/icons_assets/form_builder_assets/location_pin.svg';
  static const String calendar = 'assets/icons_assets/roles_assets/calendar.svg';
  static const String clock =
      'assets/icons_assets/main_icons_assets/clock_circle.svg';
  static const String category =
      'assets/icons_assets/crm_icons_assets/category_icon.svg';
  static const String status = 'assets/icons_assets/crm_icons_assets/status.svg';
  static const String note =
      'assets/icons_assets/form_builder_assets/description_text_lines.svg';
  static const String history =
      'assets/icons_assets/crm_icons_assets/history.svg';
  static const String lock =
      'assets/icons_assets/main_icons_assets/password-protection.svg';

  // ─────────────────────────── FEEDBACK ─────────────────────────────────────
  static const String info = 'assets/icons_assets/crm_icons_assets/info.svg';
  static const String success =
      'assets/icons_assets/main_icons_assets/check_circle_green.svg';
  static const String warning =
      'assets/icons_assets/main_icons_assets/warning_triangle_red.svg';
  static const String warningCircle =
      'assets/icons_assets/main_icons_assets/warning_exclamation_circle.svg';
  static const String rejected =
      'assets/icons_assets/main_icons_assets/status_rejected_stamp_red.svg';

  // ──────────────────────────── SETTINGS ────────────────────────────────────
  static const String settingsDarkMode =
      'assets/icons_assets/settings_assets/dark_mode_toggle_moon.svg';
  static const String settingsLightMode =
      'assets/icons_assets/home_assets/picker_light_mode.svg';
  static const String settingsLanguage =
      'assets/icons_assets/settings_assets/language_translate_bubbles.svg';
  static const String settingsHaptics =
      'assets/icons_assets/settings_assets/haptic_vibration_phone.svg';
  static const String settingsBiometrics =
      'assets/icons_assets/settings_assets/biometrics_auth.svg';
  static const String settingsBranding =
      'assets/icons_assets/settings_assets/branding_theme_badge.svg';
  static const String settingsAbout =
      'assets/icons_assets/settings_assets/about_app_info_book.svg';
  static const String settingsPrivacy =
      'assets/icons_assets/settings_assets/privacy_clipboard_lock.svg';
  static const String settingsTerms =
      'assets/icons_assets/settings_assets/terms_and_conditions_document.svg';
  static const String settingsCompany =
      'assets/icons_assets/settings_assets/company_information_cards.svg';

  // ─────────────────────────── ONBOARDING ───────────────────────────────────
  // The three first-run screens. Unlike everything above these are
  // ILLUSTRATIONS, not glyphs: full-colour, several hundred paths each, and
  // drawn to be looked at rather than tapped. Render them through
  // `CustomSvgImage.natural` with NO colour — tinting one flattens it to a
  // silhouette.
  //
  // Chosen for the story they tell in order — what you are sending, when it is
  // collected, and getting it back — from what the vendored set actually has.
  // Two of them carry a little baked-in English ("CHECKLIST", the "DONE"
  // stamp) that no translation reaches; at the size these render it is
  // texture rather than copy, but it is the first thing to fix the day
  // purpose-drawn laundry artwork arrives.
  static const String onboardingList =
      'assets/icons_assets/onboarding_assets/onboarding_checklist.svg';

  /// Desk calendar, clock and pencil. No people and no readable text, which is
  /// why it beat onboarding_calendar_planning.svg — that one has SUN/MON/TUE
  /// spelled out across it.
  static const String onboardingSchedule =
      'assets/icons_assets/calendar_assets/calendar_desk_illustration.svg';

  static const String onboardingDelivered =
      'assets/icons_assets/crm_icons_assets/successful_svg_dialog.svg';

  // ────────────────────── AVATARS & PLACEHOLDERS ────────────────────────────
  static const String avatarMale =
      'assets/icons_assets/main_icons_assets/male_avatar.svg';
  static const String avatarFemale =
      'assets/icons_assets/main_icons_assets/female_avatar.svg';
  static const String imagePlaceholder =
      'assets/icons_assets/main_icons_assets/image_placeholder_large.svg';
  static const String loginPhoto = 'assets/png_assets/loginPhoto.jpeg';

  // ───────────────────────────── LOTTIE ─────────────────────────────────────
  static const String lottieEmpty =
      'assets/lottie_assets/main_lottie_assets/lottie_empty.json';
  static const String lottieNoData =
      'assets/lottie_assets/main_lottie_assets/lottie_noData.json';
  static const String lottieSuccess =
      'assets/lottie_assets/main_lottie_assets/lottie_successful.json';
  static const String lottieConfirmation =
      'assets/lottie_assets/main_lottie_assets/lottie_confirmation.json';
  static const String lottieAttention =
      'assets/lottie_assets/main_lottie_assets/lottie_attention.json';
  static const String lottieWarning =
      'assets/lottie_assets/main_lottie_assets/lottie_warning.json';
  static const String lottieError =
      'assets/lottie_assets/main_lottie_assets/error.json';
  static const String lottieDelete =
      'assets/lottie_assets/main_lottie_assets/lottie_trash.json';
  static const String lottieLogout =
      'assets/lottie_assets/home_lottie_assets/newLogOut.json';
  static const String lottieNoInternet =
      'assets/lottie_assets/main_lottie_assets/internet.json';

  // ────────────────────────────── DATA ──────────────────────────────────────
  static const String locationData = 'assets/data/location_data.json';

  // ─────────────────────────── LEARNING CENTER ──────────────────────────────
  // Full-colour illustrations — render with `CustomSvgImage.natural`, no tint.
  static const String illustrationLearning =
      'assets/icons_assets/onboarding_assets/onboarding_analytics_presentation.svg';
  static const String illustrationChat =
      'assets/icons_assets/onboarding_assets/onboarding_chat_conversation.svg';
  static const String illustrationChecklist =
      'assets/icons_assets/onboarding_assets/onboarding_checklist.svg';
  static const String illustrationLogin =
      'assets/icons_assets/onboarding_assets/onboarding_secure_login.svg';
  static const String illustrationCalendar =
      'assets/icons_assets/onboarding_assets/onboarding_calendar_planning.svg';
  static const String send =
      'assets/icons_assets/messaging_assets/send_arrow.svg';
}
