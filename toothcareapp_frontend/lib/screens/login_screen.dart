import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../app_state.dart';
import 'category_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _error = '';
  bool _loading = false;

  Future<void> _persistLoginToken(String username, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', token);
    await prefs.setString('username', username);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Login to ToothCareGuide",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? "Enter username" : null,
                    onSaved: (v) => _username = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? "Enter password" : null,
                    onSaved: (v) => _password = v ?? '',
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState!.save();
                        setState(() {
                          _loading = true;
                          _error = '';
                        });

                        final appState = Provider.of<AppState>(context, listen: false);
                        final result = await ApiService.login(_username, _password);

                        if (result != null && result is String) {
                          setState(() {
                            _error = result;
                            _loading = false;
                          });
                        } else {
                          // Assume ApiService saves token internally AND returns it, or you need to fetch it from ApiService
                          // For demonstration, let's say you can get it from ApiService after login
                          String? token = await ApiService.getSavedToken(); // Implement this in your ApiService
                          if (token == null || token.isEmpty) {
                            setState(() {
                              _error = 'Login failed: token not found';
                              _loading = false;
                            });
                            return;
                          }

                          await _persistLoginToken(_username, token);

                          final userDetails = await ApiService.getUserDetails();
                          if (userDetails != null) {
                            appState.setUserDetails(
                              fullName: userDetails['name'],
                              dob: DateTime.parse(userDetails['dob']),
                              gender: userDetails['gender'],
                              username: userDetails['username'],
                              password: _password,
                              phone: userDetails['phone'],
                              email: userDetails['email'],
                            );

                            // Navigate to CategoryScreen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const CategoryScreen()),
                            );
                          } else {
                            setState(() {
                              _error = 'Failed to load user details';
                              _loading = false;
                            });
                          }
                        }
                      }
                    },
                    child: const Text("Login"),
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
      ),
    );
  }
}