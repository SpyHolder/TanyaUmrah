import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _editAcademicData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final student = auth.currentStudent;
    if (student == null) return;

    final semesterCtrl = TextEditingController(
      text: student.semester.toString(),
    );
    final sksCtrl = TextEditingController(text: student.totalSks.toString());
    final ipkCtrl = TextEditingController(text: student.ipk.toString());

    final formKey = GlobalKey<FormState>();
    final route = DialogRoute<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Data Akademik',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Perubahan data ini digunakan AI untuk mengecek kelayakan KRS, magang, atau skripsi secara akurat.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  validator: (value) {
                    final n = int.tryParse(value ?? '');
                    return n == null || n < 1 || n > 30
                        ? 'Semester harus 1–30.'
                        : null;
                  },
                  controller: semesterCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Semester Aktif',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  validator: (value) {
                    final n = int.tryParse(value ?? '');
                    return n == null || n < 0 || n > 300
                        ? 'SKS harus 0–300.'
                        : null;
                  },
                  controller: sksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total SKS Lulus',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  validator: (value) {
                    final n = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    return n == null || !n.isFinite || n < 0 || n > 4
                        ? 'IPK harus 0–4.'
                        : null;
                  },
                  controller: ipkCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'IPK Kumulatif',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (auth.isLoading || !formKey.currentState!.validate()) return;
              final messenger = ScaffoldMessenger.of(context);
              final success = await auth.updateProfile(
                semester: int.parse(semesterCtrl.text),
                totalSks: int.parse(sksCtrl.text),
                ipk: double.parse(ipkCtrl.text.replaceAll(',', '.')),
              );
              if (!ctx.mounted) return;
              if (success) Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Data akademik berhasil diperbarui!'
                        : auth.errorMessage ??
                              'Gagal memperbarui data akademik.',
                  ),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    await Navigator.of(context).push(route);
    // Wait for the closing animation to remove fields before disposing controllers.
    await route.completed;
    semesterCtrl.dispose();
    sksCtrl.dispose();
    ipkCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = auth.currentStudent;

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Profil Mahasiswa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Student Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        student?.nama.isNotEmpty == true
                            ? student!.nama[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    student?.nama ?? 'Mahasiswa UMRAH',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    student?.email ?? '-',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn('NIM', student?.nim ?? '-'),
                      _buildInfoColumn('Program Studi', student?.prodi ?? '-'),
                      _buildInfoColumn(
                        'Semester',
                        'Sem. ${student?.semester ?? 1}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        'Total SKS',
                        '${student?.totalSks ?? 0} SKS',
                      ),
                      _buildInfoColumn(
                        'IPK',
                        student?.ipk.toStringAsFixed(2) ?? '0.00',
                      ),
                      _buildInfoColumn(
                        'Status',
                        (student?.status ?? 'aktif').toUpperCase(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings list
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.edit_note_rounded,
                      color: AppConstants.primaryBlue,
                    ),
                    title: const Text(
                      'Perbarui Data Akademik (SKS/IPK)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Atur SKS & IPK terbaru untuk evaluasi AI',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: auth.isLoading ? null : _editAcademicData,
                  ),
                  const Divider(height: 1, indent: 56),

                  ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: AppConstants.primaryBlue,
                    ),
                    title: const Text(
                      'Tentang tanyaUMRAH',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Aplikasi Asisten Layanan Akademik v1.0.0',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'tanyaUMRAH',
                        applicationVersion: '1.0.0 (PPB 2026)',
                        applicationLegalese:
                            'Universitas Maritim Raja Ali Haji (UMRAH)\nTanjungpinang',
                        children: const [
                          SizedBox(height: 10),
                          Text(
                            'Dikembangkan oleh Kelompok Mahasiswa Teknik Informatika UMRAH dengan integrasi RAG & Google Gemini.',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: auth.isLoading ? null : () => auth.logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
