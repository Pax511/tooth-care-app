import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart'; // adjust if path is different

class WelcomeScreen extends StatefulWidget {
  final Future<void> Function(
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

  final Future<void> Function(
      BuildContext context,
      String username,
      String password,
      ) onLogin;

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
  bool _isLoading = false;

  // ADD: HIPAA Agreement checkbox state
  bool _agreedToHipaa = false;

  void _toggleForm() {
    setState(() {
      _showSignUp = !_showSignUp;
      _signUpFormKey.currentState?.reset();
      _loginFormKey.currentState?.reset();
      _agreedToHipaa = false; // reset checkbox when switching forms
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_agreedToHipaa) {
      _showErrorDialog("Agreement Required", "You must agree to the HIPAA disclaimer before signing up.");
      return;
    }
    if (_signUpFormKey.currentState?.validate() ?? false) {
      _signUpFormKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        await widget.onSignUp(
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
      } on SocketException {
        _showErrorDialog("Network Error", "Unable to connect. Please check your internet connection.");
      } on SignUpUsernameTakenException {
        _showErrorDialog("Sign Up Failed", "This username is already taken. Please choose another.");
      } on SignUpEmailTakenException {
        _showErrorDialog("Sign Up Failed", "This email is already registered. Try logging in or use another email.");
      } on SignUpWeakPasswordException {
        _showErrorDialog("Sign Up Failed", "Password is too weak. Please choose a stronger password.");
      } catch (e) {
        _showErrorDialog("Error", "An unexpected error occurred. Please try again.");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_loginFormKey.currentState?.validate() ?? false) {
      _loginFormKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        await widget.onLogin(
          context,
          _loginUsername,
          _loginPassword,
        );
      } on SocketException {
        _showErrorDialog("Network Error", "Unable to connect. Please check your internet connection.");
      } on InvalidCredentialsException {
        _showErrorDialog("Login Failed", "Incorrect username or password.");
      } catch (e) {
        _showErrorDialog("Error", "An unexpected error occurred. Please try again.");
      } finally {
        setState(() => _isLoading = false);
      }
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
                // Row for the logo images at the top
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Left Logo (LOGO2)
                    Image.asset(
                      'assets/LOGO2.jpg', // Change to your logo2 asset file
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                    // Top Right Logo (LOGO1)
                    Image.asset(
                      'assets/LOGO1.jpg', // Change to your logo1 asset file
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Welcome to Post Dental Guide!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: CircularProgressIndicator(),
                )
                    : _showSignUp
                    ? _buildSignUpForm()
                    : _buildLoginForm(),
                const SizedBox(height: 12),
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
          // HIPAA Agreement Checkbox (must be checked)
          CheckboxListTile(
            value: _agreedToHipaa,
            onChanged: (value) {
              setState(() {
                _agreedToHipaa = value ?? false;
              });
            },
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('HIPAA Disclaimer'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your privacy is important to us. We comply with the Health Insurance Portability and Accountability Act (HIPAA), which requires us to maintain the privacy and security of your health information.",
                          ),
                          SizedBox(height: 12),
                          Text(
                            "• All health information you provide is encrypted and securely stored.",
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• We will not share your personal health information with anyone except as required by law or as necessary for your care.",
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• You have the right to access, amend, and receive an accounting of disclosures of your health information.",
                          ),
                          SizedBox(height: 8),
                          Text(
                            "• For more details, please review our Privacy Policy.",
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[800], size: 20),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'I agree to the HIPAA Disclaimer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Text(
            'By signing up, you agree your data will be used in compliance with HIPAA and our Privacy Policy.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleSignUp,
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
            onPressed: _isLoading ? null : _handleLogin,
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }
}

// Exception classes for demonstration; implement, import, or adapt as needed in your codebase.
class InvalidCredentialsException implements Exception {}
class SignUpUsernameTakenException implements Exception {}
class SignUpEmailTakenException implements Exception {}
class SignUpWeakPasswordException implements Exception {}