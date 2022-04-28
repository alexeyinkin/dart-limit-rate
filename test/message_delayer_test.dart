import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:limit_rate/limit_rate.dart';
import 'package:test/test.dart';

class CallTracker {
  DateTime? _callDateTime;

  DateTime? get callDateTime => _callDateTime;

  void call() {
    _callDateTime = clock.now();
  }
}

DateTime handler(CallTracker callTracker) {
  callTracker.call();
  return callTracker.callDateTime!;
}

void main() {
  test(
    'fires right away without limits, preserves input and output',
    () {
      final initialTime = DateTime(2022);
      final delay = const Duration(milliseconds: 1000);
      fakeAsync(
        (async) {
          final sut = MessageDelayer<CallTracker, DateTime>(
            rateLimits: [],
            handler: handler,
          );

          dynamic returned1;
          final tracker1 = CallTracker();
          final future1 = sut.sendMessage(tracker1);
          final callDateTime1 = tracker1.callDateTime;
          future1.then((r) {
            returned1 = r;
          });

          final tracker2 = CallTracker();
          sut.sendMessage(tracker2);
          final callDateTime2 = tracker2.callDateTime;

          async.elapse(delay);

          final tracker3 = CallTracker();
          sut.sendMessage(tracker3);
          final callDateTime3 = tracker3.callDateTime;

          expect(callDateTime1, initialTime);
          expect(returned1, initialTime);
          expect(callDateTime2, initialTime);
          expect(callDateTime3, initialTime.add(delay));
        },
        initialTime: initialTime,
      );
    },
  );

  test(
    'runs within limits',
    () {
      final initialTime = DateTime(2022);
      fakeAsync(
        (async) {
          final sut = MessageDelayer<CallTracker, DateTime?>(
            rateLimits: [
              const RateLimit(requestCount: 2, timeMs: 1000),
              const RateLimit(requestCount: 4, timeMs: 60000),
            ],
            handler: handler,
          );

          //     Call times:   Process times:
          // 1:        0    ->       0       Right through
          // 2:        0    ->       0       Right through
          // 3:        0    ->    1000       Hit 1st limit
          // 4:      500    ->    1000       Hit 1st limit
          // 5:      500    ->   60000       Hit 1st and 2nd limits
          // 6:    60500    ->   60500       Right through
          // 7:    60500    ->   61000       Hit 1st limit

          // The first two are handled synchronously.
          final tracker1 = CallTracker();
          sut.sendMessage(tracker1);
          final callDateTime1 = tracker1.callDateTime;

          final tracker2 = CallTracker();
          sut.sendMessage(tracker2);
          final callDateTime2 = tracker2.callDateTime;

          DateTime? callDateTime3;
          final tracker3 = CallTracker();
          sut.sendMessage(tracker3).then((dt) {
            callDateTime3 = dt;
          });

          async.elapse(const Duration(milliseconds: 500));

          DateTime? callDateTime4;
          final tracker4 = CallTracker();
          sut.sendMessage(tracker4).then((dt) {
            callDateTime4 = dt;
          });

          DateTime? callDateTime5;
          final tracker5 = CallTracker();
          sut.sendMessage(tracker5).then((dt) {
            callDateTime5 = dt;
          });

          async.elapse(const Duration(milliseconds: 60000));

          // Right through again.
          final tracker6 = CallTracker();
          sut.sendMessage(tracker6);
          final callDateTime6 = tracker6.callDateTime;

          DateTime? callDateTime7;
          final tracker7 = CallTracker();
          sut.sendMessage(tracker7).then((dt) {
            callDateTime7 = dt;
          });

          async.elapse(const Duration(milliseconds: 500));

          // 1 and 2 went right through.
          expect(callDateTime1, initialTime);
          expect(callDateTime2, initialTime);

          // 3 and 4 are processed in a single timer fire.
          // TODO: Verify the number of timer creations.
          expect(
            callDateTime3,
            initialTime.add(const Duration(milliseconds: 1000)),
          );
          expect(
            callDateTime4,
            initialTime.add(const Duration(milliseconds: 1000)),
          );

          expect(
            callDateTime5,
            initialTime.add(const Duration(milliseconds: 60000)),
          );
          expect(
            callDateTime6,
            initialTime.add(const Duration(milliseconds: 60500)),
          );
          expect(
            callDateTime7,
            initialTime.add(const Duration(milliseconds: 61000)),
          );
        },
        initialTime: initialTime,
      );
    },
  );
}
