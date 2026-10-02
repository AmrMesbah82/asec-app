/// Module: admin / a5_demo
///
///*************************** FILE INFO ****************************///
/// File Name: demo_course_seed.dart
/// Purpose: Declares `DemoCourseSeed` — the certificate exams the demo
///          button writes, one per REAL course (the Drive folders the videos
///          already come from). The videos themselves are only READ.
/// Author: ASEC team
/// Created: 1/10/2026
///
/// A course we wrote questions for (AutoCAD) gets those. Any other course
/// gets questions built from its own lessons — "which of these is a lesson
/// in …", "which part of the course holds …" — so a course added to Drive
/// tomorrow still gets a sensible exam on the next fill.

import 'package:asec/features/admin/a5_demo/domain/constants/demo_seed.dart';

/// One lesson of a real course, as the generator needs it.
class DemoCourseLesson {
  const DemoCourseLesson({required this.title, this.part = ''});

  final String title;

  /// The sub-folder (e.g. "Draw and Modify-02"); '' when none.
  final String part;
}

abstract final class DemoCourseSeed {
  const DemoCourseSeed._();

  /// Questions per exam.
  static const int size = 8;

  /// Written questions, matched by a word in the course name.
  static const Map<String, List<DemoQuestion>> _written = <String, List<DemoQuestion>>{
    'autocad': <DemoQuestion>[
      DemoQuestion(
        text: 'Which command cuts a line exactly where it meets another object?',
        options: <String>['EXTEND', 'TRIM', 'BREAK', 'ERASE'],
        correctIndex: 1,
      ),
      DemoQuestion(
        text: 'FILLET with a radius greater than zero turns a sharp corner into…',
        options: <String>['A bevelled (cut) corner', 'A rounded arc', 'Two separate lines', 'A rectangle'],
        correctIndex: 1,
      ),
      DemoQuestion(
        text: 'CHAMFER is used to…',
        options: <String>['Round a corner with an arc', 'Cut a corner with a straight bevel', 'Copy objects in a circle', 'Stretch a wall'],
        correctIndex: 1,
      ),
      DemoQuestion(
        text: 'Which command draws several parallel lines at once — useful for walls?',
        options: <String>['MLINE', 'PLINE', 'XLINE', 'OFFSET'],
        correctIndex: 0,
      ),
      DemoQuestion(
        text: 'A polyline (PLINE) differs from separate LINE segments because it is…',
        options: <String>['Always curved', 'One single object', 'Only on one layer', 'Not printable'],
        correctIndex: 1,
      ),
      DemoQuestion(
        text: 'PEDIT is the command that…',
        options: <String>['Edits a polyline (join, width, close)', 'Edits text', 'Prints the drawing', 'Edits layer colours'],
        correctIndex: 0,
      ),
      DemoQuestion(
        text: 'What file extension does an AutoCAD drawing TEMPLATE use?',
        options: <String>['.dwg', '.dxf', '.dwt', '.bak'],
        correctIndex: 2,
      ),
      DemoQuestion(
        text: 'To stretch part of a drawing, you must select the objects with…',
        options: <String>['A single click', 'A crossing window', 'The ERASE command', 'Quick select only'],
        correctIndex: 1,
      ),
      DemoQuestion(
        text: 'The keyboard shortcut for ERASE is…',
        options: <String>['R', 'DEL only', 'E', 'X'],
        correctIndex: 2,
      ),
      DemoQuestion(
        text: 'Automatic Save protects your work by…',
        options: <String>[
          'Saving a backup copy every set number of minutes',
          'Printing the drawing',
          'Locking the file',
          'Uploading it to Drive',
        ],
        correctIndex: 0,
      ),
    ],
  };

  /// Titles that are certainly NOT in a given course — the wrong answers of
  /// a generated question when there are not enough other courses.
  static List<String> get _foreignTitles => <String>[
        for (final DemoVideo v in DemoSeed.videos) v.title,
      ];

  /// The exam for [course], [size] questions long.
  ///
  /// [otherTitles] are lesson titles of the OTHER courses.
  static List<DemoQuestion> questionsFor(
    String course,
    List<DemoCourseLesson> lessons,
    List<String> otherTitles,
  ) {
    final String lower = course.toLowerCase();
    for (final MapEntry<String, List<DemoQuestion>> e in _written.entries) {
      if (lower.contains(e.key)) return e.value.take(size).toList();
    }
    return _generated(course, lessons, otherTitles);
  }

  static List<DemoQuestion> _generated(
    String course,
    List<DemoCourseLesson> lessons,
    List<String> otherTitles,
  ) {
    final List<String> foreign = <String>{
      ...otherTitles,
      ..._foreignTitles,
    }.where((String t) => !lessons.any((DemoCourseLesson l) => l.title == t)).toList();
    final List<String> parts = <String>{
      for (final DemoCourseLesson l in lessons)
        if (l.part.isNotEmpty) l.part,
    }.toList();

    final List<DemoQuestion> out = <DemoQuestion>[];
    int f = 0;
    String nextForeign() => foreign.isEmpty ? '—' : foreign[f++ % foreign.length];

    for (int i = 0; i < lessons.length && out.length < size; i++) {
      final DemoCourseLesson lesson = lessons[i];

      // Every other question, when the course is split into parts: which
      // part holds this lesson.
      if (parts.length > 1 && lesson.part.isNotEmpty && i.isOdd) {
        final List<String> options = parts.take(4).toList();
        if (!options.contains(lesson.part)) options[options.length - 1] = lesson.part;
        out.add(DemoQuestion(
          text: 'In "$course", which part contains the lesson "${lesson.title}"?',
          options: options,
          correctIndex: options.indexOf(lesson.part),
        ));
        continue;
      }

      // Correct answer at a different place each time.
      final int at = i % 4;
      final List<String> options = <String>[
        for (int k = 0; k < 4; k++) k == at ? lesson.title : nextForeign(),
      ];
      out.add(DemoQuestion(
        text: 'Which of these is a lesson in "$course"?',
        options: options,
        correctIndex: at,
      ));
    }
    return out;
  }
}
