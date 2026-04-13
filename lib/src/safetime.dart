import 'safetime.abs.dart';
import 'safetime.error.dart';
import 'safetime.web.dart' if (dart.library.io) 'safetime.io.dart';

export 'safetime.abs.dart' show SafeTimeInitResult, SafeTimeSource;
export 'safetime.error.dart';

class SafeTime {
  final AbsSafeTime _safetime;
  SafeTimeInitResult _lastInitResult = const SafeTimeInitResult.uninitialized();

  SafeTime._internal([AbsSafeTime? safetime])
      : _safetime = safetime ?? createSafetime();

  static SafeTime _instance = SafeTime._internal();

  factory SafeTime() => _instance;

  /// Initializes the SafeTime library.
  static Future<SafeTimeInitResult> init() async {
    final result = await _instance._safetime.init();
    _instance._lastInitResult = result;
    return result;
  }

  /// The current date and time.
  static DateTime get now {
    if (!_instance._lastInitResult.isTrusted) {
      throw SafeTimeUnavailableError(
        code: 'trusted_time_unavailable',
        cause: _instance._lastInitResult.error,
      );
    }
    return _instance._safetime.getNow();
  }

  /// The number of milliseconds elapsed since the system was started.
  static Duration get tickCount => _instance._safetime.getTickCount();

  /// The latest initialization status.
  static SafeTimeInitResult get lastInitResult => _instance._lastInitResult;

  /// Replaces the singleton for tests.
  static void resetForTesting({AbsSafeTime? backend}) {
    _instance = SafeTime._internal(backend);
  }
}
