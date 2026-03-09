import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  String? _error;
  int _cooldown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  void _verify() {
    if (_otpController.text.trim().length < 4) {
      setState(() => _error = 'Invalid OTP code');
      return;
    }
    setState(() => _error = null);
    context.go('/complete-profile');
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _cooldown == 0;
    return Scaffold(
      appBar: AppBar(title: const Text('OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP code'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: canResend
                  ? () {
                      _startCooldown();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP sent again')),
                      );
                    }
                  : null,
              child: Text(canResend ? 'Resend OTP' : 'Resend in ${_cooldown}s'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verify,
                child: const Text('Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
