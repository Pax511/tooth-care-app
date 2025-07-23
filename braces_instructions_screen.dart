import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';

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

  late List<bool> _dosChecked;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);

    _dosChecked = List<bool>.from(appState.getChecklistForKey("braces_dos"));
    if (_dosChecked.length != bracesDos.length) {
      _dosChecked = List.filled(bracesDos.length, false);
      appState.setChecklistForKey("braces_dos", _dosChecked);
    }
  }

  void _updateDos(int idx, bool? value) {
    setState(() {
      _dosChecked[idx] = value ?? false;
    });
    Provider.of<AppState>(context, listen: false)
        .setChecklistForKey("braces_dos", _dosChecked);
  }

  @override
  Widget build(BuildContext context) {
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
                  // Do's Section with Checklist
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
                              "Do's",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(
                            bracesDos.length,
                                (i) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: CheckboxListTile(
                                value: _dosChecked[i],
                                onChanged: (val) => _updateDos(i, val),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
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
                      border: Border.all(color: Colors.red.shade200, width: 2),
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
                                (i) => Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.close, color: Colors.red, size: 20),
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