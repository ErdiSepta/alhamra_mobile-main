import 'package:flutter/material.dart';
import '../../../core/models/user_model.dart';
import 'package:alhamra_1/core/data/student_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  uninitialized,
  authenticating,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String _errorMessage = '';
  String _selectedStudent = StudentData.defaultStudent;
  String _selectedLanguage = 'Indonesia';
  static const String _userKey = 'user_token';
  static const String _selectedStudentKey = 'selected_student_name';

  AuthProvider() {
    _checkCurrentUser();
  }

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserModel? get user => _user;
  String get errorMessage => _errorMessage;
  String get selectedStudent => _selectedStudent;
  String get selectedLanguage => _selectedLanguage;

  void _checkCurrentUser() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    // Initialize current user from SharedPreferences
    await _authService.initializeCurrentUser();

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userKey);
    final savedStudent = prefs.getString(_selectedStudentKey);
    if (savedStudent != null && savedStudent.isNotEmpty) {
      _selectedStudent = savedStudent;
    }

    if (userId != null) {
      final currentUser = _authService.getCurrentUser();
      if (currentUser != null && currentUser.uid == userId) {
        _user = await _authService.getUserData(currentUser.uid);
        if (_user != null) {
          _status = AuthStatus.authenticated;
        } else {
          // User data not found, clear session
          await logout();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        // Mismatch or no current user, clear session
        await logout();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      notifyListeners();

      final credential = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (credential != null && credential.user != null) {
        _user = await _authService.getUserData(credential.user!.uid);
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, credential.user!.uid);
          _status = AuthStatus.authenticated;
          _errorMessage = '';
          notifyListeners();
          return true;
        }
      }
      _errorMessage = "Gagal mendapatkan data pengguna.";
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    _status = AuthStatus.unauthenticated;
    _user = null;
    notifyListeners();
  }

  void selectStudent(String studentName) {
    if (_selectedStudent == studentName) return;
    _selectedStudent = studentName;
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_selectedStudentKey, studentName);
      } catch (_) {}
    }();
    notifyListeners();
  }

  void selectLanguage(String language) {
    if (_selectedLanguage != language) {
      _selectedLanguage = language;
      notifyListeners();
    }
  }
}
