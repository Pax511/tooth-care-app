import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'services/api_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/category_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/pfd_instructions_screen.dart';

// ✅ Add your imports for the instruction screens
import 'screens/pfd_instructions_screen.dart';
import 'screens/prd_instructions_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ToothCareGuideApp(),
    ),
  );
}

class ToothCareGuideApp extends StatelessWidget {
  const ToothCareGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToothCareGuide',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // ✅ Fixed: Removed 'date:' since the screens don't expect it
      onGenerateRoute: (settings) {
        if (settings.name == '/instructions') {
          final args = settings.arguments as Map<String, dynamic>;
          final treatment = args['treatment'];
          final subtype = args['subtype'];
          final date = args['date'];

          if (treatment == 'Prosthesis' && subtype == 'Fixed') {
            return MaterialPageRoute(
              builder: (context) => PFDInstructionsScreen(date: date),
            );
          } else if (treatment == 'Prosthesis' && subtype == 'Removable') {
            return MaterialPageRoute(
              builder: (context) => PRDInstructionsScreen(date: date),
            );
          }

          // Add more routes for other treatments if needed
        }

        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Unknown route or arguments')),
          ),
        );
      },


      home: Builder(
        builder: (BuildContext context) {
          return WelcomeScreen(
            onSignUp: (
                BuildContext context,
                String username,
                String password,
                String phone,
                String email,
                String name,
                String dob,
                String gender,
                VoidCallback switchToLogin,
                ) async {
              final error = await ApiService.register({
                'username': username,
                'password': password,
                'phone': phone,
                'email': email,
                'name': name,
                'dob': dob,
                'gender': gender,
              });

              if (error != null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Sign Up Failed"),
                    content: Text(error),
                  ),
                );
              } else {
                final appState = Provider.of<AppState>(context, listen: false);
                appState.setUserDetails(
                  fullName: name,
                  dob: DateTime.parse(dob),
                  gender: gender,
                  username: username,
                  password: password,
                  phone: phone,
                  email: email,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sign up successful! Please login.")),
                );
                switchToLogin();
              }
            },

            onLogin: (username, password) async {
              final error = await ApiService.login(username, password);

              if (error != null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Login Failed"),
                    content: Text(error),
                  ),
                );
              } else {
                final appState = Provider.of<AppState>(context, listen: false);

                // ✅ Fetch full user details using stored token
                final userDetails = await ApiService.getUserDetails();

                if (userDetails != null) {
                  appState.setUserDetails(
                    fullName: userDetails['name'],
                    dob: DateTime.parse(userDetails['dob']),
                    gender: userDetails['gender'],
                    username: userDetails['username'],
                    password: password,
                    phone: userDetails['phone'],
                    email: userDetails['email'],
                  );
                }

                // ✅ Navigate to CategoryScreen
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoryScreen()),
                  );
                });
              }
            },
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
