import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    fetchProgressEntries();
  }

  Future<void> fetchProgressEntries() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final response = await ApiService.getProgressEntries(); // ✅ FIXED API call

    if (response != null) {
      appState.clearProgressFeedback();
      for (var entry in response) {
        final message = entry["message"]?.toString() ?? "";
        final timestamp = entry["timestamp"]?.toString().split("T")[0] ?? "";
        appState.addProgressFeedback("Entry", message, date: timestamp);
      }
      setState(() {});
    }
  }

  Future<void> submitFeedback(String message) async {
    final success = await ApiService.submitProgress(message); // ✅ FIXED API call

    if (success) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addProgressFeedback("Entry", message);
      await fetchProgressEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit feedback"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final procedureDate = appState.procedureDate ?? DateTime.now();
    final today = DateTime.now();
    final int daysSinceProcedure = today.difference(
      DateTime(procedureDate.year, procedureDate.month, procedureDate.day),
    ).inDays + 1;

    final entries = appState.progressFeedback;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(22),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Recovery Progress',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Monitor your recovery day by day",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 28),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Text(
                              'Summary',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Days since procedure',
                                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$daysSinceProcedure',
                                        style: const TextStyle(
                                          color: Color(0xFF2196F3),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 26,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text('days', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2FBF3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Expected healing',
                                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '7-14',
                                        style: TextStyle(
                                          color: Color(0xFF22B573),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 26,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Text('days', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                      child: Text(
                        "Your Progress Entries",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey[900]),
                      ),
                    ),
                  ),
                  if (entries.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36.0),
                      child: const Text(
                        "No progress entries yet.\nAdd your first entry below!",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...entries.map((entry) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(entry["title"] ?? ""),
                        subtitle: Text(entry["note"] ?? ""),
                        trailing: Text(entry["date"] ?? ""),
                      ),
                    )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.feedback),
                      label: const Text(
                        "Patient's Feedback",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final feedbackController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Patient's Feedback"),
                              content: TextField(
                                controller: feedbackController,
                                minLines: 3,
                                maxLines: 8,
                                decoration: const InputDecoration(
                                  hintText: "Enter patient's feedback on your progress...",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final message = feedbackController.text.trim();
                                    if (message.isNotEmpty) {
                                      Navigator.of(context).pop();
                                      submitFeedback(message);
                                    }
                                  },
                                  child: const Text("Submit"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
