import 'package:clock/clock.dart';

import 'rate_limit.dart';

/// A storage for call start times that affect the possibility of further calls
/// from the perspective of a single [RateLimit].
///
/// It does not handle the calls itself but only decides on their possibility.
class Guard {
  final RateLimit rateLimit;
  final startTimes = <DateTime>[];

  Guard({
    required this.rateLimit,
  }) : assert(rateLimit.requestCount > 0);

  /// Adds a call start time to the history.
  void addStartTime() {
    if (startTimes.length >= rateLimit.requestCount) {
      throw Exception('startTimes is full');
    }

    startTimes.add(clock.now());
  }

  /// Returns the time when this guard will allow access or null if allowed now.
  DateTime? get openTime {
    if (startTimes.length < rateLimit.requestCount) return null;
    return startTimes.first.add(Duration(milliseconds: rateLimit.timeMs));
  }

  /// Removes the older call start times that no longer affect the limit.
  void removeExpired() {
    int removeCount = 0;
    final removeAtAndBefore =
        clock.now().subtract(Duration(milliseconds: rateLimit.timeMs));

    for (final startTime in startTimes) {
      if (startTime.isAfter(removeAtAndBefore)) break;
      removeCount++;
    }

    startTimes.removeRange(0, removeCount);
  }
}
