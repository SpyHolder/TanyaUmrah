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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.softBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppConstants.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Edit Data Akademik',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppConstants.borderLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppConstants.primaryBlue,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data ini digunakan AI untuk menganalisis kelayakan KRS, magang, cuti, atau skripsi secara tepat.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppConstants.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: semesterCtrl,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final n = int.tryParse(value ?? '');
                    return n == null || n < 1 || n > 30
                        ? 'Semester harus antara 1 sampai 30.'
                        : null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Semester Aktif',
                    prefixIcon: Icon(Icons.timeline_rounded, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: sksCtrl,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final n = int.tryParse(value ?? '');
                    return n == null || n < 0 || n > 300
                        ? 'SKS harus antara 0 sampai 300.'
                        : null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Total SKS Lulus',
                    prefixIcon: Icon(Icons.school_rounded, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: ipkCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final n = double.tryParse((value ?? '').replaceAll(',', '.'));
                    return n == null || !n.isFinite || n < 0 || n > 4
                        ? 'IPK harus antara 0.00 sampai 4.00.'
                        : null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'IPK Kumulatif (contoh: 3.75)',
                    prefixIcon: Icon(Icons.grade_rounded, size: 20),
                    isDense: true,
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
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Simpan'),
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
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  content: Text(
                    success
                        ? 'Data akademik berhasil diperbarui!'
                        : auth.errorMessage ?? 'Gagal memperbarui data akademik.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    semesterCtrl.dispose();
    sksCtrl.dispose();
    ipkCtrl.dispose();
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text(
              'Konfirmasi Keluar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun mahasiswa UMRAH Anda?',
          style: TextStyle(fontSize: 13, color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final student = auth.currentStudent;

    return Scaffold(
      backgroundColor: AppConstants.surfaceLight,
      appBar: AppBar(
        title: const Text(
          'Profil Akademik',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Digital Student ID Card (KTM Digital)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Card Header Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryNavy,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: AppConstants.accentGold,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'UNIVERSITAS MARITIM RAJA ALI HAJI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.accentGold.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'KTM DIGITAL',
                            style: TextStyle(
                              color: AppConstants.accentGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar & Name
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppConstants.primaryNavy, AppConstants.primaryBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.primaryBlue.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          student?.email ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConstants.stateSuccess.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.stateSuccess.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: AppConstants.stateSuccess,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (student?.status ?? 'Aktif').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.stateSuccess,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppConstants.borderLight),
                        const SizedBox(height: 14),

                        // Academic Info Grid
                        Row(
                          children: [
                            _buildInfoColumn('NIM', student?.nim ?? '-'),
                            Container(height: 28, width: 1, color: AppConstants.borderLight),
                            _buildInfoColumn('Program Studi', student?.prodi ?? '-'),
                            Container(height: 28, width: 1, color: AppConstants.borderLight),
                            _buildInfoColumn(
                              'Semester',
                              'Sem. ${student?.semester ?? 1}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppConstants.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppConstants.borderLight),
                          ),
                          child: Row(
                            children: [
                              _buildMetricTile(
                                label: 'Total SKS Lulus',
                                value: '${student?.totalSks ?? 0} SKS',
                                icon: Icons.school_rounded,
                                color: AppConstants.primaryBlue,
                              ),
                              Container(height: 30, width: 1, color: AppConstants.borderLight),
                              _buildMetricTile(
                                label: 'IPK Kumulatif',
                                value: student?.ipk.toStringAsFixed(2) ?? '0.00',
                                icon: Icons.grade_rounded,
                                color: (student?.ipk ?? 0) >= 3.5
                                    ? AppConstants.stateSuccess
                                    : AppConstants.primaryNavy,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settings & Actions Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.softBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppConstants.primaryBlue,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Perbarui Data Akademik (SKS/IPK)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textDark,
                      ),
                    ),
                    subtitle: const Text(
                      'Perbarui SKS & IPK terbaru untuk evaluasi AI',
                      style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppConstants.textMuted,
                    ),
                    onTap: auth.isLoading ? null : _editAcademicData,
                  ),
                  const Divider(height: 1, indent: 56, color: AppConstants.borderLight),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.softGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: AppConstants.accentGold,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Tentang tanyaUMRAH',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textDark,
                      ),
                    ),
                    subtitle: const Text(
                      'Sistem Informasi & Asisten AI Akademik v1.0.0',
                      style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppConstants.textMuted,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'tanyaUMRAH',
                        applicationVersion: '1.0.0 (PPB 2026)',
                        applicationLegalese:
                            'Universitas Maritim Raja Ali Haji (UMRAH)\nTanjungpinang, Kepulauan Riau',
                        children: const [
                          SizedBox(height: 12),
                          Text(
                            'tanyaUMRAH adalah asisten kecerdasan buatan berbasis Retrieval-Augmented Generation (RAG) '
                            'dan model Gemini yang terintegrasi dengan pedoman akademik serta kalender resmi UMRAH.',
                            style: TextStyle(fontSize: 12, height: 1.4),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Dikembangkan oleh Tim Mahasiswa Teknik Informatika UMRAH untuk mempermudah akses informasi perkuliahan.',
                            style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button with Safe Confirmation Dialog
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: auth.isLoading ? null : () => _confirmLogout(context, auth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppConstants.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
