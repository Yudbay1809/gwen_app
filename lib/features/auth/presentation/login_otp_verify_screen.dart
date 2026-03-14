import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'auth_state_provider.dart';
import '../../../router/app_router.dart';

class OtpVerifyArgs {
  final String phone;
  final String method;

  const OtpVerifyArgs({required this.phone, required this.method});
}

class LoginOtpVerifyScreen extends ConsumerStatefulWidget {
  final OtpVerifyArgs args;

  const LoginOtpVerifyScreen({super.key, required this.args});

  @override
  ConsumerState<LoginOtpVerifyScreen> createState() => _LoginOtpVerifyScreenState();
}

class _LoginOtpVerifyScreenState extends ConsumerState<LoginOtpVerifyScreen> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  final ValueNotifier<bool> _shakeNotifier = ValueNotifier(false);
  bool _canPaste = false;
  String? _error;
  int _cooldown = 29;
  Timer? _timer;
  Timer? _pasteCheckTimer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _nodes = List.generate(6, (_) => FocusNode());
    if (kIsWeb) {
      _canPaste = true;
    }
    _startCooldown();
    _startPasteCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pasteCheckTimer?.cancel();
    _shakeNotifier.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startPasteCheck() {
    _pasteCheckTimer?.cancel();
    if (kIsWeb) {
      return;
    }
    _pasteCheckTimer = Timer.periodic(const Duration(milliseconds: 600), (_) async {
      try {
        final data = await Clipboard.getData('text/plain');
        final text = (data?.text ?? '').replaceAll(RegExp(r'\\D'), '');
        if (!mounted) return;
        setState(() => _canPaste = text.length >= 4);
      } catch (_) {
        if (!mounted) return;
        setState(() => _canPaste = false);
      }
    });
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 29);
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
    if (_otpCode.length < 6) {
      setState(() => _error = 'Invalid OTP code');
      _shakeError();
      return;
    }
    setState(() => _error = null);
    routerJustLoggedIn = true;
    ref.read(authProvider.notifier).login();
    context.go('/shop');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final method = widget.args.method;
    final phone = widget.args.phone;
    final canVerify = _otpCode.length == 6;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Verify via $method'),
        actions: [
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help is on the way')),
            ),
            icon: Icon(Icons.support_agent, color: scheme.primary),
            label: Text('Help?', style: TextStyle(color: scheme.primary)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  method == 'WhatsApp' ? Icons.chat_bubble_rounded : Icons.sms_outlined,
                  size: 46,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'We have sent a verification code via $method to',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                phone,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 22),
              const Text('Enter verification code', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              if (_canPaste)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _pasteOtp,
                    icon: const Icon(Icons.content_paste, size: 16),
                    label: const Text('Paste OTP'),
                  ),
                ),
              if (_canPaste) const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => _OtpBox(
                    controller: _controllers[index],
                    node: _nodes[index],
                    autoFocus: index == 0,
                    onChanged: (value) => _handleOtpChange(index, value),
                    shake: _shakeNotifier,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canVerify ? _verify : null,
                  child: const Text('Verify'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _cooldown == 0 ? 'Didn’t receive the code?' : 'Wait $_cooldown Second before resending',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              TextButton(
                onPressed: _cooldown == 0
                    ? () {
                        _startCooldown();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code resent via $method')),
                        );
                      }
                    : null,
                child: Text(
                  _cooldown == 0 ? 'Resend Code' : 'Resend disabled',
                  style: TextStyle(color: scheme.primary),
                ),
              ),
              const SizedBox(height: 6),
              Text('Incorrect phone number?', style: TextStyle(color: scheme.onSurfaceVariant)),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Change Number', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _otpCode => _controllers.map((e) => e.text).join();

  void _handleOtpChange(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\\D'), '');
    if (digits.length > 1) {
      _fillFromIndex(index, digits);
      return;
    }
    if (digits.isNotEmpty && index < _nodes.length - 1) {
      _nodes[index + 1].requestFocus();
    } else if (digits.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_otpCode.length == 6) {
      _verify();
    }
  }

  void _fillFromIndex(int startIndex, String digits) {
    var idx = startIndex;
    for (var i = 0; i < digits.length; i++) {
      final ch = digits[i];
      if (idx >= _controllers.length) break;
      _controllers[idx].text = ch;
      idx += 1;
    }
    if (idx < _nodes.length) {
      _nodes[idx].requestFocus();
    } else {
      _nodes.last.unfocus();
    }
    setState(() {});
    if (_otpCode.length == 6) {
      _verify();
    }
  }

  void _shakeError() {
    for (final n in _nodes) {
      n.unfocus();
    }
    for (final c in _controllers) {
      c.clear();
    }
    setState(() {});
    _shakeNotifier.value = !_shakeNotifier.value;
  }

  Future<void> _pasteOtp() async {
    String text = '';
    try {
      final data = await Clipboard.getData('text/plain');
      text = (data?.text ?? '').replaceAll(RegExp(r'\\D'), '');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard unavailable')),
        );
      }
      return;
    }
    if (text.isEmpty) {
      if (mounted) {
        setState(() => _canPaste = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard empty')),
        );
      }
      return;
    }
    _fillFromIndex(0, text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied from clipboard')),
    );
  }
}

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode node;
  final bool autoFocus;
  final ValueChanged<String> onChanged;
  final ValueListenable<bool> shake;

  const _OtpBox({
    required this.controller,
    required this.node,
    required this.autoFocus,
    required this.onChanged,
    required this.shake,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> with TickerProviderStateMixin {
  bool _focused = false;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceScale;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic));
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 15),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOutCubic));
    widget.shake.addListener(_onShake);
  }

  @override
  void dispose() {
    widget.shake.removeListener(_onShake);
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onShake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 42,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() => _focused = hasFocus);
          if (hasFocus) {
            HapticFeedback.selectionClick();
            _bounceController.forward(from: 0);
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_bounceScale, _shakeOffset]),
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeOffset.value, 0),
            child: Transform.scale(scale: _bounceScale.value, child: child),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _focused ? scheme.primary : scheme.outline, width: _focused ? 1.6 : 1),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: scheme.primary.withAlpha(90),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.node,
              autofocus: widget.autoFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
              onChanged: widget.onChanged,
            ),
          ),
        ),
      ),
    );
  }
}
