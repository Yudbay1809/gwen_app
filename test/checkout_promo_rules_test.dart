import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gwen_app/features/cart/presentation/cart_providers.dart';

void main() {
  test('promo rule enforces min subtotal and stacking constraints', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(appliedPromosProvider.notifier);
    final rules = container.read(availablePromosProvider);

    final belowMinimum = notifier.apply(
      code: 'GLOW20',
      subtotal: 200000,
      rules: rules,
    );
    expect(belowMinimum, contains('Minimum subtotal'));

    final ok = notifier.apply(code: 'BEAUTY10', subtotal: 350000, rules: rules);
    expect(ok, '');

    final blockedStack = notifier.apply(
      code: 'GLOW20',
      subtotal: 350000,
      rules: rules,
    );
    expect(blockedStack, contains('cannot be stacked'));
  });
}
