import 'safetime.abs.dart';
import 'safetime.error.dart';

AbsSafeTime createSafetime() => SafeTimeWeb();

class SafeTimeWeb implements AbsSafeTime {
  SafeTimeInitResult _lastInitResult = const SafeTimeInitResult.uninitialized();

  @override
  Future<SafeTimeInitResult> init() async {
    _lastInitResult = SafeTimeInitResult.untrusted(
      error: const SafeTimeUnsupportedPlatformError(
        code: 'web_trusted_time_unsupported',
      ),
    );
    return _lastInitResult;
  }

  @override
  DateTime getNow() {
    throw SafeTimeUnavailableError(
      code: 'trusted_time_unavailable',
      cause: _lastInitResult.error,
    );
  }

  @override
  Duration getTickCount() =>
      Duration(milliseconds: DateTime.now().millisecondsSinceEpoch);

  @override
  SafeTimeInitResult get lastInitResult => _lastInitResult;
}
