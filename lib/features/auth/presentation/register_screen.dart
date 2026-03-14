import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _obscure = true;
  String _gender = 'Male';
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _birthController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _birthController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    _checkPhoneUnique();
  }

  Future<void> _checkPhoneUnique() async {
    final raw = _phoneController.text.trim();
    final normalized = _normalizePhone(raw);
    if (normalized.length < 8) {
      setState(() => _error = 'Nomor handphone tidak valid');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList('registered_phones') ?? <String>[];
    if (existing.contains(normalized)) {
      setState(() => _error = 'Nomor handphone sudah terdaftar');
      return;
    }
    existing.add(normalized);
    await prefs.setStringList('registered_phones', existing);
    setState(() => _error = null);
    if (!mounted) return;
    context.go('/otp');
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime(now.year - 10, 12, 31),
    );
    if (picked == null) return;
    _birthController.text = DateFormat('dd MMM yyyy').format(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSubmit = _usernameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _birthController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Account'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.headset_mic_outlined),
            label: const Text('Help?'),
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LabeledField(
              label: 'Username',
              child: TextField(
                controller: _usernameController,
                decoration: _inputDecoration('Username'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Username is available', style: TextStyle(color: Colors.green)),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Email',
              child: TextField(
                controller: _emailController,
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Tanggal Lahir',
              child: TextField(
                controller: _birthController,
                readOnly: true,
                onTap: _pickBirthDate,
                decoration: _inputDecoration('Tanggal Lahir').copyWith(
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Nomor Handphone',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('🇮🇩'),
                        SizedBox(width: 6),
                        Text('+62'),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Nomor Handphone'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Password',
              child: TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: _inputDecoration('Password').copyWith(
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _GenderChip(
                  label: 'Female',
                  selected: _gender == 'Female',
                  onTap: () => setState(() => _gender = 'Female'),
                ),
                const SizedBox(width: 8),
                _GenderChip(
                  label: 'Male',
                  selected: _gender == 'Male',
                  onTap: () => setState(() => _gender = 'Male'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Referral code (optional)',
              child: TextField(
                controller: _referralController,
                decoration: _inputDecoration('Referral code (optional)'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: canSubmit ? scheme.primary : scheme.outline.withAlpha(120),
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: canSubmit ? 2 : 0,
                ),
                child: const Text('Create account', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Login',
                          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

String _normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('62')) return digits;
  if (digits.startsWith('0')) return '62${digits.substring(1)}';
  return digits;
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? scheme.primary : scheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
