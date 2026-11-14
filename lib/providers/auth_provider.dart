import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  Student? _currentStudent;
  bool _isLoading = false;
  String? _errorMessage;

  Student? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentStudent != null;

  AuthProvider() {
    _loadFromLocal();
  }

  void _loadFromLocal() {
    _currentStudent = StorageService.getStudent();
    notifyListeners();
  }

  Future<bool> loginStudent({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final student = await ApiService.verifyStudent(
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      _currentStudent = student;
      await StorageService.saveStudent(student);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    String? prodi,
    String? fakultas,
    int? semester,
    int? totalSks,
    double? ipk,
  }) async {
    if (_currentStudent == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final payload = <String, dynamic>{};
      if (prodi != null) payload['prodi'] = prodi;
      if (fakultas != null) payload['fakultas'] = fakultas;
      if (semester != null) payload['semester'] = semester;
      if (totalSks != null) payload['total_sks'] = totalSks;
      if (ipk != null) payload['ipk'] = ipk;

      final updated = await ApiService.updateProfile(_currentStudent!.nim, payload);
      _currentStudent = updated;
      await StorageService.saveStudent(updated);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentStudent = null;
    await StorageService.clearStudent();
    notifyListeners();
  }
}
