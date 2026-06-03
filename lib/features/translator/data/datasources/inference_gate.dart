import 'dart:async';

/// Thrown when a superseded or cancelled inference operation is asked to
/// continue. Callers that prefer a typed failure can catch this instead of
/// polling [CancelSignal.isCancelled].
class InferenceCancelled implements Exception {
  const InferenceCancelled();

  @override
  String toString() => 'InferenceCancelled';
}

/// A cooperative cancellation token handed to every gated operation. Long
/// running streams poll [isCancelled] between tokens and abort themselves.
class CancelSignal {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void throwIfCancelled() {
    if (_cancelled) {
      throw const InferenceCancelled();
    }
  }

  void _cancel() {
    _cancelled = true;
  }
}

/// Serializes access to the single native inference engine so at most one
/// operation touches it at any instant. Operations in the same lane supersede
/// each other (the newer cancels the older); operations in different lanes
/// queue strictly first-in-first-out and never cancel one another.
class InferenceGate {
  Future<void> _tail = Future<void>.value();
  final Map<String, CancelSignal> _activeByLane = <String, CancelSignal>{};

  /// Runs [op] after every previously enqueued operation has completed. A
  /// newer op sharing [lane] cancels the pending/in-flight op in that lane.
  Future<T> run<T>(String lane, Future<T> Function(CancelSignal) op) {
    _activeByLane[lane]?._cancel();
    final CancelSignal signal = CancelSignal();
    _activeByLane[lane] = signal;

    final Future<T> result = _tail.then((_) => op(signal));
    _tail = result.then<void>((_) {}, onError: (_) {});
    result.whenComplete(() => _release(lane, signal));
    return result;
  }

  /// Streaming counterpart of [run]. Forwards [op]'s values until the stream
  /// completes or the lane is superseded, then releases the gate.
  Stream<T> runStream<T>(String lane, Stream<T> Function(CancelSignal) op) {
    _activeByLane[lane]?._cancel();
    final CancelSignal signal = CancelSignal();
    _activeByLane[lane] = signal;

    final StreamController<T> controller = StreamController<T>();
    final Future<void> done = _tail.then((_) async {
      if (signal.isCancelled) {
        return;
      }
      try {
        await for (final T value in op(signal)) {
          if (signal.isCancelled) {
            break;
          }
          controller.add(value);
        }
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      } finally {
        await controller.close();
      }
    });
    _tail = done.then<void>((_) {}, onError: (_) {});
    done.whenComplete(() => _release(lane, signal));
    return controller.stream;
  }

  /// Cancels the pending/in-flight op in [lane], if any. Callers use this to
  /// abort their lane's work (e.g. the scanner on reset) without enqueuing a
  /// replacement.
  void cancelLane(String lane) {
    _activeByLane[lane]?._cancel();
  }

  void _release(String lane, CancelSignal signal) {
    if (identical(_activeByLane[lane], signal)) {
      _activeByLane.remove(lane);
    }
  }
}
