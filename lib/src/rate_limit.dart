/// Holds the limit of [requestCount] calls in a rolling window
/// of [timeMs] milliseconds.
class RateLimit {
  final int requestCount;
  final int timeMs; // Would use Duration here if not for the task requirement.

  const RateLimit({
    required this.requestCount,
    required this.timeMs,
  })  : assert(requestCount >= 0),
        assert(timeMs > 0);
}
