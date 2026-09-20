/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: admin_quizzes_page.dart
/// Purpose: Declares `AdminQuizzesPage` — every quiz, drafts included, with
///          the way in to the editor and to the results.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/57-custom_dialog_manager.dart';
import 'package:asec/core/custom/69-cross_axis_count_helper.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/features/admin/a1_shell/presentation/ui/widgets/console_page.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/data/repository/quiz_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/base_repository/quiz_base_repository.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_attempts_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/pages/quiz_editor_page.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/quiz_card.dart';
import 'package:asec/generated/l10n.dart';

class AdminQuizzesPage extends StatefulWidget {
  const AdminQuizzesPage({super.key, required this.adminUid});

  final String adminUid;

  @override
  State<AdminQuizzesPage> createState() => _AdminQuizzesPageState();
}

class _AdminQuizzesPageState extends State<AdminQuizzesPage> {
  final QuizBaseRepository _repository = QuizRepository();
  late final Stream<List<Quiz>> _quizzes = _repository.watchAll();

  Future<void> _openEditor([Quiz? quiz]) => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => QuizEditorPage(quiz: quiz, adminUid: widget.adminUid),
        ),
      );

  Future<void> _confirmDelete(Quiz quiz) async {
    final S s = S.of(context);
    await CustomDialogManager.showConfirm(
      context: context,
      title: s.deleteQuestion(quiz.title),
      subtitle: s.deleteQuizBody,
      confirmLabel: s.delete,
      cancelLabel: s.cancel,
      onConfirm: () async {
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final String deleted = s.deleted;
        await _repository.delete(quiz.id);
        messenger.showSnackBar(SnackBar(content: Text(deleted)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        // Unique per section: see the videos FAB for why.
        heroTag: 'asec_fab_quizzes',
        onPressed: _openEditor,
        backgroundColor: AppColors.primary,
        icon: const AppIcon(Icons.add_rounded, color: Colors.white),
        label: Text(
          s.newQuiz,
          style: StyleText.fontSize14Weight600.copyWith(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: _quizzes,
        builder: (BuildContext context, AsyncSnapshot<List<Quiz>> snapshot) {
          if (snapshot.hasError) {
            return AppErrorView(message: S.of(context).errUnknown);
          }
          if (!snapshot.hasData) return const AppLoading();

          final List<Quiz> quizzes = snapshot.data!;
          if (quizzes.isEmpty) {
            return ConsolePage(
              title: s.quizzes,
              subtitle: s.quizzesAdminSub,
              child: AppEmptyView(
                title: s.noQuizzesTitle,
                subtitle: s.noQuizzesAdminSub,
              ),
            );
          }

          return ConsolePage(
            title: s.quizzes,
            subtitle: s.quizzesAdminSub,
            child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GridView.builder(
                padding: EdgeInsets.only(bottom: 96.h),
                gridDelegate: CrossAxisCountHelper.gridDelegate(
                  context,
                  mainAxisExtent: 210,
                  minCellWidth: 320,
                  availableWidth: constraints.maxWidth,
                ),
                itemCount: quizzes.length,
                itemBuilder: (BuildContext context, int index) {
                  final Quiz quiz = quizzes[index];
                  return QuizCard(
                    quiz: quiz,
                    onTap: () => _openEditor(quiz),
                    trailing: _QuizMenu(
                      quiz: quiz,
                      onEdit: () => _openEditor(quiz),
                      onResults: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => QuizAttemptsPage(quiz: quiz),
                        ),
                      ),
                      onTogglePublished: () => _repository.setPublished(
                        quiz.id,
                        !quiz.published,
                      ),
                      onDelete: () => _confirmDelete(quiz),
                    ),
                  );
                },
              );
            },
          ),
          );
        },
      ),
    );
  }
}

enum _QuizAction { edit, results, publish, delete }

class _QuizMenu extends StatelessWidget {
  const _QuizMenu({
    required this.quiz,
    required this.onEdit,
    required this.onResults,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final Quiz quiz;
  final VoidCallback onEdit;
  final VoidCallback onResults;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);

    return PopupMenuButton<_QuizAction>(
      icon: AppIcon(Icons.more_vert_rounded, size: 20.sp),
      onSelected: (_QuizAction action) {
        switch (action) {
          case _QuizAction.edit:
            onEdit();
          case _QuizAction.results:
            onResults();
          case _QuizAction.publish:
            onTogglePublished();
          case _QuizAction.delete:
            onDelete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_QuizAction>>[
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.edit,
          child: Text(s.edit),
        ),
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.results,
          child: Text(s.results),
        ),
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.publish,
          child: Text(quiz.published ? s.switchOff : s.publish),
        ),
        PopupMenuItem<_QuizAction>(
          value: _QuizAction.delete,
          child: Text(
            s.delete,
            style: StyleText.fontSize14Weight500.copyWith(color: AppColors.red),
          ),
        ),
      ],
    );
  }
}
