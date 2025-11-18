import 'package:intl/intl.dart';

enum TingkatPrestasi { sekolah, kecamatan, kabupaten, provinsi, nasional, internasional }
enum JenisPrestasi { akademik, non_akademik, seni, olahraga, lainnya }

class Prestasi {
  final String id;
  final String judul;
  final String deskripsi;
  final TingkatPrestasi tingkat;
  final JenisPrestasi jenis;
  final String juara; // Contoh: "Juara 1", "Harapan 2", dll
  final DateTime tanggalPencapaian;
  final String? penyelenggara;
  final String? buktiUrl; // URL ke gambar/foto bukti
  final String? catatan;
  final Map<String, dynamic> rawData;

  Prestasi({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.tingkat,
    required this.jenis,
    required this.juara,
    required this.tanggalPencapaian,
    this.penyelenggara,
    this.buktiUrl,
    this.catatan,
    Map<String, dynamic>? rawData,
  }) : rawData = rawData ?? const {};

  // Format tanggal menjadi string yang lebih mudah dibaca
  String get formattedDate {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(tanggalPencapaian);
  }

  // Getter untuk ikon berdasarkan jenis prestasi
  String get iconAsset {
    switch (jenis) {
      case JenisPrestasi.akademik:
        return 'assets/icons/trophy_academic.png';
      case JenisPrestasi.non_akademik:
        return 'assets/icons/trophy_nonacademic.png';
      case JenisPrestasi.seni:
        return 'assets/icons/art_palette.png';
      case JenisPrestasi.olahraga:
        return 'assets/icons/sports_soccer.png';
      case JenisPrestasi.lainnya:
        return 'assets/icons/trophy.png';
    }
  }

  // Konversi dari JSON ke objek
  factory Prestasi.fromJson(Map<String, dynamic> json) {
    return Prestasi(
      id: json['id'] ?? '',
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      tingkat: TingkatPrestasi.values.firstWhere(
        (e) => e.toString() == 'TingkatPrestasi.${json['tingkat']}',
        orElse: () => TingkatPrestasi.sekolah,
      ),
      jenis: JenisPrestasi.values.firstWhere(
        (e) => e.toString() == 'JenisPrestasi.${json['jenis']}',
        orElse: () => JenisPrestasi.lainnya,
      ),
      juara: json['juara'] ?? '',
      tanggalPencapaian: DateTime.parse(json['tanggalPencapaian']),
      penyelenggara: json['penyelenggara'],
      buktiUrl: json['buktifile'],
      catatan: json['catatan'],
      rawData: json,
    );
  }

  // Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'tingkat': tingkat.toString().split('.').last,
      'jenis': jenis.toString().split('.').last,
      'juara': juara,
      'tanggalPencapaian': tanggalPencapaian.toIso8601String(),
      'penyelenggara': penyelenggara,
      'buktifile': buktiUrl,
      'catatan': catatan,
      'rawData': rawData,
    };
  }
}

// Contoh data dummy untuk pengembangan
List<Prestasi> dummyPrestasi = [
  Prestasi(
    id: '1',
    judul: 'Juara 1 Olimpiade Matematika',
    deskripsi: 'Memenangkan kompetisi matematika tingkat kabupaten',
    tingkat: TingkatPrestasi.kabupaten,
    jenis: JenisPrestasi.akademik,
    juara: 'Juara 1',
    tanggalPencapaian: DateTime(2023, 5, 15),
    penyelenggara: 'Dinas Pendidikan Kabupaten',
  ),
  Prestasi(
    id: '2',
    judul: 'Juara 2 Lomba Pidato Bahasa Inggris',
    deskripsi: 'Lomba pidato bahasa Inggris antar sekolah se-kecamatan',
    tingkat: TingkatPrestasi.kecamatan,
    jenis: JenisPrestasi.akademik,
    juara: 'Juara 2',
    tanggalPencapaian: DateTime(2023, 8, 20),
    penyelenggara: 'MGMP Bahasa Inggris Kecamatan',
  ),
  Prestasi(
    id: '3',
    judul: 'Juara 1 Futsal Antar Kelas',
    deskripsi: 'Turnamen futsal tahunan antar kelas',
    tingkat: TingkatPrestasi.sekolah,
    jenis: JenisPrestasi.olahraga,
    juara: 'Juara 1',
    tanggalPencapaian: DateTime(2023, 10, 5),
    penyelenggara: 'OSIS Al-Hamra',
  ),
];
