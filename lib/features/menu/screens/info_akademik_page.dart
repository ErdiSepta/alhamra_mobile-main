import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../core/data/class_data.dart';
import '../../../core/data/student_data.dart';
import '../../../core/models/academic_info_model.dart';
import '../../../core/services/odoo_api_service.dart';
import '../../../core/utils/app_styles.dart';
import '../../shared/widgets/index.dart';
import '../../shared/widgets/student_selection_widget.dart';
import '../../akademik/models/prestasi_model.dart';
import '../../akademik/services/prestasi_service.dart';

class InfoAkademikPage extends StatefulWidget {
  const InfoAkademikPage({super.key});

  @override
  State<InfoAkademikPage> createState() => _InfoAkademikPageState();
}

class _InfoAkademikPageState extends State<InfoAkademikPage> with TickerProviderStateMixin {
  // Mock Schedule Data (tetap)
  final List<JadwalHarian> _jadwalPelajaran = [
    JadwalHarian(hari: 'Senin', pelajaran: [
      MataPelajaran(jam: '07:00 - 08:30', nama: 'Matematika'),
      MataPelajaran(jam: '08:30 - 10:00', nama: 'Bahasa Indonesia'),
      MataPelajaran(jam: '10:30 - 12:00', nama: 'Fisika'),
    ]),
    JadwalHarian(hari: 'Selasa', pelajaran: [
      MataPelajaran(jam: '07:00 - 08:30', nama: 'Kimia'),
      MataPelajaran(jam: '08:30 - 10:00', nama: 'Bahasa Inggris'),
    ]),
    JadwalHarian(hari: 'Rabu', pelajaran: [
      MataPelajaran(jam: '07:00 - 08:30', nama: 'Biologi'),
      MataPelajaran(jam: '08:30 - 10:00', nama: 'Sejarah'),
      MataPelajaran(jam: '10:30 - 12:00', nama: 'Penjaskes'),
    ]),
    JadwalHarian(hari: 'Kamis', pelajaran: [
      MataPelajaran(jam: '07:00 - 08:30', nama: 'Matematika'),
      MataPelajaran(jam: '08:30 - 10:00', nama: 'Bahasa Arab'),
    ]),
    JadwalHarian(hari: 'Jumat', pelajaran: [
      MataPelajaran(jam: '07:00 - 08:30', nama: 'Fiqih'),
      MataPelajaran(jam: '08:30 - 10:00', nama: 'Aqidah Akhlak'),
    ]),
  ];

  // State dari API
  final OdooApiService _odoo = OdooApiService();
  Map<String, String> _nameToId = {};
  List<String> _childrenNames = [];
  String _selectedStudentName = StudentData.defaultStudent;
  String? _selectedSiswaId;
  bool _isStudentOverlayVisible = false;
  bool _isLoading = true;
  String? _error;

  // State untuk prestasi
  List<Prestasi> _prestasiList = [];
  bool _isLoadingPrestasi = false;
  final PrestasiService _prestasiService = PrestasiService();
  Set<String> _expandedPrestasiIds = {}; // Track expanded prestasi items

  // Tab Controller
  late TabController _tabController;

  // Profil akademik yang ditampilkan
  String _namaLengkap = '-';
  String _namaPanggilan = '-';
  String _tempatLahir = '-';
  String _tanggalLahir = '-';
  String _jenisKelamin = '-';
  String _kelas = '-';
  String _semester = '-';
  String _jumlahSiswa = '-';
  String _avatarUrl = '';
  // Data sekolah tambahan
  String _nis = '';
  String _nisn = '';
  String _tahunAjaran = '';
  String _kelasRuang = '';
  String _jenjang = '';
  String _tingkat = '';
  String _musyrif = '';
  String _kamar = '';
  String _halaqoh = '';
  String _penanggungJawab = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Ambil siswa_id yang terakhir dipilih
      final prefs = await SharedPreferences.getInstance();
      final savedSiswaId = prefs.getString('siswa_id');

      // Ambil daftar anak dari server untuk peta nama→id
      final children = await _odoo.getChildren();
      _nameToId.clear();
      final names = <String>[];
      for (final c in children) {
        final name = (c['name'] ?? c['nama'] ?? '').toString();
        final id = (c['siswa_id'] ?? c['student_id'] ?? c['id'])?.toString() ?? '';
        if (name.isNotEmpty && id.isNotEmpty) {
          names.add(name);
          _nameToId[name] = id;
        }
      }

      // Tentukan yang dipilih berdasar siswa_id atau pakai pertama
      String? selectedName;
      if (savedSiswaId != null && savedSiswaId.isNotEmpty) {
        selectedName = _nameToId.entries.firstWhere(
          (e) => e.value == savedSiswaId,
          orElse: () => const MapEntry('', ''),
        ).key;
      }
      if (selectedName == null || selectedName.isEmpty) {
        selectedName = names.isNotEmpty ? names.first : _selectedStudentName;
      }

      setState(() {
        _childrenNames = names.isEmpty ? [StudentData.defaultStudent] : names;
        _selectedStudentName = selectedName!;
        _selectedSiswaId = _nameToId[_selectedStudentName];
      });

      // Fetch profil akademik
      await _loadProfile();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      final idStr = _selectedSiswaId;
      if (idStr == null || idStr.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Siswa belum dipilih.';
        });
        return;
      }
      final id = int.tryParse(idStr) ?? -1;
      if (id < 0) {
        setState(() {
          _isLoading = false;
          _error = 'ID siswa tidak valid.';
        });
        return;
      }

      final data = await _odoo.getStudentProfile(id);

      String g = (data['gender'] ?? data['jenis_kelamin'] ?? data['jns_kelamin'] ?? '-').toString();
      if (g.isNotEmpty && g != '-') {
        final low = g.toLowerCase();
        if (low == 'l' || low.startsWith('m')) g = 'Laki-Laki';
        if (low == 'p' || low.startsWith('f') || low.contains('perem')) g = 'Perempuan';
      }

      String pick(dynamic v) => (v == null || v == false) ? '' : v.toString();
      String pickPair(dynamic v) {
        if (v is List && v.length > 1) {
          final s = v[1];
          return s?.toString() ?? '';
        }
        return v is String ? v : '';
      }

      setState(() {
        _namaLengkap = (data['name'] ?? data['nama'] ?? _selectedStudentName).toString();
        _namaPanggilan = (data['nickname'] ?? data['nama_panggilan'] ?? data['nama_pgl'] ?? _selectedStudentName.split(' ').first).toString();
        _tempatLahir = (data['birth_place'] ?? data['tempat_lahir'] ?? data['tmp_lahir'] ?? '-').toString();
        _tanggalLahir = (data['birth_date'] ?? data['tanggal_lahir'] ?? data['tgl_lahir'] ?? '-').toString();
        _jenisKelamin = g.isEmpty ? '-' : g;
        // Kelas: coba string langsung, lalu pair id-name
        String kelasStr = (data['class_name'] ?? data['kelas_name'] ?? data['kelas'] ?? data['rombel_name'] ?? data['rombel'] ?? '').toString();
        if (kelasStr.isEmpty) kelasStr = pickPair(data['rombel_id']);
        if (kelasStr.isEmpty) kelasStr = pickPair(data['kelas_id']);
        if (kelasStr.isEmpty) kelasStr = pickPair(data['ruang_kelas_id']);
        _kelas = kelasStr.isEmpty ? '-' : kelasStr;
        // Semester: string atau pair
        String semStr = (data['semester'] ?? data['semester_name'] ?? data['semester_ke'] ?? '').toString();
        if (semStr.isEmpty) semStr = pickPair(data['semester_id']);
        _semester = semStr;
        // Jumlah siswa: banyak variasi nama
        String jml = (data['students_count'] ?? data['jumlah_siswa'] ?? data['jumlah_santri'] ?? data['rombel_student_count'] ?? data['rombel_siswa_count'] ?? data['class_size'] ?? data['student_count'] ?? '').toString();
        _jumlahSiswa = jml;
        _avatarUrl = (data['avatar'] ?? data['avatar_url'] ?? '').toString();
        // Data sekolah tambahan
        _nis = (data['nis'] ?? data['NIS'] ?? '').toString();
        _nisn = (data['nisn'] ?? '').toString();
        _tahunAjaran = pickPair(data['tahunajaran_id']);
        _kelasRuang = pickPair(data['ruang_kelas_id']);
        _jenjang = pick(data['jenjang'] ?? data['jenjang_name']);
        _tingkat = pickPair(data['tingkat']);
        _musyrif = pickPair(data['musyrif_id']);
        _kamar = pickPair(data['kamar_id']);
        _halaqoh = pickPair(data['halaqoh_id']);
        _penanggungJawab = pickPair(data['penanggung_jawab_id']);
        _isLoading = false;
      });
      
      // Load prestasi setelah profile berhasil dimuat
      await _loadPrestasi();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // Method untuk load prestasi
  Future<void> _loadPrestasi() async {
    if (_selectedSiswaId == null || _selectedSiswaId!.isEmpty) return;
    
    setState(() {
      _isLoadingPrestasi = true;
    });
    
    try {
      final prestasi = await _prestasiService.getPrestasiBySiswaId(_selectedSiswaId!);
      setState(() {
        _prestasiList = prestasi;
        _isLoadingPrestasi = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPrestasi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      appBar: CustomAppBar(
        title: 'Info Akademik',
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStudentSelector(),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppStyles.primaryColor))
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(_error!, textAlign: TextAlign.center),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _initLoad,
                                      child: const Text('Coba Lagi'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _buildAcademicDetails(),
                ),
              ),
            ],
          ),
          if (_isStudentOverlayVisible)
            SearchOverlayWidget(
              isVisible: _isStudentOverlayVisible,
              title: 'Pilih Santri',
              items: _childrenNames.isEmpty ? [StudentData.defaultStudent] : _childrenNames,
              selectedItem: _selectedStudentName,
              onItemSelected: (nama) async {
                final id = _nameToId[nama];
                if (id != null && id.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('siswa_id', id);
                }
                setState(() {
                  _selectedStudentName = nama;
                  _selectedSiswaId = id;
                  _isStudentOverlayVisible = false;
                  _isLoading = true;
                  _error = null;
                  _prestasiList = []; // Reset prestasi saat ganti siswa
                  _expandedPrestasiIds.clear(); // Reset expanded items
                });
                await _loadProfile();
              },
              onClose: () => setState(() => _isStudentOverlayVisible = false),
              searchHint: 'Cari santri...',
              avatarUrl: StudentData.getStudentAvatar(_selectedStudentName),
            ),
        ],
      ),
    );
  }

  

  Widget _buildStudentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: StudentSelectionWidget(
        selectedStudent: _selectedStudentName,
        students: _childrenNames.isEmpty ? [StudentData.defaultStudent] : _childrenNames,
        onStudentChanged: (nama) async {
          final id = _nameToId[nama];
          if (id != null && id.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('siswa_id', id);
          }
          setState(() {
            _selectedStudentName = nama;
            _selectedSiswaId = id;
            _isLoading = true;
            _error = null;
            _prestasiList = []; // Reset prestasi saat ganti siswa
            _expandedPrestasiIds.clear(); // Reset expanded items
          });
          await _loadProfile();
        },
        onOverlayVisibilityChanged: (visible) => setState(() => _isStudentOverlayVisible = visible),
        avatarUrl: _avatarUrl.isNotEmpty ? _avatarUrl : StudentData.getStudentAvatar(_selectedStudentName),
      ),
    );
  }

  Widget _buildAcademicDetails() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Tab Bar (sama seperti StatusPage)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppStyles.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blueAccent,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Informasi'),
                Tab(text: 'Prestasi'),
              ],
            ),
          ),
          // Tab Bar View dengan background F5F7FA (sama seperti StatusPage)
          Expanded(
            child: Container(
              color: const Color(0xFFF5F7FA),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab Informasi
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataDiriCard(),
                        const SizedBox(height: 24),
                        _buildKelasCard(),
                      ],
                    ),
                  ),
                  // Tab Prestasi
                  _buildPrestasiTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDiriCard() {
    return CustomCardWidget(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Diri Santri', style: AppStyles.sectionTitle(context)),
          const SizedBox(height: 16),
          _buildDetailRow('Nama Lengkap', _namaLengkap),
          const Divider(height: 24),
          _buildDetailRow('Nama Panggilan', _namaPanggilan),
          const Divider(height: 24),
          _buildDetailRow('Tempat Lahir', _tempatLahir),
          const Divider(height: 24),
          _buildDetailRow('Tanggal Lahir', _tanggalLahir),
          const Divider(height: 24),
          _buildDetailRow('Jenis Kelamin', _jenisKelamin),
          // Data sekolah digabungkan ke Data Diri
          const Divider(height: 24),
          _buildDetailRow('NIS', _nis.isEmpty ? '-' : _nis),
          const Divider(height: 24),
          _buildDetailRow('NISN', _nisn.isEmpty ? '-' : _nisn),
          const Divider(height: 24),
          _buildDetailRow('Tahun Ajaran', _tahunAjaran.isEmpty ? '-' : _tahunAjaran),
          const Divider(height: 24),
          _buildDetailRow('Kelas/Ruang', _kelasRuang.isEmpty ? '-' : _kelasRuang),
          const Divider(height: 24),
          _buildDetailRow('Jenjang', _jenjang.isEmpty ? '-' : _jenjang),
          const Divider(height: 24),
          _buildDetailRow('Tingkat', _tingkat.isEmpty ? '-' : _tingkat),
          const Divider(height: 24),
          _buildDetailRow('Musyrif', _musyrif.isEmpty ? '-' : _musyrif),
          const Divider(height: 24),
          _buildDetailRow('Kamar', _kamar.isEmpty ? '-' : _kamar),
          const Divider(height: 24),
          _buildDetailRow('Halaqoh', _halaqoh.isEmpty ? '-' : _halaqoh),
          const Divider(height: 24),
          _buildDetailRow('Penanggung Jawab', _penanggungJawab.isEmpty ? '-' : _penanggungJawab),
        ],
      ),
    );
  }

  Widget _buildKelasCard() {
    return CustomCardWidget(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data Kelas Yang Ditempati Anak',
              style: AppStyles.sectionTitle(context)),
          const SizedBox(height: 16),
          _buildDetailRow('Kelas', _kelas),
          const Divider(height: 24),
          _buildDetailRow('Semester', _semester.isEmpty ? '-' : _semester),
          const Divider(height: 24),
          _buildDetailRow('Jumlah Siswa', _jumlahSiswa.isEmpty ? '-' : _jumlahSiswa),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Navigate to a new page showing class details
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DetailKelasPage(
                    className: _kelas.isEmpty ? 'Kelas' : _kelas,
                  ),
                ));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lihat Detail',
                      style: TextStyle(color: AppStyles.primaryColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppStyles.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySchedule(JadwalHarian jadwal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            jadwal.hari,
            style: AppStyles.bodyText(context).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppStyles.darkGreyColor,
            ),
          ),
          const SizedBox(height: 12),
          if (jadwal.pelajaran.isEmpty)
            const Text('Tidak ada jadwal untuk hari ini.')
          else
            CustomCardWidget(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: jadwal.pelajaran.length,
                itemBuilder: (context, index) {
                  final mapel = jadwal.pelajaran[index];
                  return _buildScheduleItem(mapel);
                },
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(MataPelajaran mapel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.schedule,
                color: AppStyles.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mapel.nama,
                  style: AppStyles.bodyText(context)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  mapel.jam,
                  style: AppStyles.bodyText(context)
                      .copyWith(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.bodyText(context)
                .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // Widget untuk tab prestasi
  Widget _buildPrestasiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan jumlah prestasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prestasi Santri',
                style: AppStyles.sectionTitle(context),
              ),
              if (_prestasiList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_prestasiList.length} Prestasi',
                    style: AppStyles.bodyText(context).copyWith(
                      color: AppStyles.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingPrestasi)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(
                  color: AppStyles.primaryColor,
                ),
              ),
            )
          else if (_prestasiList.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Belum ada prestasi yang tercatat',
                      style: AppStyles.bodyText(context).copyWith(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _prestasiList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final prestasi = _prestasiList[index];
                return _buildPrestasiItem(prestasi);
              },
            ),
        ],
      ),
    );
  }

  // Widget untuk item prestasi dengan collapse/expand
  Widget _buildPrestasiItem(Prestasi prestasi) {
    final isExpanded = _expandedPrestasiIds.contains(prestasi.id);
    final extraFields = _buildAdditionalPrestasiInfo(prestasi);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header yang bisa di-click untuk expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPrestasiIds.remove(prestasi.id);
                } else {
                  _expandedPrestasiIds.add(prestasi.id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon jenis prestasi
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getJenisColor(prestasi.jenis).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getJenisIcon(prestasi.jenis),
                      color: _getJenisColor(prestasi.jenis),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Informasi singkat
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prestasi.judul,
                          style: AppStyles.bodyText(context).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Badge juara
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getJuaraColor(prestasi.juara).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getJuaraColor(prestasi.juara).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                prestasi.juara,
                                style: AppStyles.bodyText(context).copyWith(
                                  color: _getJuaraColor(prestasi.juara),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge tingkat
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                _getTingkatLabel(prestasi.tingkat),
                                style: AppStyles.bodyText(context).copyWith(
                                  color: Colors.grey[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tanggal (singkat)
                            Flexible(
                              child: Text(
                                _formatTanggalSingkat(prestasi.tanggalPencapaian),
                                style: AppStyles.bodyText(context).copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Detail yang expandable
          if (isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _buildPrestasiDetailRow(
                    Icons.calendar_today,
                    'Tanggal',
                    prestasi.formattedDate,
                  ),
                  const SizedBox(height: 10),
                  _buildPrestasiDetailRow(
                    Icons.category,
                    'Jenis',
                    _getJenisLabel(prestasi.jenis),
                  ),
                  const SizedBox(height: 10),
                  _buildPrestasiDetailRow(
                    Icons.star,
                    'Tingkat',
                    _getTingkatLabel(prestasi.tingkat),
                  ),
                  if (prestasi.penyelenggara != null && prestasi.penyelenggara!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildPrestasiDetailRow(
                      Icons.business,
                      'Penyelenggara',
                      prestasi.penyelenggara!,
                    ),
                  ],
                  if (prestasi.deskripsi.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            prestasi.deskripsi,
                            style: AppStyles.bodyText(context).copyWith(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (extraFields.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...extraFields,
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrestasiDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppStyles.bodyText(context).copyWith(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppStyles.bodyText(context).copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Helper methods untuk styling
  Color _getJenisColor(JenisPrestasi jenis) {
    switch (jenis) {
      case JenisPrestasi.akademik:
        return Colors.blue;
      case JenisPrestasi.non_akademik:
        return Colors.purple;
      case JenisPrestasi.seni:
        return Colors.pink;
      case JenisPrestasi.olahraga:
        return Colors.orange;
      case JenisPrestasi.lainnya:
        return Colors.grey;
    }
  }

  IconData _getJenisIcon(JenisPrestasi jenis) {
    switch (jenis) {
      case JenisPrestasi.akademik:
        return Icons.school;
      case JenisPrestasi.non_akademik:
        return Icons.workspace_premium;
      case JenisPrestasi.seni:
        return Icons.palette;
      case JenisPrestasi.olahraga:
        return Icons.sports_soccer;
      case JenisPrestasi.lainnya:
        return Icons.emoji_events;
    }
  }

  String _getJenisLabel(JenisPrestasi jenis) {
    switch (jenis) {
      case JenisPrestasi.akademik:
        return 'Akademik';
      case JenisPrestasi.non_akademik:
        return 'Non Akademik';
      case JenisPrestasi.seni:
        return 'Seni';
      case JenisPrestasi.olahraga:
        return 'Olahraga';
      case JenisPrestasi.lainnya:
        return 'Lainnya';
    }
  }

  String _getTingkatLabel(TingkatPrestasi tingkat) {
    switch (tingkat) {
      case TingkatPrestasi.sekolah:
        return 'Sekolah';
      case TingkatPrestasi.kecamatan:
        return 'Kecamatan';
      case TingkatPrestasi.kabupaten:
        return 'Kabupaten';
      case TingkatPrestasi.provinsi:
        return 'Provinsi';
      case TingkatPrestasi.nasional:
        return 'Nasional';
      case TingkatPrestasi.internasional:
        return 'Internasional';
    }
  }

  Color _getJuaraColor(String juara) {
    final lowerJuara = juara.toLowerCase();
    if (lowerJuara.contains('juara 1') || lowerJuara.contains('juara i')) {
      return Colors.amber.shade700;
    } else if (lowerJuara.contains('juara 2') || lowerJuara.contains('juara ii')) {
      return Colors.grey.shade600;
    } else if (lowerJuara.contains('juara 3') || lowerJuara.contains('juara iii')) {
      return Colors.brown.shade600;
    } else {
      return AppStyles.primaryColor;
    }
  }

  // Helper untuk format tanggal singkat
  String _formatTanggalSingkat(DateTime tanggal) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(tanggal);
  }

  List<Widget> _buildAdditionalPrestasiInfo(Prestasi prestasi) {
    final entries = prestasi.rawData.entries.where((entry) {
      final key = entry.key.toLowerCase();
      if (_excludedPrestasiKeys.contains(key)) return false;
      final value = entry.value;
      if (value == null) return false;
      final str = _stringifyRawValue(value);
      return str.isNotEmpty;
    }).toList();

    if (entries.isEmpty) return [];

    return entries.map((entry) {
      final label = _formatFieldLabel(entry.key);
      final value = _stringifyRawValue(entry.value);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildPrestasiDetailRow(
          Icons.info_outline,
          label,
          value,
        ),
      );
    }).toList();
  }

  String _stringifyRawValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      if (value.isEmpty) return '';
      if (value.length == 2 && value.first is int && value.last is String) {
        return value.last.toString();
      }
      return value.map(_stringifyRawValue).where((e) => e.isNotEmpty).join(', ');
    }
    if (value is Map) {
      return value.entries
          .map((e) => '${_formatFieldLabel(e.key)}: ${_stringifyRawValue(e.value)}')
          .where((e) => e.trim().isNotEmpty)
          .join(', ');
    }
    return value.toString();
  }

  String _formatFieldLabel(String key) {
    final formatted = key.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (formatted.isEmpty) return key;
    return formatted.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  static const Set<String> _excludedPrestasiKeys = {
    'id',
    'prestasi_id',
    'judul',
    'name',
    'prestasi',
    'deskripsi',
    'keterangan',
    'catatan',
    'tingkat',
    'level',
    'jenis',
    'kategori',
    'type',
    'juara',
    'peringkat',
    'hasil',
    'tanggal_pencapaian',
    'tanggal',
    'achievement_date',
    'tgl',
    'date',
    'penyelenggara',
    'organizer',
    'instansi',
    'buktifile',
    'bukti',
    'attachment',
    'rawdata',
  };
}

// A private model class to hold all student data, including personal and academic.
// Model mock AcademicInfo tetap dipakai untuk jadwal saja

/// A new page to display the list of students in a class.
class DetailKelasPage extends StatelessWidget {
  final String className;

  const DetailKelasPage({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    // Using mock data for demonstration
    final List<String> studentsInClass = ClassData.studentsInClass;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Daftar Santri $className'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(
                          label: Text('No.',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('Nama Santri',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text('NIS',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: studentsInClass.asMap().entries.map((entry) {
                      final index = entry.key;
                      final studentName = entry.value;
                      return DataRow(
                        cells: [
                          DataCell(Text((index + 1).toString())),
                          DataCell(Text(studentName)),
                          DataCell(Text('12345${index + 1}')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download PDF'),
                onPressed: () {
                  _generateAndSavePdf(context, className, studentsInClass);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndSavePdf(
      BuildContext context, String className, List<String> students) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Membuat PDF...')),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) => [
          pw.Header(
            level: 0,
            child: pw.Text('Daftar Santri Kelas $className',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['No.', 'Nama Santri', 'NIS'],
            data: List<List<String>>.generate(
              students.length,
              (index) => [
                (index + 1).toString(),
                students[index],
                '12345${index + 1}', // Example NIS from list
              ],
            ),
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
            cellPadding: const pw.EdgeInsets.all(5),
            cellAlignments: {
              0: pw.Alignment.centerRight,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
            },
          ),
        ],
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final fileName = 'daftar_santri_${className.replaceAll(' ', '_')}.pdf';
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF berhasil disimpan di folder sementara aplikasi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}