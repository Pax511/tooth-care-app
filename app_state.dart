import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // User details
  String? fullName;
  DateTime? dob;
  String? gender;
  String? username;
  String? password;
  String? phone;
  String? email;
  String? token;

  // Procedure details
  DateTime? procedureDate;
  TimeOfDay? procedureTime;

  // Private fields for department, doctor, treatment & subtype
  String? _department;
  String? _doctor;
  String? _treatment;
  String? _treatmentSubtype;
  String? _implantStage;

  // Checklist data
  final Map<String, List<bool>> _dailyChecklist = {};
  final Map<String, List<bool>> _persistedChecklists = {};

  // Getter for treatment info
  String? get department => _department;
  String? get doctor => _doctor;
  String? get treatment => _treatment;
  String? get treatmentSubtype => _treatmentSubtype;
  String? get implantStage => _implantStage;

  // Treatment instructions mapping (unchanged)
  final Map<String, List<String>> _treatmentInstructions = {
    // Populate your actual instruction mapping here
  };

  List<String> get currentTreatmentInstructions {
    if (_treatment == null) return [];

    final baseInstructions = _treatmentInstructions[_treatment!] ?? [];

    if (_treatmentSubtype != null && _treatmentSubtype!.isNotEmpty) {
      final subtypeKey = '$_treatment:$_treatmentSubtype';
      final subtypeInstructions = _treatmentInstructions[subtypeKey] ?? [];
      return [...baseInstructions, ...subtypeInstructions]; // ✅ include both
    }

    return baseInstructions;
  }

  List<String> get currentDos => currentTreatmentInstructions.take(4).toList();
  List<String> get currentDonts =>
      currentTreatmentInstructions.skip(4).take(2).toList();
  List<String> get currentSpecificSteps =>
      currentTreatmentInstructions.skip(6).toList();

  void setUserDetails({
    required String fullName,
    required DateTime dob,
    required String gender,
    required String username,
    required String password,
    required String phone,
    required String email,
  }) {
    this.fullName = fullName;
    this.dob = dob;
    this.gender = gender;
    this.username = username;
    this.password = password;
    this.phone = phone;
    this.email = email;
    notifyListeners();
  }

  void setLoginDetails(String username, String password) {
    this.username = username;
    this.password = password;
    notifyListeners();
  }

  void setToken(String token) {
    this.token = token;
    notifyListeners();
  }

  void setDepartment(String? value) {
    if (_department != value) {
      _department = value;
      notifyListeners();
    }
  }

  void setDoctor(String? value) {
    if (_doctor != value) {
      _doctor = value;
      notifyListeners();
    }
  }

  void setTreatment(String? treatment, {String? subtype, DateTime? procedureDate}) {
    if (_treatment != treatment || _treatmentSubtype != subtype) {
      _treatment = treatment;
      _treatmentSubtype = subtype;

      if (treatment == 'Implant' && subtype != null) {
        final parts = subtype.split('\n').first.trim();
        _implantStage = parts;
      } else {
        _implantStage = null;
      }

      if (procedureDate != null) {
        this.procedureDate = procedureDate;
      }

      notifyListeners();
    }
  }


  void setProcedureDateTime(DateTime date, TimeOfDay time) {
    procedureDate = date;
    procedureTime = time;
    notifyListeners();
  }

  List<bool> getChecklistForDate(DateTime date) {
    final key = _dateKey(date);
    final n = currentDos.length;
    return List<bool>.from(_dailyChecklist[key] ?? List.filled(n, false));
  }

  void setChecklistForDate(DateTime date, List<bool> values) {
    final key = _dateKey(date);
    _dailyChecklist[key] = List<bool>.from(values);
    notifyListeners();
  }

  List<bool> getChecklistForKey(String key) {
    return _persistedChecklists[key] ?? [];
  }

  void setChecklistForKey(String key, List<bool> list) {
    _persistedChecklists[key] = List<bool>.from(list);
    notifyListeners();
  }

  void reset() {
    fullName = null;
    dob = null;
    gender = null;
    username = null;
    password = null;
    phone = null;
    email = null;
    token = null;
    procedureDate = null;
    procedureTime = null;
    _department = null;
    _doctor = null;
    _treatment = null;
    _treatmentSubtype = null;
    _implantStage = null;
    _dailyChecklist.clear();
    _persistedChecklists.clear();
    _progressFeedback.clear();
    notifyListeners();
  }

  static String _dateKey(DateTime date) =>
      "${date.year.toString().padLeft(4, '0')}-"
          "${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')}";

  final List<Map<String, String>> _progressFeedback = [];

  List<Map<String, String>> get progressFeedback =>
      List.unmodifiable(_progressFeedback);

  void addProgressFeedback(String title, String note, {String? date}) {
    final now = DateTime.now();
    final formattedDate = date ??
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _progressFeedback.add({
      'title': title,
      'note': note,
      'date': formattedDate,
    });
    notifyListeners();
  }

  void clearProgressFeedback() {
    _progressFeedback.clear();
    notifyListeners();
  }
}
