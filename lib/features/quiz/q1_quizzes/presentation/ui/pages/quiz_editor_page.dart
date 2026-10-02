/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_editor_page.dart
/// Purpose: Declares `QuizEditorPage` — the admin writes a quiz: questions,
///          the countdown, and the window it is open in.
/// Author: ASEC team
/// Created: 19/9/2026

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:asec/core/constants/app_constants.dart';
import 'package:asec/core/custom/101-custom_surface.dart';
import 'package:asec/core/custom/110-app_widgets.dart';
import 'package:asec/core/custom/111-app_svg_icon.dart';
import 'package:asec/core/custom/1-custom_dropdown.dart';
import 'package:asec/core/custom/2-custom_textfield.dart';
import 'package:asec/core/theme/app_colors.dart';
import 'package:asec/core/theme/app_padding.dart';
import 'package:asec/core/theme/app_theme.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz.dart';
import 'package:asec/features/quiz/q1_quizzes/domain/entities/quiz_question.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/controller/quiz_editor_cubit.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/date_time_field.dart';
import 'package:asec/features/quiz/q1_quizzes/presentation/ui/widgets/question_editor_card.dart';
import 'package:asec/features/video/v1_videos/data/repository/video_repository.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/generated/l10n.dart';

class QuizEditorPage extends StatelessWidget {
  const QuizEditorPage({
    super.key,
    this.quiz,
    required this.adminUid,
    this.certificate = false,
  });

  /// Null = a new quiz.
  final Quiz? quiz;
  final String adminUid;

  /// A NEW quiz starts as a certificate quiz (a course's final exam).
  final bool certificate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizEditorCubit>(
      create: (_) => QuizEditorCubit(
        existing: quiz,
        adminUid: adminUid,
        certificate: certificate,
      ),
      child: const _QuizEditorView(),
    );
  }
}

class _QuizEditorView extends StatelessWidget {
  const _QuizEditorView();

  /// From here the form is two columns: settings beside the questions.
  static const double _splitWidth = 1000;

  String _formMessage(BuildContext context, QuizFormError error) {
    final S s = S.of(context);
    switch (error) {
      case QuizFormError.titleEmpty:
        return s.enterTitle;
      case QuizFormError.noQuestions:
        return s.errNoQuestions;
      case QuizFormError.questionsIncomplete:
        return s.questionsIncomplete;
      case QuizFormError.windowBackwards:
        return s.errWindowBackwards;
      case QuizFormError.courseMissing:
        return s.errChooseCourse;
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizEditorCubit cubit = context.read<QuizEditorCubit>();

    return BlocConsumer<QuizEditorCubit, QuizEditorState>(
      listenWhen: (QuizEditorState a, QuizEditorState b) => a.status != b.status,
      listener: (BuildContext context, QuizEditorState state) {
        if (state.status == QuizEditorStatus.saved) {
          final ScaffoldMessengerState messenger =
              ScaffoldMessenger.of(context);
          Navigator.of(context).pop(true);
          messenger.showSnackBar(SnackBar(content: Text(s.quizSaved)));
        }
      },
      builder: (BuildContext context, QuizEditorState state) {
        final bool split = MediaQuery.sizeOf(context).width >= _splitWidth;

        final Widget settings = _SettingsColumn(state: state);
        final Widget questions = _QuestionsColumn(state: state);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              cubit.isNew ? s.newQuiz : s.editQuiz,
              style: StyleText.fontSize18Weight600,
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsetsDirectional.only(end: AppPadding.h),
                child: AppButton(
                  label: s.save,
                  icon: Icons.check_rounded,
                  dense: true,
                  loading: state.isSaving,
                  onPressed: cubit.save,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.h,
              vertical: 16.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (state.formError != null) ...<Widget>[
                  InfoBanner.error(_formMessage(context, state.formError!)),
                  SizedBox(height: 14.h),
                ],
                if (state.failure != null) ...<Widget>[
                  InfoBanner.error(state.failure!.message(context)),
                  SizedBox(height: 14.h),
                ],
                if (split)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(flex: 4, child: settings),
                      SizedBox(width: 16.w),
                      Expanded(flex: 6, child: questions),
                    ],
                  )
                else ...<Widget>[
                  settings,
                  SizedBox(height: 16.h),
                  questions,
                ],
                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Title, description, the countdown and the window.
class _SettingsColumn extends StatefulWidget {
  const _SettingsColumn({required this.state});

  final QuizEditorState state;

  @override
  State<_SettingsColumn> createState() => _SettingsColumnState();
}

class _SettingsColumnState extends State<_SettingsColumn> {
  late final TextEditingController _title =
      TextEditingController(text: widget.state.quiz.title);
  late final TextEditingController _description =
      TextEditingController(text: widget.state.quiz.description);
  late final TextEditingController _duration = TextEditingController(
    text: widget.state.quiz.durationMinutes == 0
        ? ''
        : widget.state.quiz.durationMinutes.toString(),
  );

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizEditorCubit cubit = context.read<QuizEditorCubit>();
    final Quiz quiz = widget.state.quiz;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppCard(
          title: s.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CustomTextField(
                controller: _title,
                label: s.title,
                hint: s.quizTitleHint,
                required: true,
                onChanged: cubit.setTitle,
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                controller: _description,
                label: s.description,
                hint: s.descriptionHint,
                maxLines: 3,
                onChanged: cubit.setDescription,
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        if (quiz.certificate) ...<Widget>[
          AppCard(
            title: s.courseLabel,
            caption: s.courseCaption,
            child: _CoursePicker(
              value: quiz.course,
              onChanged: cubit.setCourse,
            ),
          ),
          SizedBox(height: 16.h),
        ],
        AppCard(
          title: s.timeLimit,
          caption: s.zeroUntimed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CustomTextField(
                controller: _duration,
                label: s.minutes,
                hint: '0',
                keyboardType: TextInputType.number,
                prefixIcon: const AppIcon(Icons.timer_outlined),
                onChanged: (String value) =>
                    cubit.setDuration(int.tryParse(value.trim()) ?? 0),
              ),
              SizedBox(height: 18.h),
              Text(s.availabilityWindow, style: StyleText.fontSize14Weight600),
              SizedBox(height: 4.h),
              Text(
                s.availabilityHint,
                style: StyleText.fontSize12Weight400
                    .copyWith(color: AppColors.secondaryText),
              ),
              SizedBox(height: 12.h),
              DateTimeField(
                label: s.opensAt,
                value: quiz.opensAt,
                onChanged: cubit.setOpensAt,
              ),
              SizedBox(height: 12.h),
              DateTimeField(
                label: s.closesAt,
                value: quiz.closesAt,
                icon: Icons.lock_outline_rounded,
                onChanged: cubit.setClosesAt,
              ),
              SizedBox(height: 16.h),
              Material(
                // See settings_page: a ListTile needs its own Material inside
                // a card that paints its own background.
                color: AppColors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.published, style: StyleText.fontSize14Weight600),
                  subtitle: Text(
                    s.publishedHint,
                    style: StyleText.fontSize12Weight400
                        .copyWith(color: AppColors.secondaryText),
                  ),
                  trailing: Switch.adaptive(
                    value: quiz.published,
                    activeTrackColor: AppColors.secondaryPrimary,
                    onChanged: cubit.setPublished,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The question list and the button that adds one.
class _QuestionsColumn extends StatelessWidget {
  const _QuestionsColumn({required this.state});

  final QuizEditorState state;

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    final QuizEditorCubit cubit = context.read<QuizEditorCubit>();
    final List<QuizQuestion> questions = state.quiz.questions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppSectionHeader(
          title: s.questions,
          caption: s.questionsTotal(
            '${questions.length}',
            '${state.quiz.totalPoints}',
          ),
        ),
        SizedBox(height: 12.h),
        for (int i = 0; i < questions.length; i++)
          QuestionEditorCard(
            // The id keeps this card's controllers with ITS question when the
            // list around it shifts.
            key: ValueKey<String>(questions[i].id),
            index: i,
            question: questions[i],
            canRemove: questions.length > 1,
            onTextChanged: (String value) =>
                cubit.setQuestionText(questions[i].id, value),
            onOptionChanged: (int index, String value) =>
                cubit.setOption(questions[i].id, index, value),
            onCorrectChanged: (int index) =>
                cubit.setCorrect(questions[i].id, index),
            onPointsChanged: (int points) =>
                cubit.setQuestionPoints(questions[i].id, points),
            onAddOption: () => cubit.addOption(questions[i].id),
            onRemoveOption: (int index) =>
                cubit.removeOption(questions[i].id, index),
            onRemove: () => cubit.removeQuestion(questions[i].id),
          ),
        AppButton(
          label: s.addQuestion,
          icon: Icons.add_rounded,
          kind: AppButtonKind.subtle,
          expand: true,
          onPressed: cubit.addQuestion,
        ),
        SizedBox(height: 8.h),
        Text(
          '${s.minutes}: ${AppConstants.maxQuizMinutes} max',
          textAlign: TextAlign.center,
          style: StyleText.fontSize11Weight400
              .copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

/// The course a certificate quiz closes: one of the video categories (Drive
/// sub-folders). A course that no longer has videos is still offered, so an
/// existing quiz never loses its value.
class _CoursePicker extends StatefulWidget {
  const _CoursePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  State<_CoursePicker> createState() => _CoursePickerState();
}

class _CoursePickerState extends State<_CoursePicker> {
  late final Stream<List<VideoItem>> _videos = VideoRepository().watchAll();

  @override
  Widget build(BuildContext context) {
    final S s = S.of(context);
    return StreamBuilder<List<VideoItem>>(
      stream: _videos,
      builder: (BuildContext context, AsyncSnapshot<List<VideoItem>> snap) {
        final Map<String, int> order = <String, int>{};
        for (final VideoItem v in snap.data ?? const <VideoItem>[]) {
          final String c = v.category.trim();
          if (c.isEmpty) continue;
          final int o = v.categoryOrder > 0 ? v.categoryOrder : 1 << 20;
          if (!order.containsKey(c) || o < order[c]!) order[c] = o;
        }
        final List<String> courses = order.keys.toList()
          ..sort((String a, String b) {
            final int c = order[a]!.compareTo(order[b]!);
            return c != 0 ? c : a.toLowerCase().compareTo(b.toLowerCase());
          });
        final String current = widget.value.trim();
        if (current.isNotEmpty && !courses.contains(current)) {
          courses.insert(0, current);
        }

        return CustomDropdown<String>(
          value: current.isEmpty ? null : current,
          hint: s.chooseCourse,
          required: true,
          prefixIcon: Icon(Icons.folder_rounded, color: AppColors.primary, size: 20),
          items: <DropdownItem<String>>[
            for (final String c in courses)
              DropdownItem<String>(value: c, label: c),
          ],
          onChanged: widget.onChanged,
        );
      },
    );
  }
}
