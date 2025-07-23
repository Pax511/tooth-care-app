import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';

class PRDInstructionsScreen extends StatefulWidget {
  final DateTime date;
  const PRDInstructionsScreen({Key? key, required this.date}) : super(key: key);

  @override
  State<PRDInstructionsScreen> createState() => _PRDInstructionsScreenState();
}

class _PRDInstructionsScreenState extends State<PRDInstructionsScreen> {
  static const List<String> prdDos = [
    "Rinse your dentures after meals to remove food debris.",
    "Clean your dentures daily using a soft denture brush.",
    "Soak dentures in a denture cleanser overnight.",
    "Visit your dentist regularly to ensure proper fit.",
  ];

  static const List<String> prdDonts = [
    "Do not use hot water to clean dentures.",
    "Avoid dropping dentures on hard surfaces.",
    "Do not use harsh chemicals or bleach to clean dentures.",
  ];

  late List<bool> _dosChecked;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _dosChecked = List<bool>.from(appState.getChecklistForKey("prd_dos"));
    if (_dosChecked.length != prdDos.length) {
      _dosChecked = List.filled(prdDos.length, false);
      appState.setChecklistForKey("prd_dos", _dosChecked);
    }
  }

  void _updateChecklist(int idx, bool value) {
    setState(() {
      _dosChecked[idx] = value;
    });
    Provider.of<AppState>(context, listen: false).setChecklistForKey("prd_dos", _dosChecked);
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
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: const Color(0xFFF6F2FD),
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              const Text(
                                "Do's",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(prdDos.length, (i) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 0, bottom: 0),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.only(left: 20, right: 0),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              title: Text(prdDos[i], style: const TextStyle(fontSize: 15)),
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
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE6E6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.cancel, color: Colors.red),
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
                                  ...prdDonts.map((item) => Padding(
                                    padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.close, color: Colors.red, size: 18),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(item,
                                              style: const TextStyle(fontSize: 15)),
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
                              icon: const Icon(Icons.menu_book, color: Colors.white),
                              label: const Text(
                                "View Specific Instructions",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFA500), // Orange color
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PrdSpecificInstructionsScreen(),
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

// Add this screen in a separate file if needed
class PrdSpecificInstructionsScreen extends StatefulWidget {
  const PrdSpecificInstructionsScreen({super.key});

  @override
  State<PrdSpecificInstructionsScreen> createState() => _PrdSpecificInstructionsScreenState();
}

class _PrdSpecificInstructionsScreenState extends State<PrdSpecificInstructionsScreen> {
  final List<String> specificInstructions = [
    "Do not wear your dentures at night to allow gum rest.",
    "Avoid eating hard or sticky foods with new dentures.",
    "Report sore spots to your dentist immediately.",
    "Keep dentures in water when not wearing them.",
  ];

  List<bool> _checked = [];

  @override
  void initState() {
    super.initState();
    _checked = List.filled(specificInstructions.length, false);
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
          "Specific Instructions${treatment != null ? " (${treatment}${subtype != null ? " - $subtype" : ""})" : ""}",
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
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Specific Instructions:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(specificInstructions.length, (i) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.teal[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Step ${i + 1}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
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
                              onChanged: (val) => setState(() => _checked[i] = val ?? false),
                              activeColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
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
