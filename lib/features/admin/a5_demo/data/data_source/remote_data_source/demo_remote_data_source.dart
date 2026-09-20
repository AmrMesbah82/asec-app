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
import 'package:asec/features/admin/a5_demo/domain/constants/demo_seed.dart';
import 'package:asec/features/cv/c1_cv/data/models/cv_model.dart';
import 'package:asec/features/onboarding/o2_authentication/data/models/user_model.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/enums/user_role.dart';
import 'package:asec/features/quiz/q1_quizzes/data/models/quiz_model.dart';
import 'package:asec/features/video/v1_videos/data/models/video_model.dart';

/// What a run of the button actually wrote or deleted, so the message can say
/// something truer than "done".
class DemoCounts {
  const DemoCounts({
    this.members = 0,
    this.videos = 0,
    this.quizzes = 0,
    this.attempts = 0,
    this.cvs = 0,
    this.accountsMade = 0,
  });

  final int members;
  final int videos;
  final int quizzes;
  final int attempts;
  final int cvs;

  /// How many of the members got a real Firebase Auth account, and so can
  /// actually sign in. Fewer than [members] means Auth refused some — the
  /// Firestore side is still complete, the admin views still fill.
  final int accountsMade;

  int get total => members + videos + quizzes + attempts + cvs;
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

    final WriteBatch batch = AppFirebase.db.batch();

    for (final DemoMember member in DemoSeed.members) {
      batch.set(
        _col(FirebaseCollections.users).doc(uidOf[member.slug]),
        <String, dynamic>{
          UserModel.fullName: member.fullName,
          UserModel.email: member.email,
          UserModel.phone: member.phone,
          FirebaseCollections.roleField: UserRole.user.key,
          FirebaseCollections.activeField: member.active,
          FirebaseCollections.canCreateCvField: member.canCreateCv,
          FirebaseCollections.createdAtField:
              _stamp(now.subtract(Duration(days: member.joinedDaysAgo))),
          FirebaseCollections.updatedAtField: AppFirebase.now,
          FirebaseCollections.demoField: true,
        },
      );
    }

    // 2. The videos. No Cloud Storage object is written — the urls are public
    //    sample files — so `storage_path` stays empty and removing a demo
    //    video removes only its document.
    for (final DemoVideo video in DemoSeed.videos) {
      batch.set(
        _col(FirebaseCollections.videos).doc('demo_v_${video.slug}'),
        <String, dynamic>{
          VideoModel.title: video.title,
          VideoModel.description: video.description,
          VideoModel.url: video.url,
          VideoModel.storagePath: '',
          VideoModel.sizeBytes: video.sizeBytes,
          FirebaseCollections.publishedField: video.published,
          VideoModel.createdBy: adminUid,
          FirebaseCollections.createdAtField:
              _stamp(now.subtract(Duration(days: video.addedDaysAgo))),
          FirebaseCollections.updatedAtField: AppFirebase.now,
          FirebaseCollections.demoField: true,
        },
      );
    }

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

    return DemoCounts(
      members: DemoSeed.members.length,
      videos: DemoSeed.videos.length,
      quizzes: DemoSeed.quizzes.length,
      attempts: attemptCount,
      cvs: cvCount,
      accountsMade: accountsMade,
    );
  }

  // ── Remove ───────────────────────────────────────────────────────────────

  /// Deletes every document carrying `demo: true`, in every collection.
  ///
  /// The Auth accounts themselves stay: a client cannot delete another
  /// account, and only a signed-in user can delete their own. They are inert
  /// without a profile — signing in with one lands on a member view with
  /// nothing in it — and pressing Fill again adopts them back.
  Future<DemoCounts> remove() async {
    final int members = await _purge(FirebaseCollections.users);
    final int videos = await _purge(FirebaseCollections.videos);
    final int quizzes = await _purge(FirebaseCollections.quizzes);
    final int attempts = await _purge(FirebaseCollections.attempts);
    final int cvs = await _purge(FirebaseCollections.cvs);

    return DemoCounts(
      members: members,
      videos: videos,
      quizzes: quizzes,
      attempts: attempts,
      cvs: cvs,
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
