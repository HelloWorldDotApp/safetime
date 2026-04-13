import 'dart:ffi';

import 'ntp/ntp.dart';
import 'safetime.abs.dart';
import 'safetime.error.dart';

class WindowsSafeTime implements AbsSafeTime {
  WindowsSafeTime({
    WindowsBindings? binding,
    Duration Function()? tickCountProvider,
    Future<DateTime> Function()? fetchTrustedTime,
  })  : _binding = binding ?? WindowsBindings(DynamicLibrary.open('kernel32.dll')),
        _tickCountProvider = tickCountProvider,
        _fetchTrustedTime = fetchTrustedTime ?? NTP.now;

  final WindowsBindings _binding;
  final Duration Function()? _tickCountProvider;
  final Future<DateTime> Function() _fetchTrustedTime;

  int? _offsetTick;
  SafeTimeInitResult _lastInitResult = const SafeTimeInitResult.uninitialized();

  @override
  Future<SafeTimeInitResult> init() async {
    try {
      final ntpTime = (await _fetchTrustedTime()).millisecondsSinceEpoch;
      _offsetTick = ntpTime - getTickCount().inMilliseconds;
      _lastInitResult = const SafeTimeInitResult.trusted(
        source: SafeTimeSource.ntp,
      );
    } catch (error) {
      _offsetTick = null;
      _lastInitResult = SafeTimeInitResult.untrusted(error: error);
    }
    return _lastInitResult;
  }

  @override
  DateTime getNow() {
    final offsetTick = _offsetTick;
    if (offsetTick == null) {
      throw SafeTimeUnavailableError(
        code: 'trusted_time_unavailable',
        cause: _lastInitResult.error,
      );
    }
    final ticks = offsetTick + getTickCount().inMilliseconds;
    return DateTime.fromMillisecondsSinceEpoch(ticks);
  }

  @override
  Duration getTickCount() {
    if (_tickCountProvider != null) {
      return _tickCountProvider();
    }
    final d = _binding.getTickCount();
    return Duration(milliseconds: d);
  }

  @override
  SafeTimeInitResult get lastInitResult => _lastInitResult;
}

class WindowsBindings {
  final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  WindowsBindings(DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  WindowsBindings.fromLookup(
      Pointer<T> Function<T extends NativeType>(String symbolName) lookup)
      : _lookup = lookup;

  int getTickCount() => _getTickCount();

  late final _getTickCountPtr =
      _lookup<NativeFunction<Uint64 Function()>>('GetTickCount64');
  late final _getTickCount = _getTickCountPtr.asFunction<int Function()>();
}
