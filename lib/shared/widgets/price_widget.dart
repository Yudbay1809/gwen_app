import 'package:flutter/material.dart';
import '../../core/utils/formatter.dart';

class PriceWidget extends StatelessWidget {
  final num price;

  const PriceWidget({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Text(Formatter.currency(price));
  }
}
