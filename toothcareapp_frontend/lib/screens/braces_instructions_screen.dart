import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';
import 'treatment_screen.dart';

class BracesInstructionsScreen extends StatefulWidget {
  final DateTime? date;

  const BracesInstructionsScreen({super.key, this.date});
  @override
  State<BracesInstructionsScreen> createState() => _BracesInstructionsScreenState();
}

class _BracesInstructionsScreenState extends State<BracesInstructionsScreen> {
  static const List<String> bracesDos = [
    "Brush your teeth and rinse your mouth carefully after every meal.",
    "Floss daily (if possible).",
    "Attend all your orthodontic appointments.",
  ];

  static const List<String> bracesDonts = [
    "Don’t eat foods that can damage or loosen your braces, particularly chewy, hard, or sticky foods (e.g., ice, popcorn, candies, toffee, etc.).",
    "Don’t bite your nails or chew on pencils.",
  ];

  static const int totalDays = 15;
  late int currentDay;
  late List<bool> _dosChecked;

  String _generalChecklistKey(int day) => "braces_dos_day$day";

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final procedureDate = widget.date != null
        ? DateTime(widget.date!.year, widget.date!.month, widget.date!.day)
        : DateTime.now();
    int day = now.difference(procedureDate).inDays + 1;
    if (day < 1) day = 1;
    if (day > totalDays) day = totalDays;
    currentDay = day;

    final appState = Provider.of<AppState>(context, listen: false);

    _dosChecked = List<bool>.from(appState.getChecklistForKey(_generalChecklistKey(currentDay)));
    if (_dosChecked.length != bracesDos.length) {
      _dosChecked = List.filled(bracesDos.length, false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setChecklistForKey(_generalChecklistKey(currentDay), _dosChecked);
      });
    }
  }

  void _updateDos(int idx, bool? value) {
    setState(() {
      _dosChecked[idx] = value ?? false;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey(_generalChecklistKey(currentDay), _dosChecked);

    // Log (or update) only the changed instruction immediately for correct progress chart
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addInstructionLog(
      bracesDos[idx],
      date: DateTime.now().toIso8601String().split('T')[0],
      type: 'general',
      followed: _dosChecked[idx],
      username: appState.username,
      treatment: appState.treatment,
      subtype: appState.treatmentSubtype,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentDay >= totalDays) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated check/celebration
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: child,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(22),
                    child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF2ECC71), size: 64),
                  ),
                ),
                const SizedBox(height: 28),
                // Elevated card for message
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
                    child: Column(
                      children: const [
                        Text(
                          "Recovery Complete!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Congratulations! Your procedure recovery is complete. You can now select a new treatment.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                // Modern rounded button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 22),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.2,
                      ),
                    ),
                    label: const Text("Select Different Treatment"),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => TreatmentScreenMain(userName: "User")),
                            (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }else {
      final appState = Provider.of<AppState>(context);
      final treatment = appState.treatment;

      String title = "General Instructions";
      if (treatment != null) {
        title = "Instructions (${treatment})";
      }

      return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 40.0, horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$title (Day $currentDay)",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Do's Section with Checklist
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green.shade200,
                            width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Do's (Day $currentDay)",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              bracesDos.length,
                                  (i) =>
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: CheckboxListTile(
                                      value: _dosChecked[i],
                                      onChanged: (val) => _updateDos(i, val),
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity: ListTileControlAffinity
                                          .leading,
                                      dense: true,
                                      title: Text(
                                        bracesDos[i],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      activeColor: Colors.green,
                                      checkboxShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Don'ts Section (no checklist)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF2F2),
                        border: Border.all(color: Colors.red.shade200,
                            width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Don'ts",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(
                              bracesDonts.length,
                                  (i) =>
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        const Icon(
                                            Icons.close, color: Colors.red,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            bracesDonts[i],
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          "Continue to Dashboard",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                                (route) => false,
                          );
                        },
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
}