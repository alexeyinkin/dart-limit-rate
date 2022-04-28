import 'package:limit_rate/src/guard.dart';
import 'package:limit_rate/src/guards.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class GuardMock extends Mock implements Guard {}

void main() {
  test(
    'Can run immediately without limits',
    () {
      final sut = Guards(guards: []);

      final openTime = sut.openTime;

      expect(openTime, null);
    },
  );

  test(
    'adds to all guards',
    () {
      final mock1 = GuardMock();
      final mock2 = GuardMock();
      final sut = Guards(guards: [mock1, mock2]);

      sut.addStartTime();

      verify(() => mock1.addStartTime()).called(1);
      verify(() => mock2.addStartTime()).called(1);
    },
  );

  test(
    'openTime returns null for all nulls',
    () {
      final mock1 = GuardMock();
      final mock2 = GuardMock();
      final sut = Guards(guards: [mock1, mock2]);

      final openTime = sut.openTime;

      expect(openTime, null);
    },
  );

  test(
    'openTime returns latest of non-nulls',
    () {
      final mock1 = GuardMock();
      final mock2 = GuardMock();
      final mock3 = GuardMock();
      final mock4 = GuardMock();
      final mock5 = GuardMock();
      when(() => mock1.openTime).thenReturn(DateTime(2021));
      when(() => mock3.openTime).thenReturn(DateTime(2020));
      when(() => mock4.openTime).thenReturn(DateTime(2022));
      final sut = Guards(guards: [mock1, mock2, mock3, mock4, mock5]);

      final openTime = sut.openTime;

      expect(openTime, DateTime(2022));
    },
  );

  test(
    'removes expired from all guards',
    () {
      final mock1 = GuardMock();
      final mock2 = GuardMock();
      final sut = Guards(guards: [mock1, mock2]);

      sut.removeExpired();

      verify(() => mock1.removeExpired()).called(1);
      verify(() => mock2.removeExpired()).called(1);
    },
  );
}
