import 'dart:async';

import 'package:safetime/safetime.dart';

void main() async {
  final result = await SafeTime.init();
  print(['trusted', result.isTrusted, 'source', result.source]);
  if (!result.isTrusted) {
    print(['error', result.error]);
    return;
  }

  print(['ticks', SafeTime.tickCount]);
  print(['now', SafeTime.now]);
  Timer.periodic(Duration(seconds: 1), (timer) {
    print(['SafeTime', SafeTime.now]);
    print(['DateTime', DateTime.now()]);
    print('======================================');
  });
}
