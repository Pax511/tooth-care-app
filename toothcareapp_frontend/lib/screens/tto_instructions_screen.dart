import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';
import 'treatment_screen.dart';

class TTOInstructionsScreen extends StatefulWidget {
  final DateTime date;
  const TTOInstructionsScreen({Key? key, required this.date}) : super(key: key);

  @override
  State<TTOInstructionsScreen> createState() => _TTOInstructionsScreenState();
}

class _TTOInstructionsScreenState extends State<TTOInstructionsScreen> {
  // General Instructions
  final List<String> dosList = [
    "Eat soft cold foods for at least 2 days.",
    "Avoid hot, spicy, hard foods.",
    "Consume tea, coffee at room temperature.",
    "Take medicines as prescribed by your doctor.",
  ];
  final List<String> dontsList = [
    "Do not smoke/drink alcohol for 48 hours post extraction.",
    "Do not spit outside for 2 days and do not use straw for first 24 hours.",
  ];

  // Track checklist per day for 15 days
  static const int totalDays = 15;
  late int currentDay;

  late List<bool> _dosChecked;
  late List<bool> _specificChecked;

  // Specific Instructions Steps
  final List<String> specificSteps = [
    "Bite firmly on the gauze placed in your mouth for at least 45-60 minutes and then gently remove the pack. (Today 8:00 AM)",
    "After going home, apply ice pack on the area in 15-20 minute intervals till nighttime. (Tomorrow 9:00 AM)",
    "After removing the pack, take one dosage of medicines prescribed.",
    "After 24 hours, gargle in that area with lukewarm water and salt at least 3-4 times a day.",
  ];

  bool showSpecific = false;

  String _generalChecklistKey(int day) => "tto_general_dos_day$day";
  String _specificChecklistKey(int day) => "tto_specific_steps_day$day";

  @override
  void initState() {
    super.initState();
    // Calculate current day (1 to 15), clamp if > 15
    final now = DateTime.now();
    final procedureDate = DateTime(widget.date.year, widget.date.month, widget.date.day);
    int day = now.difference(procedureDate).inDays + 1;
    if (day < 1) day = 1;
    if (day > totalDays) day = totalDays;
    currentDay = day;

    final appState = Provider.of<AppState>(context, listen: false);

    // Load persisted Do’s checklist for the current day
    _dosChecked = List<bool>.from(appState.getChecklistForKey(_generalChecklistKey(currentDay)));
    if (_dosChecked.length != dosList.length) {
      _dosChecked = List.filled(dosList.length, false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setChecklistForKey(_generalChecklistKey(currentDay), _dosChecked);
      });
    }

    // Load persisted Specific Instructions checklist for the current day
    _specificChecked = List<bool>.from(appState.getChecklistForKey(_specificChecklistKey(currentDay)));
    if (_specificChecked.length != specificSteps.length) {
      _specificChecked = List.filled(specificSteps.length, false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setChecklistForKey(_specificChecklistKey(currentDay), _specificChecked);
      });
    }
  }

  void _updateChecklist(int idx, bool value) {
    setState(() {
      _dosChecked[idx] = value;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey(_generalChecklistKey(currentDay), _dosChecked);

    // FIX: Log (or update) only the changed instruction immediately
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addInstructionLog(
      dosList[idx],
      date: DateTime.now().toIso8601String().split('T')[0],
      type: "general",
      followed: value,
      username: appState.username,
      treatment: appState.treatment,
      subtype: appState.treatmentSubtype,
    );
  }

  void _updateSpecificChecklist(int idx, bool value) {
    setState(() {
      _specificChecked[idx] = value;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey(_specificChecklistKey(currentDay), _specificChecked);

    // FIX: Log (or update) only the changed instruction immediately
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addInstructionLog(
      specificSteps[idx],
      date: DateTime.now().toIso8601String().split('T')[0],
      type: "specific",
      followed: value,
      username: appState.username,
      treatment: appState.treatment,
      subtype: appState.treatmentSubtype,
    );
  }

  /// Build and push a dated record of which instructions were/weren't followed
  void _logInstructionStatusIfNeeded() {
    final appState = Provider.of<AppState>(context, listen: false);

    final String dateStr = widget.date.toLocal().toString().split(' ').first;

    // Collect not-followed general instructions for the current day
    final List<String> notFollowedGeneral = [];
    for (int i = 0; i < dosList.length; i++) {
      if (!_dosChecked[i]) notFollowedGeneral.add(dosList[i]);
    }

    // Collect not-followed specific instructions for the current day
    final List<String> notFollowedSpecific = [];
    for (int i = 0; i < specificSteps.length; i++) {
      if (!_specificChecked[i]) notFollowedSpecific.add(specificSteps[i]);
    }

    String buildSection(String title, List<String> list) {
      if (list.isEmpty) {
        return "$title: All followed ✅";
      }
      final buffer = StringBuffer("$title: Not followed ❌\n");
      for (final item in list) {
        buffer.writeln("• $item");
      }
      return buffer.toString().trimRight();
    }

    final String log = """
[Tooth Extraction] $dateStr (Day $currentDay)
${buildSection("General Instructions", notFollowedGeneral)}

${buildSection("Specific Instructions", notFollowedSpecific)}
""".trim();

    // Save to Progress Entries
    appState.addProgressFeedback("Instruction Log", log, date: dateStr);
  }

  void _goToDashboard() {
    _logInstructionStatusIfNeeded();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    int currentDay = totalDays; // at the start of build() or where currentDay is set
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
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: showSpecific
            ? AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () {
              setState(() => showSpecific = false);
            },
          ),
          title: Text(
            "Specific Instructions - Day $currentDay",
            style: const TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        )
            : null,
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
                    if (!showSpecific) ...[
                      Text(
                        "General Instructions: (Day $currentDay)",
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 19),
                      ),
                      const SizedBox(height: 18),
                      // Do's Block
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: Colors.green.shade200, width: 2),
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
                                child: const Text(
                                  "Do's",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(dosList.length, (i) =>
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 4, top: 0, bottom: 0),
                                    child: CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity: ListTileControlAffinity
                                          .leading,
                                      dense: true,
                                      title: Text(
                                        dosList[i],
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      value: _dosChecked[i],
                                      onChanged: (bool? value) {
                                        _updateChecklist(i, value ?? false);
                                      },
                                      activeColor: Colors.green,
                                      checkboxShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      // Don'ts Block (non-interactive)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: Colors.red.shade200, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
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
                              ...dontsList.map((item) =>
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 2.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 5.0),
                                          child: Icon(
                                              Icons.close, color: Colors.red,
                                              size: 18),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        )
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                              Icons.menu_book, color: Colors.white),
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
                            setState(() {
                              showSpecific = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          onPressed: _goToDashboard,
                        ),
                      ),
                    ] else
                      ...[
                        Text(
                          "To-Do List After Tooth Extraction (Day $currentDay)",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(specificSteps.length, (i) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0),
                              child: CheckboxListTile(
                                contentPadding: const EdgeInsets.only(
                                    left: 10, right: 0),
                                controlAffinity: ListTileControlAffinity
                                    .leading,
                                dense: true,
                                title: Text(
                                  specificSteps[i],
                                  style: const TextStyle(fontSize: 15),
                                ),
                                value: _specificChecked[i],
                                onChanged: (bool? value) {
                                  _updateSpecificChecklist(i, value ?? false);
                                },
                                activeColor: Colors.green,
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            )),
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
                            onPressed: _goToDashboard,
                          ),
                        ),
                      ],
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