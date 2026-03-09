import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_log_provider.dart';

class AnalyticsLogScreen extends ConsumerStatefulWidget {
  const AnalyticsLogScreen({super.key});

  @override
  ConsumerState<AnalyticsLogScreen> createState() => _AnalyticsLogScreenState();
}

class _AnalyticsLogScreenState extends ConsumerState<AnalyticsLogScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(analyticsLogProvider);
    final types = {
      'All',
      ...logs.map(_typeOf),
    }.toList();
    final filtered = _filter == 'All' ? logs : logs.where((l) => _typeOf(l) == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Logs'),
        actions: [
          TextButton(
            onPressed: () => ref.read(analyticsLogProvider.notifier).clear(),
            child: const Text('Clear', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 12),
                ...types.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _filter == t,
                      onSelected: (_) => setState(() => _filter = t),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No events yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => Text(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

String _typeOf(String log) {
  if (log.startsWith('[')) {
    final end = log.indexOf(']');
    if (end > 1) return log.substring(1, end);
  }
  return 'general';
}
