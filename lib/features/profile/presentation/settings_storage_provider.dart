import 'package:flutter_riverpod/flutter_riverpod.dart';

class StorageUsageState {
  final double usedMb;
  final double totalMb;

  const StorageUsageState({required this.usedMb, required this.totalMb});

  StorageUsageState copyWith({double? usedMb, double? totalMb}) {
    return StorageUsageState(
      usedMb: usedMb ?? this.usedMb,
      totalMb: totalMb ?? this.totalMb,
    );
  }
}

class StorageUsageNotifier extends Notifier<StorageUsageState> {
  @override
  StorageUsageState build() => const StorageUsageState(usedMb: 128.0, totalMb: 512.0);

  void clearCache() {
    state = state.copyWith(usedMb: (state.usedMb - 48).clamp(32, state.totalMb));
  }
}

final storageUsageProvider =
    NotifierProvider<StorageUsageNotifier, StorageUsageState>(StorageUsageNotifier.new);
