import 'package:flutter_test/flutter_test.dart';
import 'package:gwen_app/core/utils/scroll_spy.dart';

void main() {
  test('pickBestSection selects highest visibility ratio', () {
    final section = pickBestSection({
      ScrollSection.overview: 0.12,
      ScrollSection.ingredients: 0.55,
      ScrollSection.reviews: 0.22,
    });
    expect(section, ScrollSection.ingredients);
  });

  test('pickBestSection defaults to overview when empty', () {
    final section = pickBestSection({});
    expect(section, ScrollSection.overview);
  });
}
