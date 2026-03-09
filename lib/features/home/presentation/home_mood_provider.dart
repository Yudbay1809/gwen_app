import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomeMood { hydrating, brightening, acne, calming, antiAging }

class HomeMoodNotifier extends Notifier<HomeMood?> {
  @override
  HomeMood? build() => null;

  void setMood(HomeMood? mood) => state = mood;
}

final homeMoodProvider = NotifierProvider<HomeMoodNotifier, HomeMood?>(HomeMoodNotifier.new);

String moodLabel(HomeMood mood) {
  switch (mood) {
    case HomeMood.hydrating:
      return 'Hydrating';
    case HomeMood.brightening:
      return 'Brightening';
    case HomeMood.acne:
      return 'Acne Care';
    case HomeMood.calming:
      return 'Calming';
    case HomeMood.antiAging:
      return 'Anti-Aging';
  }
}
