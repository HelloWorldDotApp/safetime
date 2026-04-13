enum SafeTimeSource { ntp }

class SafeTimeInitResult {
  final bool isTrusted;
  final SafeTimeSource? source;
  final Object? error;

  const SafeTimeInitResult._({
    required this.isTrusted,
    this.source,
    this.error,
  });

  const SafeTimeInitResult.trusted({required SafeTimeSource source}) : this._(isTrusted: true, source: source);

  const SafeTimeInitResult.untrusted({Object? error}) : this._(isTrusted: false, error: error);

  const SafeTimeInitResult.uninitialized() : this._(isTrusted: false);
}

abstract class AbsSafeTime {
  /// Initializes the clock.
  Future<SafeTimeInitResult> init();

  /// The current date and time.
  DateTime getNow();

  /// Duration since boot, including time spent in sleep.
  Duration getTickCount();

  /// The latest synchronization result.
  SafeTimeInitResult get lastInitResult;
}
