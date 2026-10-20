/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: tips_overlay.dart
/// Purpose: Declares `TipsLayer` — the admin's tips & tricks laid over the
///          home page as layers (a stack of cards, one on top of the other),
///          in the primary colour and the full width of the page, while the
///          home page behind fades back.
/// Author: ASEC team
/// Created: 15/10/2026
/// Updated: 16/10/2026 - A layer inside the home page instead of a dialog:
///          home dimmed behind, full-width primary cards, a bookmark icon
///          to save.
///
/// HOW IT BEHAVES
///  * Each tip appears ONCE per member (remembered on the device AND in the
///    tip's `seen_by` in Firestore, so a reinstall or another device does
///    not bring it back): the
///    switched-on tips the member has not seen or saved yet
///    (newest first, five at most) appear as stacked cards.
///  * Tapping ANYWHERE closes the whole stack.
///  * The bookmark icon saves the top tip (it then lives under the bookmark
///    in the app bar, and counts for the admin) and the next layer comes
///    forward; saving the last one closes the stack.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/engagement/e1_engagement/domain/entities/engagement_entities.dart';
import 'package:asec/features/engagement/e1_engagement/presentation/ui/widgets/engagement_widgets.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/generated/l10n.dart';
import 'package:asec/core/helper/main_helper/format_helper.dart';

class TipsLayer extends StatefulWidget {
  const TipsLayer({super.key, required this.user, required this.child});

  final AppUser user;

  /// The home page — dimmed while the tips are up.
  final Widget child;

  @override
  State<TipsLayer> createState() => _TipsLayerState();
}

class _TipsLayerState extends State<TipsLayer> {
  /// Shown at most once per launch, even if the home page is rebuilt.
  static bool _shown = false;

  final EngagementRepository _repository = EngagementRepository();
  List<AppTip> _all = const <AppTip>[];
  List<AppTip> _left = const <AppTip>[];
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AppUser user = widget.user;
    if (_shown || user.isEmpty || user.isAdmin) return;
    _shown = true;
    try {
      // ONCE ONLY: a tip this member has already been shown never comes
      // back, on this device — saved or not.
      final String key = 'tips_seen_${user.uid}';
      final Set<String> seen = <String>{
        ...(GetStorage().read<List<dynamic>>(key) ?? const <dynamic>[])
            .map((dynamic e) => e.toString()),
      };
      final List<AppTip> tips = (await _repository.tipsToShow(user.uid))
          .where((AppTip t) => !seen.contains(t.id))
          .toList();
      if (!mounted || tips.isEmpty) return;
      GetStorage().write(key, <String>[...seen, ...tips.map((AppTip t) => t.id)]);
      // And in Firestore, so a reinstall or another device doesn't show
      // them again either.
      _repository
          .markTipsSeen(tips.map((AppTip t) => t.id), user.uid)
          .catchError((Object _) {});
      setState(() {
        _all = tips;
        _left = List<AppTip>.of(tips);
        _open = true;
      });
    } catch (_) {
      // No tips this time — the home page simply shows as usual.
    }
  }

  void _close() => setState(() => _open = false);

  void _save() {
    if (_left.isEmpty) return;
    final AppTip top = _left.first;
    _repository.saveTip(top.id, widget.user.uid).catchError((Object _) {});
    showEngagementToast(context, S.of(context).engTipSavedToast);
    setState(() {
      _left = _left.sublist(1);
      if (_left.isEmpty) _open = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return Stack(
      children: <Widget>[
        // THE HOME PAGE FADES BACK while the tips are up.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: _open ? 0.18 : 1,
          child: IgnorePointer(ignoring: _open, child: widget.child),
        ),
        if (_open)
          Positioned.fill(
            // Tap anywhere closes the stack. Material gives the texts their
            // theme (no yellow debug underline).
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                // IN THE CENTRE of the screen; scrolls only if a tip is
                // taller than the screen.
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) =>
                      SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(AppPadding.h, 24.h, AppPadding.h, 24.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (c.maxHeight - 48.h).clamp(0.0, double.infinity),
                    ),
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _Layers(
                        left: _left,
                        total: _all.length,
                        onSave: _save,
                      ),
                      SizedBox(height: 18.h),
                      Text(
                        FormatHelper.capitalize(s.engTipTapToClose),
                        textAlign: TextAlign.center,
                        style: StyleText.fontSize12Weight500
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                  ),
                ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The top tip, with the next ones peeking out underneath it.
class _Layers extends StatelessWidget {
  const _Layers({required this.left, required this.total, required this.onSave});

  final List<AppTip> left;
  final int total;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final int behind = (left.length - 1).clamp(0, 2);
    final double peek = 12.h;

    return Padding(
      // Room under the top card for the layers behind it.
      padding: EdgeInsets.only(bottom: peek * behind),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = behind; i >= 1; i--)
            Positioned(
              left: 14.w * i,
              right: 14.w * i,
              top: 0,
              bottom: -peek * i,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.55 - 0.18 * i),
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
            ),
          if (left.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (Widget child, Animation<double> a) =>
                  SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(a),
                child: FadeTransition(opacity: a, child: child),
              ),
              child: _TipCard(
                key: ValueKey<String>(left.first.id),
                tip: left.first,
                index: total - left.length + 1,
                total: total,
                onSave: onSave,
              ),
            ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    super.key,
    required this.tip,
    required this.index,
    required this.total,
    required this.onSave,
  });

  final AppTip tip;
  final int index;
  final int total;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final Color on = AppColors.textButton;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 18.h, 12.w, 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: <Color>[AppColors.primary, AppColors.secondaryPrimary],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: on.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(Icons.lightbulb_rounded, size: 20.sp, color: on),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  FormatHelper.capitalize(total > 1 ? '${s.engTipsTricks}  ·  $index / $total' : s.engTipsTricks),
                  style: StyleText.fontSize13Weight600
                      .copyWith(color: on.withOpacity(0.85)),
                ),
              ),
              // SAVE — an icon. Its own GestureDetector wins the tap, so it
              // does not reach the "tap anywhere closes" detector.
              Tooltip(
                message: s.save,
                child: GestureDetector(
                  onTap: onSave,
                  child: Container(
                    width: 44.r,
                    height: 44.r,
                    decoration: BoxDecoration(
                      color: on.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: AppIcon(Icons.bookmark_add_rounded,
                        size: 22.sp, color: on),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            FormatHelper.capitalize(tip.title),
            style: StyleText.fontSize20Weight600.copyWith(color: on),
          ),
          if (tip.body.isNotEmpty) ...<Widget>[
            SizedBox(height: 8.h),
            Text(
              FormatHelper.capitalize(tip.body),
              style: StyleText.fontSize15Weight400
                  .copyWith(color: on.withOpacity(0.92), height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
