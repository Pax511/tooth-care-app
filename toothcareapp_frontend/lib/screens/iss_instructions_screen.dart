import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';

class ISSInstructionsScreen extends StatefulWidget {
  final DateTime date;
  const ISSInstructionsScreen({Key? key, required this.date}) : super(key: key);

  @override
  State<ISSInstructionsScreen> createState() => _ISSInstructionsScreenState();
}

class _ISSInstructionsScreenState extends State<ISSInstructionsScreen> {
  static const List<String> doList = [
    "Eat soft cold foods for at least 2 days.",
    "Avoid hot, spicy, hard foods.",
    "Consume tea, coffee at room temperature.",
    "Take medicines as prescribed by your doctor.",
  ];
  static const List<String> dontList = [
    "Do not smoke/drink alcohol for 48 hours post extraction.",
    "Do not spit outside for 2 days and do not use straw for first 24 hours.",
  ];

  static const int totalDays = 15;
  late int currentDay;
  late List<bool> _dosChecked;

  String _generalChecklistKey(int day) => "iss_implant_second_dos_day$day";

  @override
  void initState() {
    super.initState();

    final procedureDate = DateTime(widget.date.year, widget.date.month, widget.date.day);
    final now = DateTime.now();
    int day = now.difference(procedureDate).inDays + 1;
    if (day < 1) day = 1;
    if (day > totalDays) day = totalDays;
    currentDay = day;

    final appState = Provider.of<AppState>(context, listen: false);
    _dosChecked = List<bool>.from(appState.getChecklistForKey(_generalChecklistKey(currentDay)));
    if (_dosChecked.length != doList.length) {
      _dosChecked = List.filled(doList.length, false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setChecklistForKey(_generalChecklistKey(currentDay), _dosChecked);
      });
    }
  }

  void _updateChecklist(int idx, bool value) {
    setState(() {
      _dosChecked[idx] = value;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey(_generalChecklistKey(currentDay), _dosChecked);

    // Log (or update) only the changed instruction immediately for correct progress chart
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addInstructionLog(
      doList[idx],
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
      title =
      "Instructions (${treatment}${subtype != null && subtype.isNotEmpty ? " - $subtype" : ""})";
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
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFFF6F2FD),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$title (Day $currentDay)",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Text(
                                "Do's (Day $currentDay)",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                              doList.length,
                                  (i) => Padding(
                                padding: const EdgeInsets.only(
                                    left: 8, top: 0, bottom: 0),
                                child: CheckboxListTile(
                                  contentPadding: const EdgeInsets.only(
                                      left: 20, right: 0),
                                  controlAffinity:
                                  ListTileControlAffinity.leading,
                                  dense: true,
                                  title: Text(
                                    doList[i],
                                    style:
                                    const TextStyle(fontSize: 15),
                                  ),
                                  value: _dosChecked[i],
                                  onChanged: (bool? value) {
                                    _updateChecklist(i, value ?? false);
                                  },
                                  activeColor: Colors.green,
                                  checkboxShape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(5),
                                  ),
                                ),
                              )),
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE6E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 10),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.cancel,
                                          color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        "Don'ts",
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...dontList.map((item) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: 28, top: 4, bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.close,
                                            color: Colors.red, size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(item,
                                              style: const TextStyle(
                                                  fontSize: 15)),
                                        )
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.menu_book,
                                  color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              label: const Text(
                                "View Specific Instructions",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const ISSSpecificInstructionsScreen(),
                                  ),
                                );
                              },
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
                        padding:
                        const EdgeInsets.symmetric(vertical: 15),
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

class ISSSpecificInstructionsScreen extends StatefulWidget {
  const ISSSpecificInstructionsScreen({super.key});

  @override
  State<ISSSpecificInstructionsScreen> createState() =>
      _ISSSpecificInstructionsScreenState();
}

class _ISSSpecificInstructionsScreenState
    extends State<ISSSpecificInstructionsScreen> {
  final List<String> specificInstructions = [
    "Bite firmly on the gauze placed in your mouth for at least 45–60 minutes and then gently remove the pack.",
    "After going home, apply ice pack on the area in 15–20 minute intervals till nighttime.",
    "After removing the pack, take one dosage of medicines prescribed.",
    "After 24 hours, gargle in that area with lukewarm water and salt at least 3–4 times a day.",
  ];

  static const int totalDays = 15;
  late int currentDay;
  late List<bool> _checked;

  String _specificChecklistKey(int day) => "iss_implant_second_specific_day$day";

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    // Use the procedure date from AppState or fallback to today
    final procedureDate = appState.procedureDate != null
        ? DateTime(appState.procedureDate!.year, appState.procedureDate!.month, appState.procedureDate!.day)
        : DateTime.now();

    final now = DateTime.now();
    int day = now.difference(procedureDate).inDays + 1;
    if (day < 1) day = 1;
    if (day > totalDays) day = totalDays;
    currentDay = day;

    _checked = List<bool>.from(appState.getChecklistForKey(_specificChecklistKey(currentDay)));
    if (_checked.length != specificInstructions.length) {
      _checked = List.filled(specificInstructions.length, false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setChecklistForKey(_specificChecklistKey(currentDay), _checked);
      });
    }
  }

  void _updateSpecific(int index, bool value) {
    setState(() {
      _checked[index] = value;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey(_specificChecklistKey(currentDay), _checked);

    // Log (or update) only the changed instruction immediately for correct progress chart
    final appState = Provider.of<AppState>(context, listen: false);
    appState.addInstructionLog(
      specificInstructions[index],
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
    final appState = Provider.of<AppState>(context, listen: false);
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
          "Specific Instructions${treatment != null ? " (${treatment}${subtype != null ? " - $subtype" : ""})" : ""} - Day $currentDay",
          style: const TextStyle(
              color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 24.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Specific Instructions: (Day $currentDay)",
                    style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(specificInstructions.length, (i) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 14),
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
                                specificInstructions[i],
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
                                  _updateSpecific(i, val ?? false),
                              activeColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(5)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
                        padding:
                        const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "Go to Dashboard",
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