import 'package:flutter/material.dart';

class ProfileSecurityScreen extends StatefulWidget {
  const ProfileSecurityScreen({super.key});

  @override
  State<ProfileSecurityScreen> createState() => _ProfileSecurityScreenState();
}

class _ProfileSecurityScreenState extends State<ProfileSecurityScreen> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _biometric = false;
  String? _error;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    if (_newController.text.trim().isEmpty || _confirmController.text.trim().isEmpty) {
      setState(() => _error = 'Password fields are required');
      return;
    }
    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security settings updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _oldController,
            decoration: const InputDecoration(labelText: 'Old password'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _newController,
            decoration: const InputDecoration(labelText: 'New password'),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            decoration: const InputDecoration(labelText: 'Confirm new password'),
            obscureText: true,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable biometric'),
            subtitle: const Text('Use fingerprint or face to login'),
            value: _biometric,
            onChanged: (v) => setState(() => _biometric = v),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset link sent')),
              );
            },
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}
