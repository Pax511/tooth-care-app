import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart'; // adjust if path is different

class WelcomeScreen extends StatefulWidget {
  final Function(
      BuildContext context,
      String username,
      String password,
      String phone,
      String email,
      String name,
      String dob,
      String gender,
      VoidCallback switchToLogin,
      ) onSignUp;

  final Function(String username, String password) onLogin;

  const WelcomeScreen({
    super.key,
    required this.onSignUp,
    required this.onLogin,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _signUpFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  String _signupUsername = '';
  String _signupPassword = '';
  String _signupPhone = '';
  String _signupEmail = '';
  String _signupName = '';
  String _signupDob = '';
  String _signupGender = 'Male';

  String _loginUsername = '';
  String _loginPassword = '';

  bool _showSignUp = true;

  void _toggleForm() {
    setState(() {
      _showSignUp = !_showSignUp;
      _signUpFormKey.currentState?.reset();
      _loginFormKey.currentState?.reset();
    });
  }

  void _handleSignUp() {
    if (_signUpFormKey.currentState?.validate() ?? false) {
      _signUpFormKey.currentState!.save();
      widget.onSignUp(
        context,
        _signupUsername,
        _signupPassword,
        _signupPhone,
        _signupEmail,
        _signupName,
        _signupDob,
        _signupGender,
        _toggleForm,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Welcome to Post Dental Guide!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _showSignUp ? _buildSignUpForm() : _buildLoginForm(),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _toggleForm,
                  child: Text(
                    _showSignUp
                        ? "Already have an account? Login"
                        : "Don't have an account? Sign up",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? "Enter full name" : null,
            onSaved: (v) => _signupName = v ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Date of Birth (YYYY-MM-DD)",
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? "Enter date of birth" : null,
            onSaved: (v) => _signupDob = v ?? '',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _signupGender,
            decoration: const InputDecoration(
              labelText: "Gender",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "Male", child: Text("Male")),
              DropdownMenuItem(value: "Female", child: Text("Female")),
              DropdownMenuItem(value: "Other", child: Text("Other")),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _signupGender = v);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? "Enter username" : null,
            onSaved: (v) => _signupUsername = v ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) {
              if (v == null || v.isEmpty) return "Enter password";
              if (v.length < 6) return "Password must be at least 6 characters";
              return null;
            },
            onSaved: (v) => _signupPassword = v ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Phone Number",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.isEmpty) return "Enter phone number";
              if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                return "Enter valid 10-digit phone number";
              }
              return null;
            },
            onSaved: (v) => _signupPhone = v ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Email Address",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return "Enter email address";
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(v)) {
                return "Enter valid email address";
              }
              return null;
            },
            onSaved: (v) => _signupEmail = v ?? '',
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSignUp,
            child: const Text("Sign Up"),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? "Enter username" : null,
            onSaved: (v) => _loginUsername = v ?? '',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (v) => v == null || v.isEmpty ? "Enter password" : null,
            onSaved: (v) => _loginPassword = v ?? '',
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_loginFormKey.currentState?.validate() ?? false) {
                _loginFormKey.currentState!.save();
                widget.onLogin(_loginUsername, _loginPassword);
              }
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
}
