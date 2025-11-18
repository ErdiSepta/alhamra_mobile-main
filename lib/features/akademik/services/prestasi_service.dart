import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/config/app_config.dart';
import '../../../core/services/odoo_api_service.dart';
import '../models/prestasi_model.dart';

class PrestasiService {
  PrestasiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Prestasi>> getPrestasiBySiswaId(
    String siswaId, {
    int page = 1,
    int limit = 20,
  }) async {
    var sessionId = await _getSessionId();
    sessionId ??= await _syncSessionFromOdoo();
    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('Sesi tidak ditemukan. Silakan masuk kembali.');
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/v1/siswa/$siswaId/prestasi?page=$page&limit=$limit',
    );

    final logPrefix = '[PrestasiService]';
    dev.log(
      '$logPrefix Requesting prestasi | siswaId=$siswaId page=$page limit=$limit url=$uri',
      name: 'PrestasiService',
    );
    // Additional print for non-dev.log consoles
    // ignore: avoid_print
    print('$logPrefix Requesting prestasi | siswaId=$siswaId page=$page limit=$limit');

    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $sessionId',
        'Cookie': 'session_id=$sessionId',
      },
    );

    if (response.statusCode != 200) {
      final errorLog =
          '$logPrefix Response error ${response.statusCode} body=${response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body}';
      dev.log(
        errorLog,
        name: 'PrestasiService',
        level: 1000,
      );
      // ignore: avoid_print
      print(errorLog);
      final snippet = response.body.length > 160
          ? '${response.body.substring(0, 160)}...'
          : response.body;
      throw Exception(
        'Gagal memuat data prestasi (${response.statusCode}): $snippet',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.toLowerCase().contains('application/json')) {
      final preview = response.body.trimLeft();
      if (preview.startsWith('<!DOCTYPE') || preview.startsWith('<html')) {
        throw const FormatException(
          'Server mengembalikan HTML. Sesi mungkin kedaluwarsa.',
        );
      }
    }

    final successPreview = response.body.length > 800
        ? '${response.body.substring(0, 800)}...'
        : response.body;
    dev.log(
      '$logPrefix Raw response preview: $successPreview',
      name: 'PrestasiService',
    );
    // ignore: avoid_print
    print('$logPrefix Raw response preview: $successPreview');

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Format data prestasi tidak valid.');
    }

    final List<dynamic> rawList = _extractDataList(decoded);
    final prestasiList = rawList.map((raw) => _mapPrestasi(raw)).toList();

    final parsedLog = '$logPrefix Parsed count=${prestasiList.length}';
    dev.log(parsedLog, name: 'PrestasiService');
    // ignore: avoid_print
    print(parsedLog);

    return prestasiList;
  }

  List<dynamic> _extractDataList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['items'] ?? decoded['result'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final records = data['records'] ?? data['rows'];
        if (records is List) return records;
      }
    }
    return const [];
  }

  Prestasi _mapPrestasi(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return Prestasi(
        id: raw.toString(),
        judul: 'Prestasi Santri',
        deskripsi: '',
        tingkat: TingkatPrestasi.sekolah,
        jenis: JenisPrestasi.lainnya,
        juara: '',
        tanggalPencapaian: DateTime.now(),
      );
    }

    final tingkat = _mapTingkat(raw['tingkat'] ?? raw['level']);
    final jenis = _mapJenis(raw['jenis'] ?? raw['kategori'] ?? raw['type']);
    final juara =
        (raw['juara'] ?? raw['peringkat'] ?? raw['hasil'] ?? '').toString();
    final judul =
        (raw['judul'] ?? raw['name'] ?? raw['prestasi'] ?? 'Prestasi Santri')
            .toString();
    final deskripsi =
        (raw['deskripsi'] ?? raw['keterangan'] ?? raw['catatan'] ?? '')
            .toString();
    final penyelenggara =
        (raw['penyelenggara'] ?? raw['organizer'] ?? raw['instansi'])?.toString();
    final bukti = (raw['buktifile'] ?? raw['bukti'] ?? raw['attachment'])
        ?.toString();
    final catatan = raw['catatan']?.toString();

    final tanggal = _parseDate(
      raw['tanggal_pencapaian'] ??
          raw['tanggal'] ??
          raw['tgl'] ??
          raw['date'] ??
          raw['achievement_date'],
    );

    return Prestasi(
      id: (raw['id'] ?? raw['prestasi_id'] ?? '').toString(),
      judul: judul,
      deskripsi: deskripsi,
      tingkat: tingkat,
      jenis: jenis,
      juara: juara,
      tanggalPencapaian: tanggal,
      penyelenggara: penyelenggara,
      buktiUrl: bukti,
      catatan: catatan,
      rawData: raw,
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final str = value.toString();
    try {
      return DateTime.parse(str);
    } catch (_) {
      // Coba format alternatif tanpa waktu
      try {
        final parts = str.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]) ?? 1;
          final month = int.tryParse(parts[1]) ?? 1;
          final year = int.tryParse(parts[2]) ?? DateTime.now().year;
          return DateTime(year, month, day);
        }
      } catch (_) {}
      return DateTime.now();
    }
  }

  TingkatPrestasi _mapTingkat(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? '';
    switch (raw) {
      case 'sekolah':
      case 'kelas':
        return TingkatPrestasi.sekolah;
      case 'kecamatan':
      case 'district':
        return TingkatPrestasi.kecamatan;
      case 'kabupaten':
      case 'city':
        return TingkatPrestasi.kabupaten;
      case 'provinsi':
      case 'province':
        return TingkatPrestasi.provinsi;
      case 'nasional':
        return TingkatPrestasi.nasional;
      case 'internasional':
      case 'international':
        return TingkatPrestasi.internasional;
      default:
        return TingkatPrestasi.sekolah;
    }
  }

  JenisPrestasi _mapJenis(dynamic value) {
    final raw = value?.toString().toLowerCase() ?? '';
    switch (raw) {
      case 'akademik':
      case 'academic':
        return JenisPrestasi.akademik;
      case 'non_akademik':
      case 'non-akademik':
      case 'non akademik':
      case 'non academic':
        return JenisPrestasi.non_akademik;
      case 'seni':
      case 'art':
        return JenisPrestasi.seni;
      case 'olahraga':
      case 'sport':
        return JenisPrestasi.olahraga;
      default:
        return JenisPrestasi.lainnya;
    }
  }

  Future<String?> _getSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('session_id') ??
          prefs.getString('odoo_session_id') ??
          prefs.getString('token');
    } catch (_) {
      return null;
    }
  }

  Future<String?> _syncSessionFromOdoo() async {
    try {
      final odoo = OdooApiService();
      await odoo.loadSession();
      return odoo.sessionId;
    } catch (_) {
      return null;
    }
  }
}

// Instance global untuk memudahkan penggunaan
final prestasiService = PrestasiService();
