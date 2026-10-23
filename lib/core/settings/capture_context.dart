/// Module: core / settings
///
///*************************** FILE INFO ****************************///
/// File Name: capture_context.dart
/// Purpose: Declares `CaptureContext` and `CaptureTag` — WHERE the member is
///          in the app, so a screenshot / screen-recording alert can tell the
///          admin which page and which course it was taken on.
/// Author: ASEC team
/// Created: 20/10/2026
///
/// Three sources, most specific first:
///   1. A page pushed on top of the shell wraps itself in [CaptureTag]
///      (video player, quiz) — page name, course, and the lesson/quiz title.
///   2. The Videos tab reports the course / sub-folder the member opened
///      ([browsingCourse]).
///   3. The shell reports the tab on screen ([tabId], [tabLabel]).

import 'package:flutter/widgets.dart';

class CaptureWhere {
  const CaptureWhere({this.page = '', this.course = '', this.detail = ''});

  /// "Video player", "Quiz", or the tab name.
  final String page;

  /// The course (video category › sub-folder), '' when none.
  final String course;

  /// The lesson or quiz title, '' when none.
  final String detail;
}

abstract final class CaptureContext {
  static final List<CaptureWhere> _stack = <CaptureWhere>[];

  /// The shell tab on screen.
  static String tabId = '';
  static String tabLabel = '';

  /// The course opened inside the Videos tab ('' = the course list).
  static String browsingCourse = '';

  static void _push(CaptureWhere w) => _stack.add(w);
  static void _remove(CaptureWhere w) => _stack.remove(w);

  /// Where the member is right now.
  static CaptureWhere get now {
    if (_stack.isNotEmpty) return _stack.last;
    return CaptureWhere(
      page: tabLabel,
      course: tabId == 'videos' ? browsingCourse : '',
    );
  }
}

/// Wrap a page in this to name it in capture alerts while it is open.
class CaptureTag extends StatefulWidget {
  const CaptureTag({
    super.key,
    required this.page,
    this.course = '',
    this.detail = '',
    required this.child,
  });

  final String page;
  final String course;
  final String detail;
  final Widget child;

  @override
  State<CaptureTag> createState() => _CaptureTagState();
}

class _CaptureTagState extends State<CaptureTag> {
  late CaptureWhere _where = _make();

  CaptureWhere _make() =>
      CaptureWhere(page: widget.page, course: widget.course, detail: widget.detail);

  @override
  void initState() {
    super.initState();
    CaptureContext._push(_where);
  }

  @override
  void didUpdateWidget(covariant CaptureTag old) {
    super.didUpdateWidget(old);
    if (old.page != widget.page || old.course != widget.course || old.detail != widget.detail) {
      final int i = CaptureContext._stack.indexOf(_where);
      _where = _make();
      if (i >= 0) {
        CaptureContext._stack[i] = _where;
      } else {
        CaptureContext._push(_where);
      }
    }
  }

  @override
  void dispose() {
    CaptureContext._remove(_where);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
