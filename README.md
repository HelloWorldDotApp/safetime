# safetime

`safetime` provides a trusted wall-clock time for Dart and Flutter apps.
It synchronizes with NTP once, then derives later timestamps from a monotonic
clock so that users changing the local system time after initialization do not
affect the returned value.

This package now works in strict mode:

- `SafeTime.now` throws until `SafeTime.init()` succeeds.
- `SafeTime.init()` returns a `SafeTimeInitResult` so the caller can decide
  whether to continue or block the user flow.
- If trusted synchronization fails, no fallback wall-clock time is exposed.

## What it protects against

- Users manually changing device system time after trusted initialization
- Normal wall-clock jumps caused by local time changes

## What it does not protect against

- Starting the app offline before any trusted synchronization succeeds
- A compromised OS or rooted device forging monotonic clock behavior
- Web platforms, where trusted synchronization is reported as unsupported

## Usage

```dart
import 'package:safetime/safetime.dart';

Future<void> main() async {
  final result = await SafeTime.init();

  if (!result.isTrusted) {
    throw StateError('Trusted time is unavailable: ${result.error}');
  }

  final trustedNow = SafeTime.now;
  print(trustedNow);
}
```

## API notes

- `SafeTime.init()` attempts to synchronize with NTP.
- `SafeTime.now` is only available after a successful initialization.
- `SafeTime.tickCount` exposes the local monotonic tick count used for
  time derivation.
- `SafeTime.lastInitResult` exposes the latest synchronization status.

## Exceptions

The package throws structured exceptions for caller-side localization and
branching:

- `SafeTimeUnavailableError`: trusted time has not been established yet
- `SafeTimeUnsupportedPlatformError`: the current platform cannot provide
  trusted time
- `SafeTimeClockError`: the monotonic clock source failed
- `SafeTimeNtpError`: NTP synchronization failed

Each exception includes a stable `code` field so applications can map error
states to localized copy without parsing message strings.

## Testing

Use `SafeTime.resetForTesting()` to replace the singleton backend in tests.
