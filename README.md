Guards access to a given resource according to request rate limits.

## Usage ##

In this setup, the handler may be called at most once per second and at most 10 times a minute.
Calls over that limit will be delayed.

```dart
void main() async {
  final delayer = MessageDelayer<int, String>(
    rateLimits: [
      const RateLimit(requestCount: 1, timeMs: 1000),
      const RateLimit(requestCount: 10, timeMs: 60000),
    ],
    handler: (n) => n.toString(),
  );

  final str = await delayer.sendMessage(1);
}
```
