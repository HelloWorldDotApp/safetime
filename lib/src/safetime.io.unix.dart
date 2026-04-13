// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:io';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'ntp/ntp.dart';
import 'safetime.abs.dart';
import 'safetime.error.dart';

class UnixSafeTime implements AbsSafeTime {
  UnixSafeTime({
    TimeBindings? binding,
    bool? isLinux,
    Duration Function()? tickCountProvider,
    Future<DateTime> Function()? fetchTrustedTime,
  })  : _binding = binding ?? TimeBindings(DynamicLibrary.process()),
        _isLinux = isLinux ?? (Platform.isLinux || Platform.isAndroid),
        _tickCountProvider = tickCountProvider,
        _fetchTrustedTime = fetchTrustedTime ?? NTP.now;

  final TimeBindings _binding;
  final bool _isLinux;
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
    final ts = malloc<timespec>();
    final int result;
    if (_isLinux) {
      result = _binding.clockGettime(7, ts);
    } else {
      result = _binding.clockGettime(6, ts);
    }
    if (result != 0) {
      malloc.free(ts);
      throw const SafeTimeClockError(code: 'clock_gettime_failed');
    }
    final d = ts.ref.tv_sec * 1000000000 + ts.ref.tv_nsec;
    malloc.free(ts);
    return Duration(microseconds: d ~/ 1000);
  }

  @override
  SafeTimeInitResult get lastInitResult => _lastInitResult;
}

class TimeBindings {
  final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  TimeBindings(DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  TimeBindings.fromLookup(
    Pointer<T> Function<T extends NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  int clockGettime(int clockid, Pointer<timespec> spec) {
    return _clockGettime(clockid, spec);
  }

  late final _clockGettimePtr =
      _lookup<NativeFunction<Int Function(Int, Pointer<timespec>)>>(
          'clock_gettime');
  late final _clockGettime =
      _clockGettimePtr.asFunction<int Function(int, Pointer<timespec>)>();
}

final class timespec extends Struct {
  /// seconds
  @Long()
  external int tv_sec;

  /// nanoseconds
  @Long()
  external int tv_nsec;
}
