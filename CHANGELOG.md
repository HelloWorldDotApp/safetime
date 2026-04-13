## 1.0.0

- Enforced strict trusted-time initialization before exposing `SafeTime.now`
- Added structured `SafeTimeInitResult` status reporting
- Replaced string and generic exceptions with structured `SafeTimeError` types
- Fixed NTP timestamp encoding and switched Windows uptime binding to `GetTickCount64`

- Initial version.
