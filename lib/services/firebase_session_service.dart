import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/app_config.dart';
import '../firebase_options.dart';

class SessionIdentity {
  final String uid;
  final String email;
  const SessionIdentity(this.uid, this.email);
}

abstract class SessionService {
  Future<SessionIdentity?> restore();
  Future<SessionIdentity> signIn();
  Future<String?> getIdToken();
  Future<void> signOut();
  Stream<bool> get signedInChanges;
}

class FirebaseSessionService implements SessionService {
  static String? setupError;
  bool _googleInitialized = false;

  static Future<void> configure() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      setupError = null;
    } catch (_) {
      setupError =
          'Firebase belum siap. Ikuti PANDUAN_FIREBASE_DAN_LOKAL.md '
          'untuk menjalankan flutterfire configure dan menyiapkan Google Sign-In.';
    }
  }

  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw StateError(setupError ?? 'Firebase belum dikonfigurasi.');
    }
    return FirebaseAuth.instance;
  }

  SessionIdentity _validate(User user) {
    if (!AppConfig.isStudentEmail(user.email) ||
        !user.emailVerified ||
        !user.providerData.any((p) => p.providerId == 'google.com')) {
      throw StateError(
        'Gunakan akun Google student terverifikasi dengan format '
        'NIM@${AppConfig.studentDomain}.',
      );
    }
    return SessionIdentity(user.uid, user.email!);
  }

  @override
  Stream<bool> get signedInChanges => Firebase.apps.isEmpty
      ? const Stream.empty()
      : _auth.authStateChanges().map((user) => user != null);

  @override
  Future<SessionIdentity?> restore() async {
    final user = await _auth.authStateChanges().first;
    if (user == null) return null;
    return _validate(user);
  }

  @override
  Future<SessionIdentity> signIn() async {
    UserCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({
          'hd': AppConfig.studentDomain,
          'prompt': 'select_account',
        });
      credential = await _auth.signInWithPopup(provider);
    } else {
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
        throw StateError(
          'Google Sign-In tersedia di Android/iOS/macOS atau web. '
          'Gunakan Android emulator atau Chrome untuk pengembangan.',
        );
      }
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: AppConfig.googleServerClientId,
        );
        _googleInitialized = true;
      }
      final google = await GoogleSignIn.instance.authenticate();
      if (!AppConfig.isStudentEmail(google.email)) {
        await GoogleSignIn.instance.signOut();
        throw StateError(
          'Hanya akun @${AppConfig.studentDomain} dengan NIM numerik yang diizinkan.',
        );
      }
      final token = google.authentication.idToken;
      if (token == null) {
        throw StateError(
          'Google tidak mengembalikan ID token. Periksa SHA dan OAuth client Firebase.',
        );
      }
      credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
    }
    final user = credential.user;
    if (user == null) {
      throw StateError('Login Google tidak menghasilkan pengguna.');
    }
    try {
      return _validate(user);
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  @override
  Future<String?> getIdToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) await _auth.signOut();
    if (!kIsWeb && _googleInitialized) await GoogleSignIn.instance.signOut();
  }
}
