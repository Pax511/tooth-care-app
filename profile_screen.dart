import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final patientId = "#1";
    final fullName = appState.fullName ?? "Not specified";
    final dob = appState.dob != null
        ? "${appState.dob!.day}/${appState.dob!.month}/${appState.dob!.year}"
        : "Not specified";
    final gender = appState.gender ?? "Not specified";
    final username = appState.username ?? "Not specified";
    final phone = appState.phone ?? "Not specified";
    final email = appState.email ?? "Not specified";
    final procedureDate = appState.procedureDate;
    final today = DateTime.now();
    final recoveryDay = procedureDate != null
        ? (today.difference(DateTime(procedureDate.year, procedureDate.month, procedureDate.day)).inDays + 1)
        : 0;

    // Use currentDos plus your static checklist items
    final dosList = [
      ...appState.currentDos,
      "Eat soft cold foods for at least 2 days.",
      "Use warm salt water rinse as instructed.",
      "Eat your medicine as prescribed by your dentist.",
      "Drink plenty of fluids (without using a straw).",
      "Take medicines as prescribed by your doctor."
    ];
    final checks = appState.getChecklistForDate(today);

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
                  // Header
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
                          'Patient Profile',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Your recovery information",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Personal Information Card
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.person_outline, color: Color(0xFF2196F3)),
                              SizedBox(width: 8),
                              Text('Personal Information',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Icon(Icons.account_circle, size: 54, color: Colors.blueGrey),
                          const SizedBox(height: 8),
                          Text(fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                          Text('Patient ID: $patientId',
                              style: const TextStyle(color: Colors.grey, fontSize: 15)),
                          const SizedBox(height: 16),

                          _infoTile(Icons.badge, 'Full Name', fullName, Colors.blue[50]!),
                          _infoTile(Icons.cake, 'Date of Birth', dob, Colors.blue[50]!),
                          _infoTile(Icons.person, 'Gender', gender, Colors.blue[50]!),
                          _infoTile(Icons.account_circle, 'Username', username, Colors.blue[50]!),
                          _infoTile(Icons.phone, 'Phone', phone, Colors.blue[50]!),
                          _infoTile(Icons.email, 'Email', email, Colors.blue[50]!),
                          const SizedBox(height: 16),
                          _infoTile(
                            Icons.calendar_today,
                            'Procedure Date',
                            procedureDate != null
                                ? "${procedureDate.day}/${procedureDate.month}/${procedureDate.year}"
                                : "-",
                            const Color(0xFFE8F0FE),
                          ),
                          _infoTile(
                            Icons.bar_chart,
                            'Recovery Day',
                            "Day $recoveryDay",
                            const Color(0xFFFFF6E5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Emergency Contact
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.local_phone, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text("Emergency Contact",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE6E6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Dental Office",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.redAccent,
                                        fontSize: 16)),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 18, color: Colors.redAccent),
                                    SizedBox(width: 6),
                                    Text("(555) 123-4567", style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.email, size: 18, color: Colors.redAccent),
                                    SizedBox(width: 6),
                                    Text("emergency@dentalcare.com", style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Call immediately if you experience:",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "• Severe pain not relieved by medication\n"
                                "• Excessive bleeding after 24 hours\n"
                                "• Signs of infection (fever, pus, severe swelling)\n"
                                "• Numbness lasting more than 24 hours",
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Today's Checklist
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Checklist",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 14),
                          ...List.generate(dosList.length, (i) {
                            final checked = i < checks.length ? checks[i] : false;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    checked ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: checked ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(dosList[i])),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Quick Actions
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Quick Actions",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                DefaultTabController.of(context)?.animateTo(2);
                                Navigator.of(context).maybePop();
                              },
                              child: const Text("View Care Instructions",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () {
                                DefaultTabController.of(context)?.animateTo(1);
                                Navigator.of(context).maybePop();
                              },
                              child: const Text("Check Recovery Calendar",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
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

  static Widget _infoTile(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15))),
          Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
