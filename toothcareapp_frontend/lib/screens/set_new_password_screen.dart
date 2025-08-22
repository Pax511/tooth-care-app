import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'password_reset_success_screen.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String emailOrPhone;
  final String otp;
  const SetNewPasswordScreen({super.key, required this.emailOrPhone, required this.otp});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _newPassword = '';
  String _confirmPassword = '';
  String _error = '';
  bool _loading = false;

  Future<void> _setPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await ApiService.resetPassword(
      widget.emailOrPhone,
      widget.otp,
      _newPassword,
    );

    setState(() {
      _loading = false;
    });

    if (result == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PasswordResetSuccessScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _error = result ?? "Failed to reset password. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set New Password')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter your new password",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Enter new password";
                    if (v.length < 6) return "Password must be at least 6 characters";
                    return null;
                  },
                  onSaved: (v) => _newPassword = v ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Confirm New Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Confirm new password";
                    if (v != _newPassword) return "Passwords do not match";
                    return null;
                  },
                  onSaved: (v) => _confirmPassword = v ?? '',
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _setPassword,
                          child: const Text("Set Password"),
                        ),
                      ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
