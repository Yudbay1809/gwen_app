import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _send() {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Phone number is required');
      return;
    }
    setState(() => _error = null);
    context.go('/login-otp/verify', extra: _phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _send,
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
