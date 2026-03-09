import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceDownload {
  final int orderId;
  final String code;
  final String filename;
  final String action;
  final DateTime createdAt;

  const InvoiceDownload({
    required this.orderId,
    required this.code,
    required this.filename,
    required this.action,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'code': code,
        'filename': filename,
        'action': action,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InvoiceDownload.fromJson(Map<String, dynamic> json) {
    return InvoiceDownload(
      orderId: json['orderId'] as int,
      code: json['code'] as String,
      filename: json['filename'] as String,
      action: json['action'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class OrderDownloadsNotifier extends Notifier<List<InvoiceDownload>> {
  static const _storageKey = 'order_invoice_downloads';

  @override
  List<InvoiceDownload> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    state = raw
        .map((e) => InvoiceDownload.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = state.reversed.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  Future<void> addDownload({
    required int orderId,
    required String code,
    required String filename,
    required String action,
  }) async {
    state = [
      InvoiceDownload(
        orderId: orderId,
        code: code,
        filename: filename,
        action: action,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
    await _save();
  }
}

final orderDownloadsProvider =
    NotifierProvider<OrderDownloadsNotifier, List<InvoiceDownload>>(OrderDownloadsNotifier.new);
