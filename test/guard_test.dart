import 'package:fake_async/fake_async.dart';
import 'package:limit_rate/src/guard.dart';
import 'package:limit_rate/src/rate_limit.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Requires positive requestCount and timeMs',
    () {
      expect(() {
        Guard(rateLimit: RateLimit(requestCount: 0, timeMs: 1000));
      }, throwsA(TypeMatcher<AssertionError>()));

      expect(() {
        Guard(rateLimit: RateLimit(requestCount: -1, timeMs: 1000));
      }, throwsA(TypeMatcher<AssertionError>()));

      expect(() {
        Guard(rateLimit: RateLimit(requestCount: 1, timeMs: 0));
      }, throwsA(TypeMatcher<AssertionError>()));

      expect(() {
        Guard(rateLimit: RateLimit(requestCount: 1, timeMs: -1));
      }, throwsA(TypeMatcher<AssertionError>()));
    },
  );

  test(
    'Can run immediately if not full, returns the correct delay if full',
    () {
      final timeMs = 1000;
      final initialTime = DateTime(2022);
      fakeAsync(
        (async) {
          final sut = Guard(
            rateLimit: RateLimit(requestCount: 3, timeMs: timeMs),
          );
          sut.addStartTime();
          async.elapse(Duration(milliseconds: 300));
          sut.addStartTime();

          final openTimeAfter2 = sut.openTime;

          sut.addStartTime();

          final openTimeAfter3 = sut.openTime;

          expect(openTimeAfter2, null);
          expect(
            openTimeAfter3,
            initialTime.add(Duration(milliseconds: timeMs)),
          );
        },
        initialTime: initialTime,
      );
    },
  );

  test(
    'removeExpired removes calls if timeMs has passed',
    () {
      final limitDuration = const Duration(milliseconds: 1000);
      final toSecond = const Duration(milliseconds: 300);
      final initialTime = DateTime(2022);
      fakeAsync(
        (async) {
          final sut = Guard(
            rateLimit: RateLimit(
              requestCount: 2,
              timeMs: limitDuration.inMilliseconds,
            ),
          );
          sut.addStartTime(); // Call times: [0]
          async.elapse(toSecond);
          sut.addStartTime(); // Call times: [0, 300]
          async.elapse( // FF to 1299.999999
            Duration(microseconds: limitDuration.inMicroseconds - 1),
          );
          sut.removeExpired(); // Call times: [300] (1 microsecond left)
          sut.addStartTime(); // Call times: [300, 1299.999999]

          final openTimeJustBefore = sut.openTime;

          async.elapse(const Duration(microseconds: 1)); // FF to 1300
          sut.removeExpired(); // Call times: [1299.999999]
          final openTimeJustInTime = sut.openTime;

          expect(
            openTimeJustBefore,
            initialTime.add(toSecond).add(limitDuration),
          );
          expect(openTimeJustInTime, null);
        },
        initialTime: initialTime,
      );
    },
  );

  test('throws on adding if full', () {
    final sut = Guard(rateLimit: RateLimit(requestCount: 2, timeMs: 1000));

    sut.addStartTime();
    sut.addStartTime();

    expect(
      () => sut.addStartTime(),
      throwsException,
    );
  });
}
