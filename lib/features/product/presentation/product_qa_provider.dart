import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductQAItem {
  final String question;
  final String? answer;
  final int votes;

  const ProductQAItem({required this.question, this.answer, required this.votes});
}

class ProductQANotifier extends Notifier<Map<int, List<ProductQAItem>>> {
  @override
  Map<int, List<ProductQAItem>> build() {
    return {
      100: const [
        ProductQAItem(question: 'Is this suitable for sensitive skin?', answer: 'Yes, it is gentle.', votes: 12),
        ProductQAItem(question: 'How often should I use it?', answer: 'Twice daily, morning and night.', votes: 6),
      ],
    };
  }

  void addQuestion(int productId, String question) {
    final q = question.trim();
    if (q.isEmpty) return;
    final List<ProductQAItem> list = [...(state[productId] ?? const <ProductQAItem>[])];
    list.insert(0, ProductQAItem(question: q, votes: 0));
    state = {...state, productId: list};
  }

  void upvote(int productId, String question) {
    final list = [...(state[productId] ?? const <ProductQAItem>[])];
    final index = list.indexWhere((q) => q.question == question);
    if (index == -1) return;
    final item = list[index];
    list[index] = ProductQAItem(question: item.question, answer: item.answer, votes: item.votes + 1);
    state = {...state, productId: list};
  }
}

final productQAProvider =
    NotifierProvider<ProductQANotifier, Map<int, List<ProductQAItem>>>(ProductQANotifier.new);
