import 'dart:async';
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/api_service.dart';
import '../services/firebase_session_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final SessionService _session;
  final Future<Student> Function(String) _verify;
  StreamSubscription<bool>? _subscription;
  Student? _currentStudent;
  String? _accountId;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _epoch = 0;
  bool _disposed = false;

  AuthProvider({
    SessionService? session,
    Future<Student> Function(String)? verify,
  }) : _session = session ?? FirebaseSessionService(),
       _verify =
           verify ?? ((token) => ApiService.verifyStudent(idToken: token));

  Student? get currentStudent => _currentStudent;
  String? get accountId => _accountId;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentStudent != null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    ApiService.tokenProvider = _session.getIdToken;
    ApiService.onUnauthorized = logout;
    try {
      final identity = await _session.restore();
      if (identity != null) await _accept(identity, _epoch);
    } catch (e) {
      _errorMessage = _message(e);
      await _session.signOut();
    } finally {
      _isInitializing = false;
      _subscription = _session.signedInChanges.listen((signedIn) {
        if (!signedIn && isLoggedIn) unawaited(logout());
      });
      _notify();
    }
  }

  Future<void> _accept(SessionIdentity identity, int epoch) async {
    final token = await _session.getIdToken();
    if (token == null) {
      throw StateError('Sesi Google tidak tersedia. Silakan masuk lagi.');
    }
    final student = await _verify(token);
    if (epoch != _epoch || _disposed) return;
    // A local profile alone is never accepted as proof of a signed-in session.
    StorageService.useAccount(identity.uid);
    await StorageService.saveStudent(student);
    if (epoch != _epoch || _disposed) return;
    _accountId = identity.uid;
    _currentStudent = student;
  }

  Future<bool> loginWithGoogle() async {
    if (_isLoading) return false;
    final epoch = ++_epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final identity = await _session.signIn();
      await _accept(identity, epoch);
      return epoch == _epoch && isLoggedIn;
    } catch (e) {
      if (epoch == _epoch) {
        _errorMessage = _message(e);
        await _session.signOut();
        StorageService.useAccount(null);
      }
      return false;
    } finally {
      if (epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<bool> updateProfile({
    String? prodi,
    String? fakultas,
    int? semester,
    int? totalSks,
    double? ipk,
  }) async {
    final student = _currentStudent;
    if (student == null || _isLoading) return false;
    final epoch = _epoch;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final updated = await ApiService.updateProfile(student.nim, {
        'prodi': ?prodi,
        'fakultas': ?fakultas,
        'semester': ?semester,
        'total_sks': ?totalSks,
        'ipk': ?ipk,
      });
      if (epoch != _epoch || _disposed) return false;
      _currentStudent = updated;
      await StorageService.saveStudent(updated);
      return true;
    } catch (e) {
      if (epoch == _epoch) _errorMessage = _message(e);
      return false;
    } finally {
      if (epoch == _epoch) {
        _isLoading = false;
        _notify();
      }
    }
  }

  Future<void> logout() async {
    ++_epoch;
    _currentStudent = null;
    _accountId = null;
    _isLoading = false;
    StorageService.useAccount(null);
    _notify();
    try {
      await _session.signOut();
    } catch (_) {
      _errorMessage =
          'Sesi lokal sudah ditutup. Periksa koneksi sebelum login kembali.';
      _notify();
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst(RegExp(r'^(Exception|Bad state):\s*'), '');

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
