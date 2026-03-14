import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'login_otp_verify_screen.dart';

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _phoneController = TextEditingController(text: '+62-85731643104');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _goVerify(String method) {
    final phone = _phoneController.text.trim();
    context.go(
      '/login-otp/verify',
      extra: OtpVerifyArgs(phone: phone.isEmpty ? '+62-85731643104' : phone, method: method),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final masked = _maskPhone(_phoneController.text.trim());
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'To ensure smooth shopping experience and the security\n'
                'of your account, we will send you a verification code.',
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 28),
              const Text(
                'Choose a verification method :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'Melalui WhatsApp ke nomor $masked',
                onTap: () => _goVerify('WhatsApp'),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                icon: Icons.sms_outlined,
                iconColor: scheme.primary,
                title: 'Melalui SMS ke nomor $masked',
                onTap: () => _goVerify('SMS'),
              ),
              const Spacer(),
              Text(
                'Didn’t receive the code via WhatsApp and SMS?',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: () => _goVerify('Email'),
                child: Text('Verify via Email', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Verify later', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

String _maskPhone(String phone) {
  if (phone.isEmpty) return '****-****-*104';
  final digits = phone.replaceAll(RegExp(r'\\D'), '');
  if (digits.length < 4) return phone;
  final suffix = digits.substring(digits.length - 3);
  return '****-****-*$suffix';
}
