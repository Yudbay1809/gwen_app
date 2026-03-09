import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompleteProfileScreen extends StatelessWidget {
  const CompleteProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'City')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/shop'),
                child: const Text('Finish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
