import 'guard.dart';

/// A collection of [Guard] objects each for a single [RateLimit].
///
/// This class merges the logic of multiple [Guard] objects and so acts as
/// a single complex guard.
/// It does not handle the calls itself but only decides on their possibility.
class Guards {
  final List<Guard> guards;

  Guards({
    required this.guards,
  });

  void addStartTime() {
    for (final guard in guards) {
      guard.addStartTime();
    }
  }

  DateTime? get openTime {
    DateTime? latest;

    for (final guard in guards) {
      final openTime = guard.openTime;
      if (latest == null || (openTime?.isAfter(latest) ?? false)) {
        latest = openTime;
      }
    }

    return latest;
  }

  void removeExpired() {
    for (final guard in guards) {
      guard.removeExpired();
    }
  }
}
