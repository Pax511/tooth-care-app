import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';

class FillingInstructionsScreen extends StatefulWidget {
  const FillingInstructionsScreen({super.key});

  @override
  State<FillingInstructionsScreen> createState() =>
      _FillingInstructionsScreenState();
}

class _FillingInstructionsScreenState
    extends State<FillingInstructionsScreen> {
  static const List<String> fillingDos = [
    "Eat soft cold foods for at least 2 days.",
    "Avoid hot, spicy, hard foods.",
    "Consume tea, coffee at room temperature.",
    "Take medicines as prescribed by your doctor.",
  ];

  static const List<String> fillingDonts = [
    "Do not smoke/drink alcohol for 48 hours post extraction.",
    "Do not spit outside for 2 days and do not use straw for first 24 hours.",
  ];

  static const int totalDays = 15;
  late int currentDay;
  late List<bool> _dosChecked;

  String _generalChecklistKey(int day) => "filling_dos_day$day";

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<AppState>(context, listen: false);
    final procedureDate = appState.procedureDate != null
        ? DateTime(appState.procedureDate!.year, appState.procedureDate!.month, appState.procedureDate!.day)
        : DateTime.now();

    final now = DateTime.now();
    int day = now.difference(procedureDate).inDays + 1;
    if (day < 1) day = 1;
    if (day > totalDays) day = totalDays;
    currentDay = day;

    _dosChecked = List<bool>.from(appState.getChecklistForKey(_generalChecklistKey(currentDay)));
    if (_dosChecked.length != fillingDos.length) {
      _dosChecked = List.filled(fillingDos.length, false);
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

    final appState = Provider.of<AppState>(context, listen: false);
    appState.addInstructionLog(
      fillingDos[idx],
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
    final appState = Provider.of<AppState>(context);
    final treatment = appState.treatment;
    final subtype = appState.treatmentSubtype;

    String title = "General Instructions";
    if (treatment != null) {
      title = "Instructions ($treatment${(subtype != null && subtype.isNotEmpty) ? " - $subtype" : ""})";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 40.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$title (Day $currentDay)",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Do's Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green.shade200, width: 2),
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
                            fillingDos.length,
                                (i) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: CheckboxListTile(
                                value: _dosChecked[i],
                                onChanged: (val) => _updateDos(i, val),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                ListTileControlAffinity.leading,
                                dense: true,
                                title: Text(
                                  fillingDos[i],
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
                  // Don'ts Section
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2F2),
                      border: Border.all(color: Colors.red.shade200, width: 2),
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
                            fillingDonts.length,
                                (i) => Padding(
                              padding:
                              const EdgeInsets.only(left: 4, bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.close,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fillingDonts[i],
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
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.menu_book, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      label: const Text(
                        "View Specific Instructions",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                            const FillingSpecificInstructionsScreen(),
                          ),
                        );
                      },
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
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
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

// Specific Instructions screen for Filling
class FillingSpecificInstructionsScreen extends StatefulWidget {
  const FillingSpecificInstructionsScreen({super.key});

  @override
  State<FillingSpecificInstructionsScreen> createState() =>
      _FillingSpecificInstructionsScreenState();
}

class _FillingSpecificInstructionsScreenState
    extends State<FillingSpecificInstructionsScreen> {
  static const List<String> fillingSpecificInstructions = [
    "Bite firmly on the gauze placed in your mouth for at least 45-60 minutes and then gently remove the pack.",
    "After going home, apply ice pack on the area in 15-20 minute intervals till nighttime.",
    "After removing the pack, take one dosage of medicines prescribed.",
    "After 24 hours, gargle in that area with lukewarm water and salt at least 3-4 times a day."
  ];

  static const int totalDays = 15;
  late int currentDay;
  late List<bool> _checked;

  String _specificChecklistKey(int day) => "filling_specific_day$day";

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    final procedureDate = appState.procedureDate != null
        ? DateTime(appState.procedureDate!.year, appState.procedureDate!.month, appState.procedureDate!.day)
        : DateTime.now();

    final now = DateTime.now();
    int day = now.difference(procedureDate).inDays + 1;
    if (day < 1) day = 1;
    if (day > totalDays) day = totalDays;
    currentDay = day;

    _checked = List<bool>.from(appState.getChecklistForKey(_specificChecklistKey(currentDay)));
    if (_checked.length != fillingSpecificInstructions.length) {
      _checked = List.filled(fillingSpecificInstructions.length, false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setChecklistForKey(_specificChecklistKey(currentDay), _checked);
      });
    }
  }

  void _updateSpecificChecklist(int index, bool value) {
    setState(() {
      _checked[index] = value;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey(_specificChecklistKey(currentDay), _checked);

    final appState = Provider.of<AppState>(context, listen: false);
    appState.addInstructionLog(
      fillingSpecificInstructions[index],
      date: DateTime.now().toIso8601String().split('T')[0],
      type: 'specific',
      followed: _checked[index],
      username: appState.username,
      treatment: appState.treatment,
      subtype: appState.treatmentSubtype,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final treatment = appState.treatment;
    final subtype = appState.treatmentSubtype;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Specific Instructions (${treatment != null ? treatment : ''}${(subtype != null && subtype.isNotEmpty) ? " - $subtype" : ""}) - Day $currentDay",
          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Specific Instructions: (Day $currentDay)",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    fillingSpecificInstructions.length,
                        (i) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.lightBlue[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Step ${i + 1}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                fillingSpecificInstructions[i],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Checkbox(
                              value: _checked[i],
                              onChanged: (val) =>
                                  _updateSpecificChecklist(i, val ?? false),
                              activeColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                            ),
                          ],
                        ),
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
                        "Go to Dashboard",
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
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