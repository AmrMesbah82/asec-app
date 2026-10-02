/// Module: admin / a5_demo
///
///*************************** FILE INFO ****************************///
/// File Name: demo_remote_data_source.dart
/// Purpose: Writes (and removes) the demo content of `DemoSeed`.
/// Author: ASEC team
/// Created: 20/9/2026
///
/// EVERY DOCUMENT WRITTEN HERE CARRIES `demo: true`.
/// That single flag is the whole design:
///   * remove is a query, not a bookkeeping list of ids;
///   * `firestore.rules` lets the admin write a MEMBER's profile, attempt or
///     CV only while the document carries the flag, so this tool can never be
///     bent into a way of forging a real record;
///   * and nothing the real users create is ever touched by either button.
///
/// Ids are DETERMINISTIC (`demo_q_safety`, `demo_v_boq`, …), so pressing the
/// button twice refreshes the same documents instead of breeding copies.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:asec/core/constants/firebase_collections.dart';
import 'package:asec/core/network/app_firebase.dart';
import 'package:asec/features/admin/a5_demo/domain/constants/demo_course_seed.dart';
import 'package:asec/features/admin/a5_demo/domain/constants/demo_seed.dart';
import 'package:asec/features/cv/c1_cv/data/models/cv_model.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';
import 'package:asec/features/quiz/q1_quizzes/data/models/quiz_model.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/video/v1_videos/data/models/video_model.dart';
import 'package:asec/features/web/data/site_repo.dart';

/// What a run of the button actually wrote or deleted, so the message can say
/// something truer than "done".
class DemoCounts {
  const DemoCounts({
    this.members = 0,
    this.videos = 0,
    this.quizzes = 0,
    this.attempts = 0,
    this.cvs = 0,
    this.certificates = 0,
    this.inbox = 0,
    this.accountsMade = 0,
  });

  final int members;
  final int videos;
  final int quizzes;
  final int attempts;
  final int cvs;

  /// Certificate exams — one per real course.
  final int certificates;

  /// Website inbox entries (messages, service and job requests).
  final int inbox;

  /// How many of the members got a real Firebase Auth account, and so can
  /// actually sign in. Fewer than [members] means Auth refused some — the
  /// Firestore side is still complete, the admin views still fill.
  final int accountsMade;

  int get total =>
      members + videos + quizzes + attempts + cvs + certificates + inbox;
}

class DemoRemoteDataSource {
  CollectionReference<Map<String, dynamic>> _col(String name) =>
      AppFirebase.collection(name);

  // ── Fill ─────────────────────────────────────────────────────────────────

  Future<DemoCounts> fill({required String adminUid}) async {
    final DateTime now = DateTime.now();

    // 1. The members. Each one gets a real Auth account where it can, so the
    //    admin can sign out and sign in AS a member to check the member side.
    //    Where Auth refuses (offline, a keychain that will not open, an email
    //    already taken with another password) the profile is still written
    //    under a stable synthetic uid: the admin views fill either way, that
    //    member simply cannot sign in.
    final Map<String, String> uidOf = <String, String>{};
    int accountsMade = 0;

    for (final DemoMember member in DemoSeed.members) {
      String uid = 'demo_${member.slug}';
      try {
        uid = await AppFirebase.createOrFindAccount(
          email: member.email,
          password: DemoSeed.password,
        );
        accountsMade++;
      } catch (_) {
        // Keep the synthetic uid.
      }
      uidOf[member.slug] = uid;
    }

    // The REAL courses — the Drive folders the videos come from. Read only:
    // the videos are never written or removed by this button.
    final Map<String, List<DemoCourseLesson>> courses = await _realCourses();
    final List<String> courseNames = courses.keys.toList();

    final WriteBatch batch = AppFirebase.db.batch();

    for (final DemoMember member in DemoSeed.members) {
      final _DemoAccess access = _accessFor(member.slug, courseNames, now);
      batch.set(
        _col(FirebaseCollections.users).doc(uidOf[member.slug]),
        <String, dynamic>{
          UserModel.fullName: member.fullName,
          UserModel.email: member.email,
          UserModel.phone: member.phone,
          FirebaseCollections.roleField: UserRole.user.key,
          FirebaseCollections.activeField: member.active,
          FirebaseCollections.canCreateCvField: member.canCreateCv,
          // What the Members screen's access dialog edits: every status
          // (open, paused, not started, ended, limited devices / courses)
          // appears at least once.
          UserModel.coursesAll: access.allCourses,
          UserModel.courses: access.courses,
          UserModel.platforms: access.platforms,
          UserModel.accessFrom: _maybeStamp(access.from),
          UserModel.accessUntil: _maybeStamp(access.until),
          UserModel.pausedAt: _maybeStamp(access.pausedAt),
          FirebaseCollections.createdAtField:
              _stamp(now.subtract(Duration(days: member.joinedDaysAgo))),
          FirebaseCollections.updatedAtField: AppFirebase.now,
          FirebaseCollections.demoField: true,
        },
      );
    }

    // 2. The videos: none. Lessons come from the shared Google Drive
    //    folder (see DriveVideoSync), which also clears the old sample
    //    videos — so demo data no longer adds any.

    // 3. The quizzes.
    for (final DemoQuiz quiz in DemoSeed.quizzes) {
      batch.set(
        _col(FirebaseCollections.quizzes).doc(_quizId(quiz)),
        <String, dynamic>{
          QuizModel.title: quiz.title,
          QuizModel.description: quiz.description,
          QuizModel.durationMinutes: quiz.durationMinutes,
          QuizModel.opensAt: _offsetStamp(now, quiz.opensInHours),
          QuizModel.closesAt: _offsetStamp(now, quiz.closesInHours),
          FirebaseCollections.publishedField: quiz.published,
          QuizModel.questions: <Map<String, dynamic>>[
            for (int i = 0; i < quiz.questions.length; i++)
              <String, dynamic>{
                QuizModel.qId: _questionId(i),
                QuizModel.qText: quiz.questions[i].text,
                QuizModel.qOptions: quiz.questions[i].options,
                QuizModel.qCorrectIndex: quiz.questions[i].correctIndex,
                QuizModel.qPoints: quiz.questions[i].points,
              },
          ],
          QuizModel.questionCount: quiz.questions.length,
          QuizModel.totalPoints: quiz.questions.fold<int>(
            0,
            (int sum, DemoQuestion q) => sum + q.points,
          ),
          QuizModel.createdBy: adminUid,
          FirebaseCollections.createdAtField:
              _stamp(now.subtract(Duration(days: quiz.addedDaysAgo))),
          FirebaseCollections.updatedAtField: AppFirebase.now,
          FirebaseCollections.demoField: true,
        },
      );
    }

    // 4. The attempts. Marked HERE, against the same seed the quiz was
    //    written from, so a demo score is never a number somebody typed: it
    //    is the answers in `DemoSeed` run through the same rule the app uses.
    int attemptCount = 0;
    for (final DemoAttempt attempt in DemoSeed.attempts) {
      final DemoQuiz? quiz = _quizBySlug(attempt.quizSlug);
      final DemoMember? member = _memberBySlug(attempt.memberSlug);
      final String? uid = uidOf[attempt.memberSlug];
      if (quiz == null || member == null || uid == null) continue;

      final String quizId = _quizId(quiz);
      final DateTime startedAt =
          now.subtract(Duration(hours: attempt.startedHoursAgo));
      final DateTime submittedAt =
          startedAt.add(Duration(minutes: attempt.tookMinutes));

      final Map<String, int> answers = <String, int>{};
      int score = 0;
      int correct = 0;
      int totalPoints = 0;

      for (int i = 0; i < quiz.questions.length; i++) {
        final DemoQuestion question = quiz.questions[i];
        totalPoints += question.points;

        // Fewer choices than questions, or -1, means the question was left
        // blank — and a blank is simply absent from the answers map, exactly
        // as the attempt screen writes it.
        final int chosen =
            i < attempt.choices.length ? attempt.choices[i] : -1;
        if (chosen < 0) continue;

        answers[_questionId(i)] = chosen;
        if (chosen == question.correctIndex) {
          correct++;
          score += question.points;
        }
      }

      batch.set(
        _col(FirebaseCollections.attempts)
            .doc(FirebaseCollections.attemptId(quizId, uid)),
        <String, dynamic>{
          FirebaseCollections.quizIdField: quizId,
          QuizAttemptModel.quizTitle: quiz.title,
          FirebaseCollections.userIdField: uid,
          QuizAttemptModel.userName: member.fullName,
          QuizAttemptModel.userEmail: member.email,
          QuizAttemptModel.answers: answers,
          QuizAttemptModel.score: score,
          QuizAttemptModel.totalPoints: totalPoints,
          QuizAttemptModel.correctCount: correct,
          QuizAttemptModel.questionCount: quiz.questions.length,
          QuizAttemptModel.startedAt: _stamp(startedAt),
          FirebaseCollections.submittedAtField: _stamp(submittedAt),
          QuizAttemptModel.autoSubmitted: attempt.autoSubmitted,
          FirebaseCollections.createdAtField: _stamp(submittedAt),
          FirebaseCollections.demoField: true,
        },
      );
      attemptCount++;
    }

    // 5. The CVs. The document id IS the owner's uid, same as a real one.
    int cvCount = 0;
    for (final DemoCv cv in DemoSeed.cvs) {
      final DemoMember? member = _memberBySlug(cv.memberSlug);
      final String? uid = uidOf[cv.memberSlug];
      if (member == null || uid == null) continue;

      batch.set(
        _col(FirebaseCollections.cvs).doc(uid),
        <String, dynamic>{
          CvModel.fullName: member.fullName,
          CvModel.email: member.email,
          CvModel.phone: member.phone,
          CvModel.location: cv.location,
          CvModel.militaryStatus: cv.militaryStatus,
          CvModel.graduationYear: cv.graduationYear,
          CvModel.specialization: cv.specialization,
          CvModel.role: cv.role,
          CvModel.proSkills: cv.proSkills,
          CvModel.softSkills: cv.softSkills,
          CvModel.languages: cv.languages,
          CvModel.bio: cv.bio,
          CvModel.photoUrl: '',
          CvModel.photoPath: '',
          CvModel.facebookLink: cv.facebookLink,
          CvModel.linkedinLink: cv.linkedinLink,
          CvModel.cvFileUrl: cv.cvFileUrl,
          CvModel.cvFilePath: '',
          CvModel.cvFileName: cv.cvFileName,
          CvModel.cvFileSize: cv.cvFileSize,
          CvModel.portfolioLink: cv.portfolioLink,
          CvModel.status: cv.statusKey,
          FirebaseCollections.createdAtField: _stamp(
            DateTime.now().subtract(Duration(days: member.joinedDaysAgo - 2)),
          ),
          FirebaseCollections.updatedAtField: AppFirebase.now,
          FirebaseCollections.demoField: true,
        },
      );
      cvCount++;
    }

    await batch.commit();

    // 6. Certificate exams — one per real course — and their results.
    final WriteBatch certBatch = AppFirebase.db.batch();
    int certCount = 0;
    for (int c = 0; c < courseNames.length; c++) {
      final String course = courseNames[c];
      final List<DemoCourseLesson> lessons = courses[course]!;
      final List<String> otherTitles = <String>[
        for (final MapEntry<String, List<DemoCourseLesson>> e in courses.entries)
          if (e.key != course) ...e.value.map((DemoCourseLesson l) => l.title),
      ];
      final List<DemoQuestion> questions =
          DemoCourseSeed.questionsFor(course, lessons, otherTitles);
      if (questions.isEmpty) continue;

      final String quizId = 'demo_cert_${_slug(course)}';
      final int total = questions.fold<int>(0, (int s, DemoQuestion q) => s + q.points);
      certBatch.set(
        _col(FirebaseCollections.quizzes).doc(quizId),
        <String, dynamic>{
          QuizModel.title: '$course — final exam',
          QuizModel.description:
              'Pass with ${Quiz.passPercent}% to earn the ASEC certificate for $course. '
              'Opens once every lesson of the course is watched.',
          QuizModel.durationMinutes: 20,
          QuizModel.opensAt: null,
          QuizModel.closesAt: null,
          FirebaseCollections.publishedField: true,
          QuizModel.certificate: true,
          QuizModel.course: course,
          QuizModel.questions: <Map<String, dynamic>>[
            for (int i = 0; i < questions.length; i++)
              <String, dynamic>{
                QuizModel.qId: _questionId(i),
                QuizModel.qText: questions[i].text,
                QuizModel.qOptions: questions[i].options,
                QuizModel.qCorrectIndex: questions[i].correctIndex,
                QuizModel.qPoints: questions[i].points,
              },
          ],
          QuizModel.questionCount: questions.length,
          QuizModel.totalPoints: total,
          QuizModel.createdBy: adminUid,
          FirebaseCollections.createdAtField: _stamp(now.subtract(Duration(days: 20 - c))),
          FirebaseCollections.updatedAtField: AppFirebase.now,
          FirebaseCollections.demoField: true,
        },
      );
      certCount++;

      // Who sat it: a pass, a fail on the 2nd try, a pass on the 3rd —
      // so the results table, the certificate and "retake" all show.
      for (final (String slug, int wrong, int tries, int hoursAgo) in <(String, int, int, int)>[
        ('sara', 0, 1, 30 + c * 5),
        ('omar', (questions.length * 0.6).ceil(), 2, 20 + c * 4),
        ('youssef', 2, 3, 12 + c * 3),
      ]) {
        final DemoMember? member = _memberBySlug(slug);
        final String? uid = uidOf[slug];
        if (member == null || uid == null) continue;
        // Skip a member whose demo access does not include this course.
        final _DemoAccess access = _accessFor(slug, courseNames, now);
        if (!access.allCourses && !access.courses.contains(course)) continue;

        final Map<String, int> answers = <String, int>{};
        int score = 0;
        int correct = 0;
        for (int i = 0; i < questions.length; i++) {
          final DemoQuestion q = questions[i];
          final bool right = i >= wrong; // the first [wrong] answers miss
          final int chosen = right ? q.correctIndex : (q.correctIndex + 1) % q.options.length;
          answers[_questionId(i)] = chosen;
          if (chosen == q.correctIndex) {
            correct++;
            score += q.points;
          }
        }
        final DateTime started = now.subtract(Duration(hours: hoursAgo));
        final DateTime submitted = started.add(Duration(minutes: 9 + c));
        certBatch.set(
          _col(FirebaseCollections.attempts).doc(FirebaseCollections.attemptId(quizId, uid)),
          <String, dynamic>{
            FirebaseCollections.quizIdField: quizId,
            QuizAttemptModel.quizTitle: '$course — final exam',
            FirebaseCollections.userIdField: uid,
            QuizAttemptModel.userName: member.fullName,
            QuizAttemptModel.userEmail: member.email,
            QuizAttemptModel.answers: answers,
            QuizAttemptModel.score: score,
            QuizAttemptModel.totalPoints: total,
            QuizAttemptModel.correctCount: correct,
            QuizAttemptModel.questionCount: questions.length,
            QuizAttemptModel.startedAt: _stamp(started),
            FirebaseCollections.submittedAtField: _stamp(submitted),
            QuizAttemptModel.autoSubmitted: false,
            QuizAttemptModel.passed:
                total > 0 && score * 100 >= Quiz.passPercent * total,
            QuizAttemptModel.tries: tries,
            FirebaseCollections.createdAtField: _stamp(submitted),
            FirebaseCollections.demoField: true,
          },
        );
        attemptCount++;
      }
    }
    if (certCount > 0) await certBatch.commit();

    // 7. The website's inbox: contact messages, service requests and job
    //    applications, in every status (new / read / done).
    final int inboxCount = await _fillInbox(now);

    return DemoCounts(
      members: DemoSeed.members.length,
      videos: 0,
      quizzes: DemoSeed.quizzes.length,
      attempts: attemptCount,
      cvs: cvCount,
      certificates: certCount,
      inbox: inboxCount,
      accountsMade: accountsMade,
    );
  }

  /// Course name → its lessons, in lesson order, from the `videos`
  /// collection (filled from Drive). Read only.
  Future<Map<String, List<DemoCourseLesson>>> _realCourses() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col(FirebaseCollections.videos).get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snap.docs
        .where((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
            d.data()[FirebaseCollections.demoField] != true)
        .toList()
      ..sort((QueryDocumentSnapshot<Map<String, dynamic>> a,
              QueryDocumentSnapshot<Map<String, dynamic>> b) {
        final Object? ta = a.data()[FirebaseCollections.createdAtField];
        final Object? tb = b.data()[FirebaseCollections.createdAtField];
        if (ta is Timestamp && tb is Timestamp) return ta.compareTo(tb);
        return 0;
      });
    final Map<String, List<DemoCourseLesson>> out = <String, List<DemoCourseLesson>>{};
    for (final QueryDocumentSnapshot<Map<String, dynamic>> d in docs) {
      final Map<String, dynamic> m = d.data();
      final String course = '${m[VideoModel.category] ?? ''}'.trim();
      final String title = '${m[VideoModel.title] ?? ''}'.trim();
      if (course.isEmpty || title.isEmpty) continue;
      out.putIfAbsent(course, () => <DemoCourseLesson>[]).add(DemoCourseLesson(
            title: title,
            part: '${m[VideoModel.subcategory] ?? ''}'.trim(),
          ));
    }
    return out;
  }

  /// Every access status the Members screen can show, spread over the demo
  /// members. Sara (the account the "ready" message suggests signing in as)
  /// is always fully open.
  static _DemoAccess _accessFor(String slug, List<String> courses, DateTime now) {
    final List<String> first = courses.take(1).toList();
    final List<String> firstTwo = courses.take(2).toList();
    switch (slug) {
      case 'sara':
        return _DemoAccess(
          from: now.subtract(const Duration(days: 90)),
          until: now.add(const Duration(days: 275)),
        );
      case 'omar':
        return _DemoAccess(
          allCourses: first.isEmpty,
          courses: first,
          platforms: const <String>['android', 'ios'],
          until: now.add(const Duration(days: 60)),
        );
      case 'mona':
        return _DemoAccess(
          from: now.subtract(const Duration(days: 45)),
          until: now.add(const Duration(days: 30)),
          pausedAt: now.subtract(const Duration(days: 2)),
        );
      case 'youssef':
        return _DemoAccess(
          allCourses: firstTwo.isEmpty,
          courses: firstTwo,
          platforms: const <String>['windows', 'macos'],
        );
      case 'nour':
        return _DemoAccess(
          from: now.add(const Duration(days: 3)),
          until: now.add(const Duration(days: 93)),
        );
      case 'kareem':
        return _DemoAccess(
          from: now.subtract(const Duration(days: 60)),
          until: now.subtract(const Duration(days: 5)),
        );
    }
    return const _DemoAccess();
  }

  Future<int> _fillInbox(DateTime now) async {
    final WriteBatch b = AppFirebase.db.batch();
    int n = 0;
    void add(String coll, String id, int hoursAgo, String status, Map<String, dynamic> data) {
      b.set(_col(coll).doc('demo_$id'), <String, dynamic>{
        ...data,
        'status': status,
        'created_at': _stamp(now.subtract(Duration(hours: hoursAgo))),
        FirebaseCollections.demoField: true,
      });
      n++;
    }

    add(Coll.messages, 'msg_1', 3, 'new', <String, dynamic>{
      'name': 'أحمد مصطفى',
      'phone': '01011122233',
      'email': 'ahmed.m@example.com',
      'subject': 'استفسار عن كورس الأوتوكاد',
      'message': 'السلام عليكم، أريد معرفة مواعيد الكورس القادم وهل يوجد شهادة في النهاية؟',
    });
    add(Coll.messages, 'msg_2', 26, 'read', <String, dynamic>{
      'name': 'Mariam Fathy',
      'phone': '01198877665',
      'email': 'mariam.f@example.com',
      'subject': 'Corporate training',
      'message': 'We are a contracting company with 12 engineers. Can you run the MEP course for our team on site?',
    });
    add(Coll.messages, 'msg_3', 75, 'done', <String, dynamic>{
      'name': 'محمد عبد الله',
      'phone': '01277766554',
      'email': 'm.abdallah@example.com',
      'subject': 'شكر',
      'message': 'شكرًا على الشرح الممتاز في فيديوهات التكييف، استفدت جدًا.',
    });
    add(Coll.serviceRequests, 'req_1', 8, 'new', <String, dynamic>{
      'client_name': 'خالد إبراهيم',
      'company': 'شركة النخبة للمقاولات',
      'phone': '01022233344',
      'email': 'k.ibrahim@example.com',
      'project_name': 'مستشفى خاص — التجمع الخامس',
      'project_type': 'طبي',
      'services': <String>['تصميم', 'شوب دروينج'],
      'floors': '6',
      'land_area': '2400 م²',
      'location': 'القاهرة الجديدة',
      'files_link': 'https://drive.google.com/',
    });
    add(Coll.serviceRequests, 'req_2', 50, 'read', <String, dynamic>{
      'client_name': 'Hany Lotfy',
      'company': 'Lotfy Developments',
      'phone': '01155544433',
      'email': 'hany@example.com',
      'project_name': 'Residential compound — phase 2',
      'project_type': 'سكني',
      'services': <String>['اشراف على التنفيذ'],
      'floors': '4 buildings × 7',
      'land_area': '12,000 m²',
      'location': 'New Alamein',
      'files_link': '',
    });
    add(Coll.jobApplications, 'job_1', 5, 'new', <String, dynamic>{
      'name': 'ياسمين حسن',
      'university': 'جامعة عين شمس',
      'faculty': 'هندسة — قسم ميكانيكا',
      'residence': 'مدينة نصر',
      'email': 'yasmin.h@example.com',
      'phone': '01066655544',
      'skills': 'AutoCAD, Revit MEP, HAP',
      'company': '',
      'projects_link': '',
      'graduation_date': '2025-07-01',
      'grade': 'جيد جدا',
      'request_type': 'معايشة',
      'skill_level': 'مبتدئ',
      'experience_role': 'مهندس متدرب',
      'from': '',
      'to': '',
    });
    add(Coll.jobApplications, 'job_2', 40, 'done', <String, dynamic>{
      'name': 'Mostafa Adel',
      'university': 'Cairo University',
      'faculty': 'Engineering — Electrical Power',
      'residence': 'Giza',
      'email': 'mostafa.adel@example.com',
      'phone': '01233344455',
      'skills': 'AutoCAD, Dialux, ETAP, shop drawings',
      'company': 'Delta MEP',
      'projects_link': 'https://www.linkedin.com/',
      'graduation_date': '2021-07-01',
      'grade': 'جيد',
      'request_type': 'وظيفة',
      'skill_level': 'متوسط',
      'experience_role': 'مهندس مكتب فني',
      'from': '2021-09-01',
      'to': '2026-06-30',
    });
    await b.commit();
    return n;
  }

  // ── Remove ───────────────────────────────────────────────────────────────

  /// Deletes every document carrying `demo: true`, in every collection.
  ///
  /// The Auth accounts themselves stay: a client cannot delete another
  /// account, and only a signed-in user can delete their own. They are inert
  /// without a profile — signing in with one lands on a member view with
  /// nothing in it — and pressing Fill again adopts them back.
  Future<DemoCounts> remove() async {
    // Videos are NOT touched: they come from the Drive folder only.
    final int members = await _purge(FirebaseCollections.users);
    final int quizzes = await _purge(FirebaseCollections.quizzes);
    final int attempts = await _purge(FirebaseCollections.attempts);
    final int cvs = await _purge(FirebaseCollections.cvs);
    int inbox = 0;
    for (final String coll in <String>[
      Coll.messages,
      Coll.serviceRequests,
      Coll.jobApplications,
    ]) {
      inbox += await _purge(coll);
    }

    return DemoCounts(
      members: members,
      quizzes: quizzes,
      attempts: attempts,
      cvs: cvs,
      inbox: inbox,
    );
  }

  /// Deletes the demo documents of one collection, 400 at a time — a write
  /// batch holds 500 operations and this stays clear of the edge.
  Future<int> _purge(String collection) async {
    int deleted = 0;

    while (true) {
      final QuerySnapshot<Map<String, dynamic>> page = await _col(collection)
          .where(FirebaseCollections.demoField, isEqualTo: true)
          .limit(400)
          .get();

      if (page.docs.isEmpty) return deleted;

      final WriteBatch batch = AppFirebase.db.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in page.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      deleted += page.docs.length;

      // A page that was not full was the last one.
      if (page.docs.length < 400) return deleted;
    }
  }

  // ── Small helpers ────────────────────────────────────────────────────────

  static Timestamp _stamp(DateTime at) => Timestamp.fromDate(at);

  static Timestamp? _maybeStamp(DateTime? at) =>
      at == null ? null : Timestamp.fromDate(at);

  /// "Draw and Modify" → "draw_and_modify"; Arabic names keep their letters.
  static String _slug(String name) {
    final String s = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return s.isEmpty ? 'course' : s;
  }

  static Timestamp? _offsetStamp(DateTime now, int? hours) =>
      hours == null ? null : Timestamp.fromDate(now.add(Duration(hours: hours)));

  static String _quizId(DemoQuiz quiz) => 'demo_q_${quiz.slug}';

  /// Question ids are positional and stable, because the answers map on every
  /// attempt is keyed by them.
  static String _questionId(int index) => 'q${index + 1}';

  static DemoQuiz? _quizBySlug(String slug) {
    for (final DemoQuiz quiz in DemoSeed.quizzes) {
      if (quiz.slug == slug) return quiz;
    }
    return null;
  }

  static DemoMember? _memberBySlug(String slug) {
    for (final DemoMember member in DemoSeed.members) {
      if (member.slug == slug) return member;
    }
    return null;
  }
}

/// One demo member's access settings (see `_accessFor`).
class _DemoAccess {
  const _DemoAccess({
    this.allCourses = true,
    this.courses = const <String>[],
    this.platforms = const <String>[],
    this.from,
    this.until,
    this.pausedAt,
  });

  final bool allCourses;
  final List<String> courses;
  final List<String> platforms;
  final DateTime? from;
  final DateTime? until;
  final DateTime? pausedAt;
}
