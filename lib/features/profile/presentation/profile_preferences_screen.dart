import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'settings_storage_provider.dart';

class ProfilePreferencesScreen extends ConsumerWidget {
  const ProfilePreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    final notifier = ref.read(appPreferencesProvider.notifier);
    final storage = ref.watch(storageUsageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme across the app'),
            value: prefs.isDarkMode,
            onChanged: notifier.setDarkMode,
          ),
          const SizedBox(height: 8),
          const Text('Language', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(prefs.language),
            initialValue: prefs.language,
            items: const [
              DropdownMenuItem(value: 'ID', child: Text('Bahasa Indonesia')),
              DropdownMenuItem(value: 'EN', child: Text('English')),
            ],
            onChanged: (value) {
              if (value != null) notifier.setLanguage(value);
            },
          ),
          const SizedBox(height: 16),
          const Text('Currency', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(prefs.currency),
            initialValue: prefs.currency,
            items: const [
              DropdownMenuItem(value: 'IDR', child: Text('IDR - Rupiah')),
              DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
              DropdownMenuItem(value: 'SGD', child: Text('SGD - Singapore Dollar')),
            ],
            onChanged: (value) {
              if (value != null) notifier.setCurrency(value);
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Active Preferences'),
              subtitle: Text(
                'Theme: ${prefs.isDarkMode ? 'Dark' : 'Light'} | Language: ${prefs.language} | Currency: ${prefs.currency}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Storage Usage'),
              subtitle: Text('${storage.usedMb.toStringAsFixed(0)} MB of ${storage.totalMb.toStringAsFixed(0)} MB'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(storageUsageProvider.notifier).clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear cache'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await notifier.reset();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preferences reset to default')),
                );
              }
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset to default'),
          ),
        ],
      ),
    );
  }
}
