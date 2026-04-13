import 'dart:io';

import 'safetime.abs.dart';
import 'safetime.io.unix.dart';
import 'safetime.io.windows.dart';

AbsSafeTime createSafetime() => SafeTimeIO();

class SafeTimeIO implements AbsSafeTime {
  final AbsSafeTime _safetime;

  SafeTimeIO()
      : _safetime = Platform.isWindows ? WindowsSafeTime() : UnixSafeTime();

  @override
  Future<SafeTimeInitResult> init() => _safetime.init();

  @override
  DateTime getNow() => _safetime.getNow();

  @override
  Duration getTickCount() => _safetime.getTickCount();

  @override
  SafeTimeInitResult get lastInitResult => _safetime.lastInitResult;
}
