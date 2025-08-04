import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';
import 'services/api_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/category_screen.dart';
import 'screens/home_screen.dart';
import 'screens/treatment_screen.dart';
import 'screens/pfd_instructions_screen.dart';
import 'screens/prd_instructions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.loadInstructionLogs();

  runApp(
    ChangeNotifierProvider(
      create: (_) => appState,
      child: const ToothCareGuideApp(),
    ),
  );
}

// Utility function to parse "HH:mm:ss" or "HH:mm" string to TimeOfDay
TimeOfDay? parseTimeOfDay(dynamic timeStr) {
  if (timeStr == null) return null;
  final str = timeStr is String ? timeStr : timeStr.toString();
  final parts = str.split(":");
  if (parts.length < 2) return null;
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
      home: AppEntryGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppEntryGate extends StatefulWidget {
  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final isLoggedIn = await ApiService.checkIfLoggedIn();
    if (!isLoggedIn) {
      setState(() => _loading = false);
      return;
    }

    final userDetails = await ApiService.getUserDetails();
    if (userDetails == null) {
      setState(() => _loading = false);
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    appState.setUserDetails(
      fullName: userDetails['name'],
      dob: DateTime.parse(userDetails['dob']),
      gender: userDetails['gender'],
      username: userDetails['username'],
      password: '', // Password not retrievable
      phone: userDetails['phone'],
      email: userDetails['email'],
    );
    // Set additional info if available
    appState.setDepartment(userDetails['department']);
    appState.setDoctor(userDetails['doctor']);
    appState.setTreatment(userDetails['treatment'], subtype: userDetails['treatment_subtype']);
    appState.procedureDate = userDetails['procedure_date'] != null
        ? DateTime.parse(userDetails['procedure_date'])
        : null;
    appState.procedureTime = parseTimeOfDay(userDetails['procedure_time']);
    appState.procedureCompleted =
        userDetails['procedure_completed'] == true;

    // Auto-skip logic
    if (appState.department != null &&
        appState.doctor != null &&
        appState.treatment != null &&
        appState.procedureDate != null &&
        appState.procedureTime != null &&
        appState.procedureCompleted == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (appState.treatment == 'Prosthesis' && appState.treatmentSubtype == 'Fixed') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PFDInstructionsScreen(date: appState.procedureDate!),
            ),
          );
        } else if (appState.treatment == 'Prosthesis' && appState.treatmentSubtype == 'Removable') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PRDInstructionsScreen(date: appState.procedureDate!),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
      return;
    }

    // If only category info is present, but treatment is missing
    if (appState.department != null &&
        appState.doctor != null &&
        (appState.treatment == null ||
            appState.procedureDate == null ||
            appState.procedureTime == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TreatmentScreenMain(userName: appState.username ?? "User")),
        );
      });
      return;
    }

    // If nothing, go to category
    if (appState.department == null || appState.doctor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CategoryScreen()),
        );
      });
      return;
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Fallback to WelcomeScreen if not auto-logged in
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
            appState.setDepartment(userDetails['department']);
            appState.setDoctor(userDetails['doctor']);
            appState.setTreatment(userDetails['treatment'], subtype: userDetails['treatment_subtype']);
            appState.procedureDate = userDetails['procedure_date'] != null
                ? DateTime.parse(userDetails['procedure_date'])
                : null;
            appState.procedureTime = parseTimeOfDay(userDetails['procedure_time']);
            appState.procedureCompleted =
                userDetails['procedure_completed'] == true;
          }

          // Now repeat the auto-skip logic after login
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (appState.department != null &&
                appState.doctor != null &&
                appState.treatment != null &&
                appState.procedureDate != null &&
                appState.procedureTime != null &&
                appState.procedureCompleted == false) {
              if (appState.treatment == 'Prosthesis' && appState.treatmentSubtype == 'Fixed') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PFDInstructionsScreen(date: appState.procedureDate!),
                  ),
                );
              } else if (appState.treatment == 'Prosthesis' && appState.treatmentSubtype == 'Removable') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PRDInstructionsScreen(date: appState.procedureDate!),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            } else if (appState.department != null &&
                appState.doctor != null &&
                (appState.treatment == null ||
                    appState.procedureDate == null ||
                    appState.procedureTime == null)) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => TreatmentScreenMain(userName: appState.username ?? "User")),
              );
            } else if (appState.department == null || appState.doctor == null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CategoryScreen()),
              );
            }
          });
        }
      },
    );
  }
}