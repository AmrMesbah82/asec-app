/// Module: engagement / e1_engagement
///
///*************************** FILE INFO ****************************///
/// File Name: watch_sync.dart
/// Purpose: Declares `WatchSync` (sends a member's watch progress to
///          `progress/{uid}` so the admin and the leaderboard see their
///          stars) and `CourseStars` (1 star per 20% of a course, 5 at most).
/// Author: ASEC team
/// Created: 15/10/2026
///
/// FEW WRITES. Progress is saved on the device every few seconds while a
/// lesson plays (VideoWatchStore). Only a step of 5% or more — or reaching
/// the end — is queued here, and the queue is written in ONE merge a few
/// seconds later, so a whole lesson costs a handful of writes.

import 'dart:async';

import 'package:get_storage/get_storage.dart';

import 'package:asec/features/engagement/e1_engagement/data/repository/engagement_repository.dart';
import 'package:asec/features/onboarding/o2_authentication/domain/entities/app_user.dart';
import 'package:asec/features/onboarding/o2_authentication/presentation/controller/session_controller.dart';
import 'package:asec/features/video/v1_videos/domain/entities/video_item.dart';
import 'package:asec/features/video/v1_videos/presentation/ui/widgets/video_watch_store.dart';

abstract final class WatchSync {
  const WatchSync._();

  static final GetStorage _box = GetStorage();
  static final EngagementRepository _repository = EngagementRepository();
  static final Map<String, double> _pending = <String, double>{};
  static Timer? _timer;

  static String _key(String uid, String id) => 'video_sync_${uid}_$id';

  static double _synced(String uid, String id) {
    final Object? v = _box.read<Object>(_key(uid, id));
    return v is num ? v.toDouble() : 0;
  }

  /// Called by VideoWatchStore after every save. Members only.
  static void report(String videoId, double progress) {
    final AppUser me = SessionController.to.current;
    if (me.isEmpty || me.isAdmin) return;
    final double p = progress.clamp(0.0, 1.0);
    final double last = _pending[videoId] ?? _synced(me.uid, videoId);
    final bool finished = p >= 1 && last < 1;
    if (!finished && p < last + 0.05) return;
    _pending[videoId] = double.parse(p.toStringAsFixed(2));
    _timer ??= Timer(const Duration(seconds: 4), _flush);
  }

  /// Sends what this device already knows — progress made before this
  /// feature existed, or while offline.
  static void backfill(Iterable<VideoItem> videos) {
    for (final VideoItem v in videos) {
      final double p = VideoWatchStore.progress(v.id);
      if (p > 0) report(v.id, p);
    }
  }

  static Future<void> _flush() async {
    _timer = null;
    final AppUser me = SessionController.to.current;
    if (_pending.isEmpty || me.isEmpty) return;
    final Map<String, double> batch = Map<String, double>.of(_pending);
    _pending.clear();
    try {
      await _repository.writeProgress(
        uid: me.uid,
        name: me.displayName,
        videos: batch,
      );
      for (final MapEntry<String, double> e in batch.entries) {
        _box.write(_key(me.uid, e.key), e.value);
      }
    } catch (_) {
      // Offline or refused: the next report or backfill sends it again.
    }
  }
}

/// 1 star for every 20% of a course watched — 5 stars at most.
abstract final class CourseStars {
  const CourseStars._();

  static const int max = 5;

  /// 0..1 — the average progress of the course's videos.
  static double ratio(Iterable<double> progresses) {
    int n = 0;
    double sum = 0;
    for (final double p in progresses) {
      n++;
      sum += p.clamp(0.0, 1.0);
    }
    return n == 0 ? 0 : sum / n;
  }

  static int fromRatio(double ratio) {
    final int stars = (ratio.clamp(0.0, 1.0) * max + 1e-9).floor();
    return stars < 0 ? 0 : (stars > max ? max : stars);
  }

  /// This device's own progress in [videos].
  static double localRatio(Iterable<VideoItem> videos) =>
      ratio(videos.map((VideoItem v) => VideoWatchStore.progress(v.id)));

  static int local(Iterable<VideoItem> videos) => fromRatio(localRatio(videos));
}
