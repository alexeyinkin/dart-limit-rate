import 'dart:async';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart';

import 'guard.dart';
import 'guards.dart';
import 'rate_limit.dart';

/// Protects a resource by delaying access according to a rate limit.
class MessageDelayer<M, R> {
  /// The resource to be protected.
  final R Function(M message) handler;
  final Guards _guards;
  final _queue = <_QueueItem<M, R>>[];
  Timer? _timer;

  MessageDelayer({
    required this.handler,
    required List<RateLimit> rateLimits,
  }) : _guards = Guards(guards: _createGuards(rateLimits));

  static List<Guard> _createGuards(List<RateLimit> rateLimits) {
    return rateLimits
        .map((limit) => Guard(rateLimit: limit))
        .toList(growable: false);
  }

  /// Initiates an attempt to access the resource.
  Future<R> sendMessage(M message) async {
    _guards.removeExpired();
    final openTime = _guards.openTime;

    if (openTime == null) {
      _guards.addStartTime();
      return handler(message);
    }

    final completer = Completer<R>();
    _queue.add(_QueueItem(message: message, completer: completer));
    _setTimerIfNot(openTime);
    return completer.future;
  }

  void _setTimerIfNot(DateTime dateTime) {
    if (_timer != null) return;

    final duration = dateTime.difference(clock.now());

    _timer = Timer(
      duration.isNegative ? Duration.zero : duration,
      _handleQueued,
    );
  }

  void _handleQueued() {
    _timer = null;

    while (true) {
      _guards.removeExpired();

      final queueItem = _queue.firstOrNull;
      if (queueItem == null) return;

      final openTime = _guards.openTime;
      if (openTime != null) {
        _setTimerIfNot(openTime);
        return;
      }

      _queue.removeAt(0);
      _guards.addStartTime();

      queueItem.completer.complete(
        handler(queueItem.message),
      );
    }
  }
}

class _QueueItem<M, R> {
  final M message;
  final Completer<R> completer;

  const _QueueItem({
    required this.message,
    required this.completer,
  });
}
