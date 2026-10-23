/// Module: user / u1_shell
///
///*************************** FILE INFO ****************************///
/// File Name: access_gate.dart
/// Purpose: Declares `AccessGate` — between a member and their app: paused,
///          not started yet, ended, or the wrong device each gets a screen
///          that says why, with a sign-out button. Re-checked every 30
///          seconds, so an access period that ends while the app is open
///          closes it, and live, so the admin's Pause takes effect at once.
/// Author: ASEC team
/// Created: 1/10/2026
/// Updated: 23/10/2026 - No more one-device lock and no platform screen:
///          members sign in on any device / platform. Paused, dates and
///          a device the admin blocked still apply.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/5-custom_button.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/admin/a2_members/data/device_security.dart';
import 'package:asec/features/onboarding/o1_splash/presentation/ui/pages/splash_screen.dart';
import 'package:asec/features/onboarding/o2_authentication/data/device/device_identity.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/member_access.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/ui/widgets/brand_mark.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class AccessGate extends StatefulWidget {
  const AccessGate({super.key, required this.user, required this.child});

  final AppUser user;
  final Widget child;

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> {
  Timer? _tick;

  /// The admin blocked THIS device (`blocked_devices/{DeviceIdentity.id}`).
  /// Null until the first answer.
  bool? _blocked;
  StreamSubscription<bool>? _blockSub;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    if (widget.user.isAdmin) {
      _blocked = false;
    } else {
      _blockSub = DeviceBlocks.watchThisDevice().listen((bool b) {
        if (!mounted) return;
        setState(() => _blocked = b);
      }, onError: (Object _) {
        if (!mounted || _blocked != null) return;
        setState(() => _blocked = false);
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _blockSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AccessBlock block = MemberAccess.check(
      widget.user,
      thisDevice: DeviceIdentity.id,
      boundHereUid: DeviceIdentity.boundUid,
    );
    if (_blocked == true && !widget.user.isAdmin) {
      return _BlockedView(user: widget.user, block: AccessBlock.deviceBlocked);
    }
    if (block == AccessBlock.none) return widget.child;
    return _BlockedView(user: widget.user, block: block);
  }
}

/// The "you can't use the app right now" screen. Clean and calm: a solid
/// brand panel with the logo (beside the content on desktop, a rounded
/// header on a phone), and one white card with the reason, a short list of
/// the facts behind it, and Sign out.
class _BlockedView extends StatelessWidget {
  const _BlockedView({required this.user, required this.block});

  final AppUser user;
  final AccessBlock block;

  static IconData _platformIcon(String p) {
    switch (p) {
      case 'android':
        return Icons.android_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      case 'macos':
        return Icons.laptop_mac_rounded;
      case 'windows':
        return Icons.desktop_windows_rounded;
      default:
        return Icons.devices_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final (IconData icon, Color accent, String title, String body) = switch (block) {
      AccessBlock.paused => (
          Icons.pause_rounded,
          AppColors.statusPending,
          s.blockedTitlePaused,
          s.blockedBodyPaused,
        ),
      AccessBlock.notStarted => (
          Icons.schedule_rounded,
          AppColors.primary,
          s.blockedTitleNotStarted,
          s.blockedBodyNotStarted(AppDates.day(context, user.accessFrom)),
        ),
      AccessBlock.expired => (
          Icons.event_busy_rounded,
          AppColors.red,
          s.blockedTitleExpired,
          s.blockedBodyExpired(AppDates.day(context, user.accessUntil)),
        ),
      AccessBlock.platform => (
          Icons.devices_other_rounded,
          AppColors.red,
          s.blockedTitlePlatform,
          s.accessPlatformsCaption,
        ),
      AccessBlock.otherDevice => (
          Icons.phonelink_lock_rounded,
          AppColors.red,
          s.blockedTitleOtherDevice,
          s.blockedBodyOtherDevice,
        ),
      AccessBlock.deviceRemoved => (
          Icons.phonelink_erase_rounded,
          AppColors.statusPending,
          s.blockedTitleDeviceRemoved,
          s.blockedBodyDeviceRemoved,
        ),
      AccessBlock.deviceBlocked => (
          Icons.block_rounded,
          AppColors.red,
          s.blockedTitleDeviceBlocked,
          s.blockedBodyDeviceBlocked,
        ),
      AccessBlock.none => (Icons.check_rounded, AppColors.green, '', ''),
    };

    final List<_Fact> facts = <_Fact>[
      _Fact(Icons.person_rounded, s.tbMember, user.displayName),
      if (block == AccessBlock.platform) ...<_Fact>[
        _Fact(
          _platformIcon(MemberAccess.currentPlatform),
          s.tbThisDevice,
          MemberAccess.platformLabel(MemberAccess.currentPlatform),
          highlight: true,
        ),
        _Fact(
          Icons.verified_user_rounded,
          s.tbAllowedOn,
          (user.platforms.isEmpty ? MemberAccess.defaultPlatforms : user.platforms)
              .map(MemberAccess.platformLabel)
              .join('، '),
        ),
      ],
      if (block == AccessBlock.otherDevice)
        _Fact(Icons.devices_rounded, s.tbAccountDevice, user.deviceName, highlight: true),
      if (block == AccessBlock.paused)
        _Fact(Icons.pause_circle_outline_rounded, s.tbStatus,
            s.accessPausedSince(AppDates.day(context, user.pausedAt))),
      if (block == AccessBlock.expired || block == AccessBlock.notStarted) ...<_Fact>[
        _Fact(Icons.play_circle_outline_rounded, s.tbStarts, AppDates.day(context, user.accessFrom),
            highlight: block == AccessBlock.notStarted),
        _Fact(Icons.event_rounded, s.tbEnds, AppDates.day(context, user.accessUntil),
            highlight: block == AccessBlock.expired),
      ],
    ];

    final Widget card = _Card(
      icon: icon,
      accent: accent,
      title: title,
      body: body,
      facts: facts,
      onSignOut: () => AppRouter.signOut(context),
      signOutLabel: s.signOut,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) {
          if (c.maxWidth >= 900) {
            // DESKTOP: brand panel on one side, the card centred on the other.
            return Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: ColoredBox(
                    color: AppColors.primary,
                    child: const Center(
                      child: BrandMark(size: 72, vertical: true, onDark: true),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: card,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          // PHONE: a rounded brand header, the card rising over its edge.
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 230,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
                  ),
                  child: const SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Center(
                        child: BrandMark(size: 56, vertical: true, onDark: true),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -44),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: card,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Fact {
  const _Fact(this.icon, this.label, this.value, {this.highlight = false});

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
    required this.facts,
    required this.onSignOut,
    required this.signOutLabel,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String body;
  final List<_Fact> facts;
  final VoidCallback onSignOut;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: accent),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            FormatHelper.capitalize(title),
            style: StyleText.fontSize24Weight600.copyWith(color: AppColors.text, height: 1.25),
          ),
          const SizedBox(height: 8),
          Text(
            FormatHelper.capitalize(body),
            style: StyleText.fontSize14Weight400.copyWith(color: AppColors.secondaryText, height: 1.6),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < facts.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            facts[i].icon,
                            size: 18,
                            color: facts[i].highlight ? accent : AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                FormatHelper.capitalize(facts[i].label),
                                style: StyleText.fontSize12Weight400.copyWith(color: AppColors.secondaryText),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                FormatHelper.capitalize(facts[i].value),
                                style: StyleText.fontSize14Weight600.copyWith(
                                  color: facts[i].highlight ? accent : AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          customButton(title: signOutLabel, function: onSignOut, fullWidth: true),
        ],
      ),
    );
  }
}
