/// Module: web
///
///*************************** FILE INFO ****************************///
/// File Name: site_preview_page.dart
/// Purpose: Declares `SitePreviewPage` — "View site" in the app's Website
///          tab. It shows the real public site (the same pages web_main.dart
///          serves) inside the app, reading the same live content, so an
///          edit can be checked at once — and it works before the site has
///          been published to Firebase Hosting.
/// Author: ASEC team
/// Created: 26/9/2026
///
/// The public site is light by design (it is asecbim.com), so the preview
/// draws it with [WebPalette.light] whatever the app's theme; the bar above
/// it follows the app (language, SVG icons). The site starts in the app's
/// language; its "English / عربي" button switches it, and closing the
/// preview puts the app's language back.
library;

import 'package:flutter/material.dart';

import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/features/web/admin/panel_nav.dart' show kWebsiteUrl;
import 'package:asec/features/web/core/i18n.dart';
import 'package:asec/features/web/core/theme.dart';
import 'package:asec/features/web/core/widgets.dart';
import 'package:asec/features/web/site/site_nav.dart';
import 'package:asec/features/web/site/site_shell.dart';

class SitePreviewPage extends StatefulWidget {
  const SitePreviewPage({super.key, this.initialPath = '/'});

  final String initialPath;

  @override
  State<SitePreviewPage> createState() => _SitePreviewPageState();
}

class _SitePreviewPageState extends State<SitePreviewPage> {
  late final List<Uri> _history = <Uri>[Uri.parse(widget.initialPath)];

  /// The language when the preview opened — restored when it closes.
  final String _startLang = AppLang.code;

  @override
  void dispose() {
    AppLang.set(_startLang);
    super.dispose();
  }

  Uri get _uri => _history.last;

  void _go(String path) {
    final Uri next = Uri.parse(path);
    if (next.path == _uri.path) return;
    setState(() => _history.add(next));
  }

  void _back() {
    if (_history.length > 1) {
      setState(_history.removeLast);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // The site is always light (see top). Set before anything below builds.
    WebColors.palette = WebPalette.light;
    final ThemeData theme = WebTheme.light;

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _back();
      },
      child: Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: WebColors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Directionality(
              textDirection: AppLang.direction,
              child: AppBar(
                toolbarHeight: 52,
                backgroundColor: const Color(0xFF0B1B38),
                foregroundColor: WebColors.white,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                leading: IconButton(
                  tooltip: const L('إغلاق المعاينة', 'Close preview').t,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const AppIcon(Icons.close_rounded, color: WebColors.white),
                ),
                title: Row(
                  children: <Widget>[
                    if (_history.length > 1)
                      IconButton(
                        tooltip: const L('رجوع', 'Back').t,
                        onPressed: _back,
                        icon: AppIcon(
                          AppLang.isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                          color: WebColors.white,
                        ),
                      ),
                    const AppIcon(Icons.visibility_outlined, size: 18, color: WebColors.white),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${const L('معاينة الموقع', 'Site preview').t}  ·  ${_uri.path}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WebColors.white),
                      ),
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: WebColors.white),
                    onPressed: () => openLink('$kWebsiteUrl${_uri.path}'),
                    icon: const AppIcon(Icons.open_in_new_rounded, size: 18, color: WebColors.white),
                    label: Text(const L('فتح الرابط المنشور', 'Open live link').t),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          body: SitePreviewScope(
            go: _go,
            child: SiteShell(
              location: _uri.path,
              // Same page change as the web: fade in, rising a few pixels.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                reverseDuration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey<String>(_uri.toString()), child: sitePageFor(_uri)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
