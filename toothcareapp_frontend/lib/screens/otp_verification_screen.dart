import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String emailOrPhone;
  const OtpVerificationScreen({super.key, required this.emailOrPhone});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}


class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _otp = '';
  String _error = '';
  bool _loading = false;
  bool _resending = false;
  int _resendCooldown = 30;
  int _secondsLeft = 0;
  String _resendMessage = '';
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _secondsLeft = _resendCooldown;
    });
    Future.doWhile(() async {
      if (_secondsLeft == 0) return false;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _secondsLeft--;
        });
      }
      return _secondsLeft > 0;
    });
  }

  Future<void> _resendOtp() async {
    setState(() {
      _resending = true;
      _resendMessage = '';
    });
    final result = await ApiService.requestReset(widget.emailOrPhone);
    setState(() {
      _resending = false;
      if (result == true) {
        _resendMessage = 'OTP resent! Please check your email or phone.';
        _startResendTimer();
      } else {
        _resendMessage = result is String ? result : 'Failed to resend OTP.';
      }
    });
  }

  Future<void> _submitOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState!.save();

    setState(() {
      _loading = true;
      _error = '';
    });

    final result = await ApiService.verifyOtpAndResetPassword(
      widget.emailOrPhone,
      _otp,
      '', // No password for OTP verification only
    );

    setState(() {
      _loading = false;
    });

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successful! Please login.")),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    } else {
      setState(() {
        _error = result ?? "OTP verification failed. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Enter the OTP sent to your email or phone",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "OTP",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter OTP" : null,
                  onSaved: (v) => _otp = v ?? '',
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitOtp,
                          child: const Text("Reset Password"),
                        ),
                      ),
                const SizedBox(height: 16),
                _resending
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : TextButton(
                        onPressed: _secondsLeft == 0 ? _resendOtp : null,
                        child: Text(_secondsLeft == 0
                            ? "Resend OTP"
                            : "Resend OTP in $_secondsLeft s"),
                      ),
                if (_resendMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _resendMessage,
                      style: TextStyle(
                        color: _resendMessage.startsWith('OTP resent')
                            ? Colors.green
                            : Colors.red,
                      ),
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