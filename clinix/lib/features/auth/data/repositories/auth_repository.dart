import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/staff_model.dart';

class AuthRepository {
  static const String _sessionKey = 'clinix_staff_session';
  static const String _staffDirectoryKey = 'clinix_staff_directory';

  final SharedPreferences _preferences;

  AuthRepository(this._preferences);

  StaffModel? get currentStaff {
    final session = _preferences.getString(_sessionKey);

    if (session == null || session.isEmpty) {
      return null;
    }

    try {
      return StaffModel.fromJson(
        jsonDecode(session) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  bool get isLoggedIn => currentStaff != null;

  Future<StaffModel> login({
    required String staffId,
    required String password,
  }) async {
    final normalizedStaffId = staffId.trim().toUpperCase();

    if (!RegExp(r'^STAFF-\d{3}$').hasMatch(normalizedStaffId)) {
      throw const AuthException(
        'Staff ID must be in STAFF-001 format.',
      );
    }

    if (password != 'Clinix@123') {
      throw const AuthException(
        'Invalid Staff ID or password.',
      );
    }

    final existingStaff = _getStaffFromDirectory(
      normalizedStaffId,
    );

    final staff = existingStaff ??
        StaffModel(
          id: normalizedStaffId,
          name: _generateStaffName(normalizedStaffId),
          email:
              '${normalizedStaffId.toLowerCase()}@clinix.local',
          role: 'Clinical Staff',
          department: 'Clinical Care',
          status: 'Active',
        );

    await _saveStaffToDirectory(staff);

    await _preferences.setString(
      _sessionKey,
      jsonEncode(staff.toJson()),
    );

    return staff;
  }

  List<StaffModel> getStaffDirectory() {
    final data = _preferences.getStringList(
      _staffDirectoryKey,
    );

    if (data == null) {
      return [];
    }

    final staff = <StaffModel>[];

    for (final item in data) {
      try {
        staff.add(
          StaffModel.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        );
      } catch (_) {}
    }

    staff.sort(
      (a, b) => a.id.compareTo(b.id),
    );

    return staff;
  }

  StaffModel? _getStaffFromDirectory(
    String staffId,
  ) {
    for (final staff in getStaffDirectory()) {
      if (staff.id == staffId) {
        return staff;
      }
    }

    return null;
  }

  Future<void> _saveStaffToDirectory(
    StaffModel staff,
  ) async {
    final directory = getStaffDirectory();

    final existingIndex = directory.indexWhere(
      (item) => item.id == staff.id,
    );

    if (existingIndex >= 0) {
      directory[existingIndex] = staff;
    } else {
      directory.add(staff);
    }

    await _preferences.setStringList(
      _staffDirectoryKey,
      directory
          .map(
            (item) => jsonEncode(item.toJson()),
          )
          .toList(),
    );
  }

  String _generateStaffName(String staffId) {
    final number = staffId.substring(
      'STAFF-'.length,
    );

    return 'Staff $number';
  }

  Future<void> logout() async {
    await _preferences.remove(_sessionKey);
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}