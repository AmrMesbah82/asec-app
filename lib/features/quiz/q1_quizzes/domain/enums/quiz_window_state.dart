/// Module: quiz / q1_quizzes
///
///*************************** FILE INFO ****************************///
/// File Name: quiz_window_state.dart
/// Purpose: Declares `QuizWindowState` — where "now" sits in a quiz's
///          allowed-time window.
/// Author: ASEC team
/// Created: 19/9/2026

/// TWO DIFFERENT TIMES, AND THEY ARE EASY TO CONFUSE:
///
///   * the WINDOW (`opensAt` .. `closesAt`) — when the quiz may be taken at
///     all. This enum is about that.
///   * the COUNTDOWN (`durationMinutes`) — how long one member gets once they
///     have started. That lives on the attempt.
enum QuizWindowState {
  /// Before `opensAt`.
  notOpenYet,

  /// Inside the window, or no window set at all.
  open,

  /// After `closesAt`.
  closed;

  bool get isOpen => this == QuizWindowState.open;
}
