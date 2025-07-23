import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';

class RootCanalInstructionsScreen extends StatefulWidget {
  final DateTime date;
  const RootCanalInstructionsScreen({Key? key, required this.date}) : super(key: key);


  @override
  State<RootCanalInstructionsScreen> createState() => _RootCanalInstructionsScreenState();
}

class _RootCanalInstructionsScreenState extends State<RootCanalInstructionsScreen> {
  static const List<String> generalInstructions = [
    "If your lips or tongue feel numb avoid chewing on that side till numbness wears off.",
    "If multiple appointments are required, do not bite hard/sticky food from the operated site till the completion of treatment.",
    "A putty-like material is placed in your tooth after completion of your treatment which is temporary; To protect and help keep your temporary in place.",
    "Avoid chewing sticky foods, especially on side of filling.",
    "Avoid biting hard foods and hard substances, such as ice, fingernails and pencils.",
    "If possible, chew only on the opposite side of your mouth.",
    "It's important to continue to brush and floss regularly and normally.",
  ];

  late List<bool> _generalChecked;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);

    _generalChecked = List<bool>.from(appState.getChecklistForKey("root_canal_general"));
    if (_generalChecked.length != generalInstructions.length) {
      _generalChecked = List.filled(generalInstructions.length, false);
      appState.setChecklistForKey("root_canal_general", _generalChecked);
    }
  }

  void _updateGeneral(int idx, bool? value) {
    setState(() {
      _generalChecked[idx] = value ?? false;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey("root_canal_general", _generalChecked);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final treatment = appState.treatment;
    final subtype = appState.treatmentSubtype;

    String title = "General Instructions";
    if (treatment != null) {
      title = "Instructions (${treatment}${subtype != null && subtype.isNotEmpty ? " - $subtype" : ""})";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green.shade200, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "General Instructions",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                            generalInstructions.length,
                                (i) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: CheckboxListTile(
                                value: _generalChecked[i],
                                onChanged: (val) => _updateGeneral(i, val),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                                title: Text(
                                  generalInstructions[i],
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RootCanalSpecificInstructionsScreen(),
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
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

// Specific Instructions screen for Root Canal
class RootCanalSpecificInstructionsScreen extends StatefulWidget {
  const RootCanalSpecificInstructionsScreen({super.key});

  @override
  State<RootCanalSpecificInstructionsScreen> createState() => _RootCanalSpecificInstructionsScreenState();
}

class _RootCanalSpecificInstructionsScreenState extends State<RootCanalSpecificInstructionsScreen> {
  static const List<String> specificInstructions = [
    "DO NOT EAT anything for 1 hr post-treatment completion.",
    "If you are experiencing discomfort, apply an ice pack on the area in 10 minutes ON 5 minutes OFF intervals for up to an hour.",
    "DO NOT SMOKE for the 1st day after treatment.",
  ];

  List<bool> _checked = List.filled(specificInstructions.length, false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Specific Instructions (Root Canal)",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Specific Instructions:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    specificInstructions.length,
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
                            // Step number
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
                            // Instruction and meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    specificInstructions[i],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (i == 0)
                                    Row(
                                      children: const [
                                        Icon(Icons.warning_amber_rounded,
                                            color: Colors.red, size: 18),
                                        SizedBox(width: 6),
                                        Text("Today 8:00 AM",
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  if (i == 1)
                                    Row(
                                      children: const [
                                        Icon(Icons.event_available,
                                            color: Colors.green, size: 18),
                                        SizedBox(width: 6),
                                        Text("Today 9:00 AM",
                                            style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  if (i == 2)
                                    Row(
                                      children: const [
                                        Icon(Icons.smoke_free,
                                            color: Colors.orange, size: 18),
                                        SizedBox(width: 6),
                                        Text("No smoking for 1 day",
                                            style: TextStyle(
                                                color: Colors.orange,
                                                fontSize: 14)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: _checked[i],
                              onChanged: (val) =>
                                  setState(() => _checked[i] = val ?? false),
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
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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