import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_config.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_session_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final setupError = FirebaseSessionService.setupError;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryBlue,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Center(
                      child: Text(
                        'tU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selamat Datang di tanyaUMRAH',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Asisten informasi akademik\nUniversitas Maritim Raja Ali Haji',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.school_outlined,
                    size: 36,
                    color: AppConstants.primaryBlue,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Masuk dengan akun Google mahasiswa',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gunakan NIM@${AppConfig.studentDomain}. '
                    'Akun Gmail pribadi dan akun staf tidak dapat mengakses layanan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (setupError != null || auth.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        setupError ?? auth.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.brown.shade800),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: auth.isLoading || setupError != null
                          ? null
                          : () => auth.loginWithGoogle(),
                      icon: auth.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        auth.isLoading
                            ? 'Memverifikasi akun...'
                            : 'Masuk dengan Google',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Data akademik dan pertanyaan dapat diproses oleh layanan AI. '
                    'Jangan kirim kata sandi atau data rahasia melalui chat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      height: 1.5,
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
