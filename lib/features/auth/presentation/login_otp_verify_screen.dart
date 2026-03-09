import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_state_provider.dart';

class LoginOtpVerifyScreen extends ConsumerStatefulWidget {
  final String phone;

  const LoginOtpVerifyScreen({super.key, required this.phone});

  @override
  ConsumerState<LoginOtpVerifyScreen> createState() => _LoginOtpVerifyScreenState();
}

class _LoginOtpVerifyScreenState extends ConsumerState<LoginOtpVerifyScreen> {
  final _otpController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    if (_otpController.text.trim().length < 4) {
      setState(() => _error = 'Invalid OTP code');
      return;
    }
    setState(() => _error = null);
    ref.read(authProvider.notifier).login();
    context.go('/shop');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Code sent to ${widget.phone}'),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP code'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _verify,
              child: const Text('Verify & Login'),
            ),
          ],
        ),
      ),
    );
  }
}
