import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileAvatarNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? path) => state = path;
}

final profileAvatarProvider =
    NotifierProvider<ProfileAvatarNotifier, String?>(ProfileAvatarNotifier.new);
