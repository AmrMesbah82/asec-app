/// Module: core/helper
///
///*************************** FILE INFO ****************************///
/// File Name: stream_combine.dart
/// Purpose: `combineLatest` — merges several list streams into one, without
///          pulling in rxdart for a single operator.
/// Author: Manger Plus team
/// Created: 18/9/2026

import 'dart:async';

/// Emits [combine] of the latest value of every stream, once each has emitted
/// at least once. Errors from any source are forwarded. Cancelling the result
/// cancels every source — which is what closes the Firestore listeners.
Stream<R> combineLatest<T, R>(
  List<Stream<T>> streams,
  R Function(List<T> values) combine,
) {
  if (streams.isEmpty) return const Stream.empty();
  if (streams.length == 1) {
    return streams.first.map((T v) => combine(<T>[v]));
  }

  late StreamController<R> controller;
  final List<StreamSubscription<T>> subs = <StreamSubscription<T>>[];
  final List<T?> latest = List<T?>.filled(streams.length, null);
  final List<bool> has = List<bool>.filled(streams.length, false);

  void emit() {
    if (has.every((bool h) => h)) {
      controller.add(combine(latest.cast<T>()));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      for (int i = 0; i < streams.length; i++) {
        subs.add(streams[i].listen(
          (T value) {
            latest[i] = value;
            has[i] = true;
            emit();
          },
          onError: controller.addError,
        ));
      }
    },
    onCancel: () async {
      for (final StreamSubscription<T> sub in subs) {
        await sub.cancel();
      }
      subs.clear();
    },
  );

  return controller.stream;
}
