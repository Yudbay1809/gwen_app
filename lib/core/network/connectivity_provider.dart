import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_utils_stub.dart'
    if (dart.library.io) 'connectivity_utils_io.dart';

final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield await checkOnline();
  await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
    yield await checkOnline();
  }
});
