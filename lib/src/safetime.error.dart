abstract class SafeTimeError implements Exception {
  const SafeTimeError({
    required this.code,
    this.cause,
  });

  final String code;
  final Object? cause;
}

class SafeTimeUnavailableError extends SafeTimeError {
  const SafeTimeUnavailableError({
    required super.code,
    super.cause,
  });
}

class SafeTimeUnsupportedPlatformError extends SafeTimeError {
  const SafeTimeUnsupportedPlatformError({
    required super.code,
    super.cause,
  });
}

class SafeTimeClockError extends SafeTimeError {
  const SafeTimeClockError({
    required super.code,
    super.cause,
  });
}

class SafeTimeNtpError extends SafeTimeError {
  const SafeTimeNtpError({
    required super.code,
    this.server,
    super.cause,
  });

  final String? server;
}
