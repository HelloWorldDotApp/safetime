import 'dart:ffi';

import 'package:safetime/safetime.dart';
import 'package:safetime/src/ntp/ntp.message.dart';
import 'package:safetime/src/safetime.abs.dart';
import 'package:safetime/src/safetime.io.unix.dart';
import 'package:safetime/src/safetime.io.windows.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    SafeTime.resetForTesting();
  });

  test('Singleton Pattern', () {
    final s1 = SafeTime();
    final s2 = SafeTime();
    expect(identical(s1, s2), isTrue);
    expect(s1.hashCode == s2.hashCode, isTrue);
  });

  test('throws before trusted time initialization', () {
    expect(
      () => SafeTime.now,
      throwsA(
        isA<SafeTimeUnavailableError>().having(
          (e) => e.code,
          'code',
          'trusted_time_unavailable',
        ),
      ),
    );
  });

  test('encodes randomized timestamp byte at the requested offset', () {
    final message = NTPMessage();
    final buffer = List<int>.filled(48, 0);

    message.encodeTimestamp(buffer, 40, 1.5);

    expect(buffer[7], 0);
    expect(buffer[47], isNonZero);
  });

  test('init returns trusted result and exposes synchronized time', () async {
    final syncedNow = DateTime.utc(2026, 4, 13, 12, 0, 0);

    SafeTime.resetForTesting(
      backend: _FakeSafeTime(
        initResult: const SafeTimeInitResult.trusted(source: SafeTimeSource.ntp),
        now: syncedNow,
      ),
    );

    final result = await SafeTime.init();

    expect(result.isTrusted, isTrue);
    expect(result.source, SafeTimeSource.ntp);
    expect(SafeTime.now, syncedNow);
  });

  test('failed init keeps time unavailable', () async {
    final error = SafeTimeNtpError(
      code: 'ntp_unavailable',
      server: 'time.example.com',
    );

    SafeTime.resetForTesting(
      backend: _FakeSafeTime(
        initResult: SafeTimeInitResult.untrusted(error: error),
        nowError: SafeTimeUnavailableError(code: 'trusted_time_unavailable'),
      ),
    );

    final result = await SafeTime.init();

    expect(result.isTrusted, isFalse);
    expect(result.error, same(error));
    expect(
      () => SafeTime.now,
      throwsA(
        isA<SafeTimeUnavailableError>().having(
          (e) => e.code,
          'code',
          'trusted_time_unavailable',
        ),
      ),
    );
  });

  test('windows binding uses GetTickCount64 symbol', () {
    late String symbolName;

    Pointer<T> lookup<T extends NativeType>(String name) {
      symbolName = name;
      return Pointer.fromFunction<Uint64 Function()>(_fakeGetTickCount64, 0)
          .cast<T>();
    }

    final binding = WindowsBindings.fromLookup(lookup);

    expect(binding.getTickCount(), 1234);
    expect(symbolName, 'GetTickCount64');
  });

  test('unix binding throws structured clock error when clock_gettime fails', () {
    Pointer<T> lookup<T extends NativeType>(String _) {
      return Pointer.fromFunction<Int32 Function(Int32, Pointer<timespec>)>(
        _fakeClockGettimeFailure,
        1,
      ).cast<T>();
    }

    final safeTime = UnixSafeTime(
      binding: TimeBindings.fromLookup(lookup),
      isLinux: true,
    );

    expect(
      () => safeTime.getTickCount(),
      throwsA(
        isA<SafeTimeClockError>().having(
          (e) => e.code,
          'code',
          'clock_gettime_failed',
        ),
      ),
    );
  });
}

int _fakeGetTickCount64() => 1234;

int _fakeClockGettimeFailure(int _, Pointer<timespec> __) => 1;

class _FakeSafeTime implements AbsSafeTime {
  _FakeSafeTime({
    required this.initResult,
    this.now,
    this.nowError,
  });

  final SafeTimeInitResult initResult;
  final DateTime? now;
  final Object? nowError;

  @override
  Future<SafeTimeInitResult> init() async => initResult;

  @override
  DateTime getNow() {
    if (nowError != null) {
      throw nowError!;
    }
    return now!;
  }

  @override
  Duration getTickCount() => Duration.zero;

  @override
  SafeTimeInitResult get lastInitResult => initResult;
}
