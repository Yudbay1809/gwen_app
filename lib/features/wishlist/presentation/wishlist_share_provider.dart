import 'package:flutter_riverpod/flutter_riverpod.dart';

class WishlistShareNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  String getLink(String name) {
    if (state.containsKey(name)) return state[name]!;
    final link = 'https://soc0.app/wishlist/${name.replaceAll(' ', '-').toLowerCase()}';
    state = {...state, name: link};
    return link;
  }
}

final wishlistShareProvider = NotifierProvider<WishlistShareNotifier, Map<String, String>>(
  WishlistShareNotifier.new,
);
