class Student {
  final String nim;
  final String nama;
  final String email;
  final String? photoUrl;
  final String fakultas;
  final String prodi;
  final int semester;
  final int totalSks;
  final double ipk;
  final List<String> mkLulus;
  final String status;

  Student({
    required this.nim,
    required this.nama,
    required this.email,
    this.photoUrl,
    required this.fakultas,
    required this.prodi,
    required this.semester,
    required this.totalSks,
    required this.ipk,
    required this.mkLulus,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      nim: json['nim'] ?? '',
      nama: json['nama'] ?? 'Mahasiswa UMRAH',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'],
      fakultas: json['fakultas'] ?? 'Teknik dan Ilmu Kelautan',
      prodi: json['prodi'] ?? 'Teknik Informatika',
      semester: json['semester'] is int ? json['semester'] : int.tryParse(json['semester'].toString()) ?? 1,
      totalSks: json['total_sks'] is int ? json['total_sks'] : int.tryParse(json['total_sks'].toString()) ?? 0,
      ipk: json['ipk'] is num ? (json['ipk'] as num).toDouble() : double.tryParse(json['ipk'].toString()) ?? 0.0,
      mkLulus: json['mk_lulus'] != null ? List<String>.from(json['mk_lulus']) : [],
      status: json['status'] ?? 'aktif',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'nama': nama,
      'email': email,
      'photo_url': photoUrl,
      'fakultas': fakultas,
      'prodi': prodi,
      'semester': semester,
      'total_sks': totalSks,
      'ipk': ipk,
      'mk_lulus': mkLulus,
      'status': status,
    };
  }

  // Calculate progress toward bachelor degree (standard: 144 SKS)
  double get graduationProgress => (totalSks / 144.0).clamp(0.0, 1.0);
}
