import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import 'home_screen.dart';

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
  late List<bool> _dosChecked;

  // Specific Instructions Steps
  final List<String> specificSteps = [
    "Bite firmly on the gauze placed in your mouth for at least 45-60 minutes and then gently remove the pack. (Today 8:00 AM)",
    "After going home, apply ice pack on the area in 15-20 minute intervals till nighttime. (Tomorrow 9:00 AM)",
    "After removing the pack, take one dosage of medicines prescribed.",
    "After 24 hours, gargle in that area with lukewarm water and salt at least 3-4 times a day.",
  ];
  late List<bool> _specificChecked;

  bool showSpecific = false;

  @override
  void initState() {
    super.initState();
    _dosChecked = List.filled(dosList.length, false);
    _specificChecked = List.filled(specificSteps.length, false);
  }

  void _updateChecklist(int idx, bool value) {
    setState(() {
      _dosChecked[idx] = value;
    });
  }

  void _updateSpecificChecklist(int idx, bool value) {
    setState(() {
      _specificChecked[idx] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If showSpecific is true, show the specific instructions checklist, else general
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
        title: const Text(
          "Specific Instructions",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      )
          : null,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showSpecific) ...[
                    const Text(
                      "General Instructions:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                    ),
                    const SizedBox(height: 18),
                    // Do's Block
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
                            ...List.generate(dosList.length, (i) => Padding(
                              padding: const EdgeInsets.only(left: 4, top: 0, bottom: 0),
                              child: CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                dense: true,
                                title: Text(
                                  dosList[i],
                                  style: const TextStyle(fontSize: 15, color: Colors.green, fontWeight: FontWeight.w600),
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
                        border: Border.all(color: Colors.red.shade200, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
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
                            ...dontsList.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5.0),
                                    child: Icon(Icons.close, color: Colors.red, size: 18),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.w600),
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
                  ] else ...[
                    const Text(
                      "To-Do List After Tooth Extraction",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(specificSteps.length, (i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.only(left: 10, right: 0),
                        controlAffinity: ListTileControlAffinity.leading,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}