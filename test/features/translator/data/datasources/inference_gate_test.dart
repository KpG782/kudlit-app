import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/translator/data/datasources/inference_gate.dart';

void main() {
  group('InferenceGate', () {
    test('serializes overlapping ops so at most one runs at a time', () async {
      final InferenceGate gate = InferenceGate();
      int inFlight = 0;
      int maxInFlight = 0;

      Future<int> body(int id) {
        return gate.run<int>('chat', (CancelSignal sig) async {
          inFlight++;
          maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          inFlight--;
          return id;
        });
      }

      final List<int> results = await Future.wait<int>(<Future<int>>[
        body(1),
        body(2),
        body(3),
      ]);

      expect(maxInFlight, 1);
      expect(results, <int>[1, 2, 3]);
    });

    test('runs ops from different lanes first-in-first-out', () async {
      final InferenceGate gate = InferenceGate();
      final List<String> completionOrder = <String>[];

      Future<void> body(String lane, int ms) {
        return gate.run<void>(lane, (CancelSignal sig) async {
          await Future<void>.delayed(Duration(milliseconds: ms));
          completionOrder.add(lane);
        });
      }

      // chat is enqueued first but is slow; system is enqueued second but
      // fast. FIFO serialization means chat must still complete first.
      final Future<void> chat = body('chat', 40);
      final Future<void> system = body('system', 1);
      await Future.wait<void>(<Future<void>>[chat, system]);

      expect(completionOrder, <String>['chat', 'system']);
    });

    test(
      'supersedes an in-flight op when a newer op shares its lane',
      () async {
        final InferenceGate gate = InferenceGate();
        bool firstObservedCancel = false;

        final Future<String> first = gate.run<String>('scan', (
          CancelSignal sig,
        ) async {
          for (int i = 0; i < 40 && !sig.isCancelled; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          firstObservedCancel = sig.isCancelled;
          return sig.isCancelled ? 'first-cancelled' : 'first-ran-fully';
        });

        // Let the first op start running before a newer scan supersedes it.
        await Future<void>.delayed(const Duration(milliseconds: 15));

        final Future<String> second = gate.run<String>('scan', (
          CancelSignal sig,
        ) async {
          return 'second-done';
        });

        expect(await first, 'first-cancelled');
        expect(firstObservedCancel, isTrue);
        expect(await second, 'second-done');
      },
    );

    test('a superseded stream stops emitting and releases the gate', () async {
      final InferenceGate gate = InferenceGate();
      final List<int> received = <int>[];

      final Stream<int> stream = gate.runStream<int>('scan', (
        CancelSignal sig,
      ) async* {
        for (int i = 0; i < 100; i++) {
          if (sig.isCancelled) return;
          yield i;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      final StreamSubscription<int> sub = stream.listen(received.add);

      // Let a few values flow, then supersede the scan lane.
      await Future<void>.delayed(const Duration(milliseconds: 18));
      bool secondRan = false;
      final Future<void> second = gate.run<void>('scan', (
        CancelSignal sig,
      ) async {
        secondRan = true;
      });

      await second;
      final int countAtSupersede = received.length;
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(received, isNotEmpty);
      expect(secondRan, isTrue);
      expect(received.length, countAtSupersede);
      await sub.cancel();
    });

    test('a system-lane op never cancels an in-flight chat op', () async {
      final InferenceGate gate = InferenceGate();
      bool chatCancelled = false;

      final Future<String> chat = gate.run<String>('chat', (
        CancelSignal sig,
      ) async {
        for (int i = 0; i < 10; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          if (sig.isCancelled) {
            chatCancelled = true;
            return 'chat-cancelled';
          }
        }
        return 'chat-complete';
      });

      // Fire a background system op while chat is mid-flight.
      await Future<void>.delayed(const Duration(milliseconds: 12));
      final Future<void> system = gate.run<void>(
        'system',
        (CancelSignal sig) async {},
      );

      expect(await chat, 'chat-complete');
      expect(chatCancelled, isFalse);
      await system;
    });

    test('cancelLane cancels the active op in that lane', () async {
      final InferenceGate gate = InferenceGate();
      bool observedCancel = false;

      final Future<String> op = gate.run<String>('scan', (
        CancelSignal sig,
      ) async {
        for (int i = 0; i < 40 && !sig.isCancelled; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        observedCancel = sig.isCancelled;
        return sig.isCancelled ? 'cancelled' : 'ran-fully';
      });

      await Future<void>.delayed(const Duration(milliseconds: 15));
      gate.cancelLane('scan');

      expect(await op, 'cancelled');
      expect(observedCancel, isTrue);
    });
  });
}
