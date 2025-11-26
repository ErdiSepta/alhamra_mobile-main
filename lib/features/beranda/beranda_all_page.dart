import 'package:alhamra_1/core/utils/app_styles.dart';
import '../../core/data/dashboard_data.dart';
import '../../core/data/student_data.dart';
import '../../core/localization/app_localizations.dart';
import '../shared/widgets/search_overlay_widget.dart';
import '../shared/widgets/student_selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../core/data/payment_service.dart';
import '../../core/services/odoo_api_service.dart';
import '../../core/data/pocket_money_service.dart';
import '../../core/data/canteen_service.dart';
import '../../core/models/pocket_money_history.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/data/tahfidz_service.dart';
import '../../core/data/perizinan_service.dart';
import '../../core/data/mutabaah_service.dart';
import '../../core/data/kesehatan_service.dart';
import '../../core/data/pelanggaran_service.dart';
import '../../core/models/perizinan_history.dart';
import '../../core/models/kesehatan_history.dart';
import '../../core/models/pelanggaran_history.dart';
import '../../core/models/absensi_model.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

/// Custom painter for circular progress indicator
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Draw progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      (progress * 2 * math.pi), // Sweep angle
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class BerandaAllPage extends StatefulWidget {
  const BerandaAllPage({super.key});

  @override
  State<BerandaAllPage> createState() => _BerandaAllPageState();
}

class _BerandaAllPageState extends State<BerandaAllPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Remove static dashboard data usage for keuangan
  String _saldoUangSaku = 'Rp 0';
  String _saldoWallet = 'Rp 0';
  
  // Santri selection state
  String _selectedSantri = StudentData.defaultStudent;
  String? _selectedSiswaId;
  List<String> _childrenNames = const [];
  final Map<String, String> _nameToId = {};
  bool _isStudentOverlayVisible = false;
  bool _isLoadingStudents = false;
  String _amountTagihan = 'Rp 0';
  String _amountUangSaku = 'Rp 0';
  double _persentaseLunas = 0.0; // 0..100

  // Kesantrian data state
  bool _isLoadingKesantrian = false;
  String _totalIzin = '0';
  String _totalHafalan = '-';
  String _totalSetoran = '0';
  String _setoranTerakhir = '-';
  String _setoranTanggal = '-';
  String _mutabaahScore = '0';
  String _mutabaahStatus = '-';
  List<FlSpot> _setoranChartData = [];
  int _totalSakitSemester = 0;
  int _pelanggaranRingan = 0;
  int _pelanggaranSedang = 0;
  int _pelanggaranBerat = 0;
  int _totalPerihal = 0;
  int _totalTerapiKesehatan = 0;

  // Services
  final TahfidzService _tahfidzService = TahfidzService();
  final PerizinanService _perizinanService = PerizinanService();
  final MutabaahService _mutabaahService = MutabaahService();
  final KesehatanService _kesehatanService = KesehatanService();
  final PelanggaranService _pelanggaranService = PelanggaranService();
  final CanteenService _canteenService = CanteenService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBillsTotal();
      _loadPocketMoneyTotal();
      _initStudentSelection();
      _loadKesantrianData();
    });
  }

  Future<void> _initStudentSelection() async {
    setState(() {
      _isLoadingStudents = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('siswa_id');
      final odoo = OdooApiService();
      await odoo.loadSession();
      final children = await odoo.getChildren();
      final names = <String>[];
      _nameToId.clear();
      for (final child in children) {
        final name = (child['name'] ?? child['nama'] ?? '').toString();
        final id = (child['id'] ?? child['siswa_id'])?.toString() ?? '';
        if (name.isEmpty || id.isEmpty) continue;
        names.add(name);
        _nameToId[name] = id;
      }

      String selectedName = _selectedSantri;
      String? selectedId = savedId;

      if (names.isNotEmpty) {
        if (selectedId != null) {
          final matchEntry = _nameToId.entries.firstWhere(
            (entry) => entry.value == selectedId,
            orElse: () => const MapEntry('', ''),
          );
          if (matchEntry.key.isNotEmpty) {
            selectedName = matchEntry.key;
          } else {
            selectedName = names.first;
            selectedId = _nameToId[selectedName];
          }
        } else {
          selectedName = names.first;
          selectedId = _nameToId[selectedName];
        }
      }

      if (selectedName.isNotEmpty) {
        try {
          context.read<AuthProvider>().selectStudent(selectedName);
        } catch (_) {}
      }

      if (selectedId != null && selectedId.isNotEmpty) {
        await prefs.setString('siswa_id', selectedId);
      }

      if (!mounted) return;
      setState(() {
        _childrenNames = names;
        if (selectedName.isNotEmpty) {
          _selectedSantri = selectedName;
        }
        _selectedSiswaId = selectedId;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _childrenNames = StudentData.allStudents;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  Future<void> _loadBillsTotal() async {
    try {
      String? sessionId;
      String? siswaId;
      try {
        final prefs = await SharedPreferences.getInstance();
        sessionId = prefs.getString('session_id');
        siswaId = prefs.getString('siswa_id');
        sessionId ??= prefs.getString('odoo_session_id');
      } catch (_) {}

      if (sessionId == null || sessionId.isEmpty) {
        try {
          final odoo = OdooApiService();
          await odoo.loadSession();
          sessionId = odoo.sessionId;
        } catch (_) {}
      }
      if (siswaId == null || siswaId.isEmpty) {
        try {
          final odoo = OdooApiService();
          await odoo.loadSession();
          final children = await odoo.getChildren();
          if (children.isNotEmpty) {
            siswaId = children.first['id'].toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('siswa_id', siswaId);
          }
        } catch (_) {}
      }
      siswaId ??= _selectedSiswaId;
      if (sessionId == null || siswaId == null || siswaId.isEmpty) return;

      final service = PaymentService();
      final bills = await service.fetchBillsForSiswa(
        sessionId: sessionId,
        siswaId: siswaId,
        page: 1,
        limit: 50,
      );
      final totalOutstanding = bills
          .where((b) => b.isPayable)
          .fold<int>(0, (p, b) => p + b.outstanding);
      final int sumTotal = bills.fold<int>(0, (p, b) => p + b.amount);
      final int sumPaid = bills.fold<int>(0, (p, b) => p + (b.amountPaid ?? 0));
      final double percentPaid = (sumTotal > 0)
          ? (sumPaid / sumTotal) * 100.0
          : 0.0;
      if (!mounted) return;
      setState(() {
        _amountTagihan = _formatRupiah(totalOutstanding);
        _persentaseLunas = percentPaid.clamp(0.0, 100.0);
      });
    } catch (_) {}
  }

  String _formatRupiah(int amount) {
    final s = amount.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'Rp ${s.replaceAllMapped(reg, (m) => '.')}';
  }

  Future<void> _loadPocketMoneyTotal() async {
    // Dummy data: tidak lagi menghitung dari API, hanya menampilkan nilai tetap.
    if (!mounted) return;
    setState(() {
      // Ubah angka di sini jika ingin nilai dummy berbeda.
      _saldoUangSaku = _formatRupiah(0);
      _saldoWallet = _formatRupiah(15300);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sync with global selected student so changes from other pages propagate here
    String? providerStudent;
    try {
      providerStudent = context.watch<AuthProvider>().selectedStudent;
    } catch (_) {
      providerStudent = null;
    }
    if (providerStudent != null && providerStudent.isNotEmpty && providerStudent != _selectedSantri) {
      _selectedSantri = providerStudent;
      final siswaId = _nameToId[_selectedSantri];
      if (siswaId != null && siswaId.isNotEmpty) {
        _selectedSiswaId = siswaId;
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('siswa_id', siswaId);
        });
      }
      _loadBillsTotal();
      _loadPocketMoneyTotal();
      _loadKesantrianData();
    }
    return Stack(
      children: [
        // Main scaffold
        Scaffold(
          body: Column(
            children: [
              // Blue header section
              Container(
                color: AppStyles.primaryColor,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildStudentSelector(),
                    ],
                  ),
                ),
              ),
              // Tab bar section
              _buildTabBar(),
              // White content section
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: IgnorePointer(
                    ignoring: _isStudentOverlayVisible,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSemuaTab(),
                        _buildKeuanganTab(),
                        _buildKesantrianTab(),
                        _buildAkademikTab(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Full-screen overlay untuk pemilihan santri
        if (_isStudentOverlayVisible)
          SearchOverlayWidget(
            isVisible: _isStudentOverlayVisible,
            title: AppLocalizations.of(context).pilihSantri,
            items: _childrenNames.isEmpty ? StudentData.allStudents : _childrenNames,
            selectedItem: _selectedSantri,
            onItemSelected: (santri) {
              _handleStudentSelection(santri);
            },
            onClose: () {
              setState(() {
                _isStudentOverlayVisible = false;
              });
            },
            searchHint: AppLocalizations.of(context).cariSantri,
            avatarUrl: StudentData.defaultAvatarUrl,
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            localizations.beranda,
            style: AppStyles.heading1(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Opacity(
        opacity: _isLoadingStudents ? 0.5 : 1,
        child: AbsorbPointer(
          absorbing: _isLoadingStudents,
          child: StudentSelectionWidget(
            selectedStudent: _selectedSantri,
            students: _childrenNames.isEmpty ? [StudentData.defaultStudent] : _childrenNames,
            onStudentChanged: _handleStudentSelection,
            onOverlayVisibilityChanged: (visible) {
              setState(() {
                _isStudentOverlayVisible = visible;
              });
            },
            avatarUrl: StudentData.getStudentAvatar(_selectedSantri),
          ),
        ),
      ),
    );
  }

  void _handleStudentSelection(String santri) async {
    setState(() {
      _selectedSantri = santri;
      _isStudentOverlayVisible = false;
    });
    final id = _nameToId[santri];
    if (id != null && id.isNotEmpty) {
      _selectedSiswaId = id;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('siswa_id', id);
      } catch (_) {}
    }
    try {
      context.read<AuthProvider>().selectStudent(santri);
    } catch (_) {}
    _loadBillsTotal();
    _loadPocketMoneyTotal();
    _loadKesantrianData();
  }

  Widget _buildTabBar() {
    final localizations = AppLocalizations.of(context);
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        indicatorColor: AppStyles.primaryColor,
        indicatorWeight: 2,
        labelColor: AppStyles.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
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
        tabs: [
          Tab(text: localizations.semua),
          Tab(text: localizations.keuangan),
          Tab(text: localizations.kesantrian),
          Tab(text: localizations.akademik),
        ],
      ),
    );
  }


  Widget _buildSemuaTab() {
    final localizations = AppLocalizations.of(context);
    return Container(
      color: AppStyles.greyColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Keuangan overview
            _buildKeuanganCards(),
            const SizedBox(height: 20),

            // Kesantrian overview (reuse same cards as Kesantrian tab)
            _buildPerizinanCard(localizations),
            const SizedBox(height: 16),
            _buildTahfidzCard(localizations),
            const SizedBox(height: 16),
            _buildSetoranTerakhirCard(localizations),
            const SizedBox(height: 16),
            _buildPerkembanganSetoranCard(localizations),
            const SizedBox(height: 16),
            _buildMutabaahHarianCard(localizations),
            const SizedBox(height: 16),
            _buildAktivitasKesehatan(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildKeuanganTab() {
    return Container(
      color: AppStyles.greyColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildKeuanganCards(),
      ),
    );
  }

  Widget _buildKesantrianTab() {
    final localizations = AppLocalizations.of(context);
    return Container(
      color: AppStyles.greyColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perizinan Card
            _buildPerizinanCard(localizations),
            const SizedBox(height: 16),
            // Tahfidz Al-Quran Card
            _buildTahfidzCard(localizations),
            const SizedBox(height: 16),
            // Setoran Terakhir Card
            _buildSetoranTerakhirCard(localizations),
            const SizedBox(height: 16),
            // Perkembangan Setoran Card
            _buildPerkembanganSetoranCard(localizations),
            const SizedBox(height: 16),
            // Mutabaah Harian Card
            _buildMutabaahHarianCard(localizations),
            const SizedBox(height: 16),
            // Aktivitas & Kesehatan Card
            _buildAktivitasKesehatan(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildAkademikTab() {
    final localizations = AppLocalizations.of(context);

    // Dummy akademik overview menggunakan sample data dashboard
    final akademikOverview = DashboardData.getSampleData().akademik;

    // Dummy data absensi untuk presentasi & distribusi kehadiran
    final attendance = AttendanceData.createMock('1');
    return Container(
      color: AppStyles.greyColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAkademikAttendanceCard(
              localizations,
              attendancePercentage: attendance.attendancePercentage,
              hadir: attendance.hadirCount,
              izin: attendance.izinCount,
              alpha: attendance.alphaCount,
            ),
            const SizedBox(height: 16),
            _buildAkademikCard(akademikOverview, isFullPage: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAkademikAttendanceCard(
    AppLocalizations localizations, {
    required double attendancePercentage,
    required int hadir,
    required int izin,
    required int alpha,
  }) {
    final statusText = attendancePercentage >= 95
        ? 'Excellent'
        : attendancePercentage >= 90
            ? 'Very Good'
            : attendancePercentage >= 80
                ? 'Good'
                : 'Needs Improvement';

    // Hitung persentase distribusi berdasarkan jumlah hari
    final totalDays = hadir + izin + alpha;
    final hadirPercent = totalDays > 0 ? (hadir / totalDays) * 100 : 0.0;
    final izinPercent = totalDays > 0 ? (izin / totalDays) * 100 : 0.0;
    final alphaPercent = totalDays > 0 ? (alpha / totalDays) * 100 : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.kehadiran,
                  style: AppStyles.heading2(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontSize: 11,
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${attendancePercentage.toStringAsFixed(1)}%',
                          style: AppStyles.heading2(context).copyWith(
                            fontSize: 20,
                            color: AppStyles.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kehadiran',
                          style: AppStyles.sectionTitle(context).copyWith(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Hadir', style: AppStyles.sectionTitle(context)),
                          Text('$hadir hari', style: AppStyles.sectionTitle(context)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Izin', style: AppStyles.sectionTitle(context)),
                          Text('$izin hari', style: AppStyles.sectionTitle(context)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Alpha', style: AppStyles.sectionTitle(context)),
                          Text('$alpha hari', style: AppStyles.sectionTitle(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distribusi Kehadiran',
                  style: AppStyles.heading2(context).copyWith(fontSize: 16),
                ),
                const Icon(
                  Icons.pie_chart_outline,
                  size: 20,
                  color: Colors.blueGrey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 220,
                width: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF4CAF50),
                        value: hadirPercent,
                        title: '',
                        radius: 60,
                        badgeWidget: _buildPieLabel(
                          color: const Color(0xFF4CAF50),
                          text: 'Hadir ${hadirPercent.toStringAsFixed(1)}%',
                        ),
                        badgePositionPercentageOffset: 1.8,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFFFA000),
                        value: izinPercent,
                        title: '',
                        radius: 60,
                        badgeWidget: _buildPieLabel(
                          color: const Color(0xFFFFA000),
                          text: 'Izin ${izinPercent.toStringAsFixed(1)}%',
                        ),
                        badgePositionPercentageOffset: 1.8,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFD32F2F),
                        value: alphaPercent,
                        title: '',
                        radius: 60,
                        badgeWidget: _buildPieLabel(
                          color: const Color(0xFFD32F2F),
                          text: 'Alpha ${alphaPercent.toStringAsFixed(1)}%',
                        ),
                        badgePositionPercentageOffset: 1.8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAkademikDistributionCard(
    AppLocalizations localizations, {
    required double hadirPercent,
    required double izinPercent,
    required double alphaPercent,
  }) {
    final totalPercent = hadirPercent + izinPercent + alphaPercent;
    final safeHadir = totalPercent == 0 ? 0.0 : hadirPercent;
    final safeIzin = totalPercent == 0 ? 0.0 : izinPercent;
    final safeAlpha = totalPercent == 0 ? 0.0 : alphaPercent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Distribusi Kehadiran',
                  style: AppStyles.heading2(context),
                ),
                const Icon(
                  Icons.pie_chart_outline,
                  size: 20,
                  color: Colors.blueGrey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox
              (
                height: 220,
                width: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF4CAF50),
                        value: safeHadir,
                        title: '',
                        radius: 60,
                        badgeWidget: _buildPieLabel(
                          color: const Color(0xFF4CAF50),
                          text: 'Hadir ${safeHadir.toStringAsFixed(1)}%',
                        ),
                        badgePositionPercentageOffset: 1.8,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFFFA000),
                        value: safeIzin,
                        title: '',
                        radius: 60,
                        badgeWidget: _buildPieLabel(
                          color: const Color(0xFFFFA000),
                          text: 'Izin ${safeIzin.toStringAsFixed(1)}%',
                        ),
                        badgePositionPercentageOffset: 1.8,
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFD32F2F),
                        value: safeAlpha,
                        title: '',
                        radius: 60,
                        badgeWidget: _buildPieLabel(
                          color: const Color(0xFFD32F2F),
                          text: 'Alpha ${safeAlpha.toStringAsFixed(1)}%',
                        ),
                        badgePositionPercentageOffset: 1.8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeuanganCards() {
    final localizations = AppLocalizations.of(context);
    // Persentase dibulatkan untuk tampilan pie chart dan legend
    final double lunasPercent = _persentaseLunas.clamp(0.0, 100.0);
    final double kurangPercent = (100.0 - lunasPercent).clamp(0.0, 100.0);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and filter icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.keuangan,
                  style: AppStyles.heading2(context),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // First row - Total Tagihan Aktif
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.totalTagihanAktif,
                    style: AppStyles.sectionTitle(context).copyWith(
                      color: const Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _amountTagihan,
                    style: AppStyles.heading1(context).copyWith(
                      color: const Color(0xFFD32F2F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Second row - Saldo cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.saldoUangSaku,
                          style: AppStyles.sectionTitle(context).copyWith(
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _saldoUangSaku,
                          style: AppStyles.saldoValue(context).copyWith(
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.saldoWallet,
                          style: AppStyles.sectionTitle(context).copyWith(
                            color: const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _saldoWallet,
                          style: AppStyles.saldoValue(context).copyWith(
                            color: const Color(0xFF1976D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Progress indicators
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.lunas} ${_persentaseLunas.toInt()}%',
                  style: AppStyles.sectionTitle(context),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${localizations.kurang} ${(100 - _persentaseLunas).toInt()}%',
                  style: AppStyles.sectionTitle(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _persentaseLunas.toInt(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (100 - _persentaseLunas).toInt(),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Pie Chart with Legend Below
            Column(
              children: [
                Center(
                  child: SizedBox(
                    height: 240,
                    width: 240,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: const Color(0xFF2196F3),
                            value: lunasPercent,
                            radius: 72,
                            title: '',
                            badgeWidget: _buildPieLabel(
                              color: const Color(0xFF2196F3),
                              text: '${localizations.lunas} ${lunasPercent.toStringAsFixed(0)}%',
                            ),
                            badgePositionPercentageOffset: 1.9,
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFFF5252),
                            value: kurangPercent,
                            radius: 72,
                            title: '',
                            badgeWidget: _buildPieLabel(
                              color: const Color(0xFFFF5252),
                              text: '${localizations.kurang} ${kurangPercent.toStringAsFixed(0)}%',
                            ),
                            badgePositionPercentageOffset: 1.9,
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legend Below Chart
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(const Color(0xFF2196F3), '${localizations.lunas} ${lunasPercent.toStringAsFixed(0)}%'),
                    const SizedBox(width: 40),
                    _buildLegend(const Color(0xFFFF5252), '${localizations.kurang} ${kurangPercent.toStringAsFixed(0)}%'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildKesantrianCards(KesantrianOverview data) {
    final localizations = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with title and icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.kesantrian,
                  style: AppStyles.heading2(context).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cards row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.totalHafalan,
                          style: AppStyles.sectionTitle(context).copyWith(
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.totalHafalan,
                          style: AppStyles.saldoValue(context).copyWith(
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBDEFB), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.semesterIni,
                          style: AppStyles.sectionTitle(context).copyWith(
                            color: const Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.detailSetoran,
                          style: AppStyles.facilityDescription(context).copyWith(
                            color: const Color(0xFF1976D2),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAkademikCard(AkademikOverview data, {bool isFullPage = false}) {
    final localizations = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.akademik,
                  style: AppStyles.heading2(context),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCountChip(localizations.totalAbsen, '${data.totalAbsen} ${localizations.hari}', Colors.orange),
                _buildCountChip(localizations.rataRataNilai, data.rataRataNilai.toString(), Colors.purple),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Text('${localizations.perkembanganNilai} (6 ${localizations.bulan})', style: AppStyles.bodyText(context).copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < data.perkembanganNilai.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(data.perkembanganNilai[value.toInt()].bulan, style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.perkembanganNilai.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.nilai);
                      }).toList(),
                      isCurved: true,
                      color: AppStyles.primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppStyles.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCountChip(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
      ],
    );
  }


  Future<void> _loadKesantrianData() async {
    setState(() {
      _isLoadingKesantrian = true;
    });
    try {
      String? siswaId = _selectedSiswaId;
      if (siswaId == null || siswaId.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          siswaId = prefs.getString('siswa_id');
        } catch (_) {}
      }
      if (siswaId == null || siswaId.isEmpty) return;

      // Load all Kesantrian data in parallel
      final tahfidzFuture = _tahfidzService.fetchRiwayat(siswaId: siswaId, limit: 100);
      final perizinanFuture = _perizinanService.fetchRiwayat(siswaId: siswaId, limit: 100);
      final mutabaahFuture = _mutabaahService.fetchRiwayat(siswaId: siswaId, limit: 100);
      final kesehatanFuture = _kesehatanService.fetchRiwayat(siswaId: siswaId, limit: 100);
      final pelanggaranFuture = _pelanggaranService.fetchRiwayat(siswaId: siswaId, limit: 100);

      final results = await Future.wait([
        tahfidzFuture,
        perizinanFuture,
        mutabaahFuture,
        kesehatanFuture,
        pelanggaranFuture,
      ], eagerError: false);

      if (!mounted) return;

      final tahfidzList = results[0] as List<TahfidzServerItem>;
      final perizinanList = results[1] as List<PerizinanHistory>;
      final mutabaahList = results[2] as List<MutabaahServerItem>;
      final kesehatanList = results[3] as List<KesehatanHistory>;
      final pelanggaranList = results[4] as List<PelanggaranHistory>;

      // Process Tahfidz data
      int totalHafalan = 0;
      String setoranTerakhir = '-';
      String setoranTanggal = '-';
      final chartData = <FlSpot>[];
      
      if (tahfidzList.isNotEmpty) {
        totalHafalan = tahfidzList.length;
        final lastEntry = tahfidzList.first;
        setoranTerakhir = lastEntry.surahName;
        setoranTanggal = DateFormat('dd MMM yyyy', 'id_ID').format(lastEntry.tanggal);
        
        // Build chart data (last 6 entries)
        final chartEntries = tahfidzList.take(6).toList().reversed.toList();
        for (int i = 0; i < chartEntries.length; i++) {
          chartData.add(FlSpot(i.toDouble(), (i + 1) * 50.0));
        }
      }

      // Process Perizinan data
      final totalIzin = perizinanList.length;

      // Process Mutabaah data
      String mutabaahScore = '0';
      String mutabaahStatus = '-';
      if (mutabaahList.isNotEmpty) {
        final latestMutabaah = mutabaahList.first;
        // Bersihkan nilai skor agar hanya angka (misal "9" dari "9 dari 9")
        final rawScore = latestMutabaah.totalSkor ?? '';
        final match = RegExp(r'\d+').firstMatch(rawScore);
        mutabaahScore = match?.group(0) ?? rawScore;
        mutabaahStatus = latestMutabaah.status;
      }

      // Process Kesehatan data
      final totalSakitSemester = kesehatanList.length;

      // Process Pelanggaran data
      int pelanggaranRingan = 0;
      int pelanggaranSedang = 0;
      int pelanggaranBerat = 0;
      for (final p in pelanggaranList) {
        if (p.status.toLowerCase().contains('ringan')) {
          pelanggaranRingan++;
        } else if (p.status.toLowerCase().contains('sedang')) {
          pelanggaranSedang++;
        } else if (p.status.toLowerCase().contains('berat')) {
          pelanggaranBerat++;
        }
      }

      setState(() {
        _totalIzin = totalIzin.toString();
        _totalHafalan = totalHafalan.toString();
        _totalSetoran = totalHafalan.toString();
        _setoranTerakhir = setoranTerakhir;
        _setoranTanggal = setoranTanggal;
        _mutabaahScore = mutabaahScore;
        _mutabaahStatus = mutabaahStatus;
        _setoranChartData = chartData;
        _totalSakitSemester = totalSakitSemester;
        _pelanggaranRingan = pelanggaranRingan;
        _pelanggaranSedang = pelanggaranSedang;
        _pelanggaranBerat = pelanggaranBerat;
        _totalPerihal = pelanggaranList.length;
        _totalTerapiKesehatan = kesehatanList.length;
        _isLoadingKesantrian = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('Error loading Kesantrian data: $e');
      setState(() {
        _isLoadingKesantrian = false;
      });
    }
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppStyles.sectionTitle(context).copyWith(
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Label kecil di luar pie chart untuk menampilkan persentase
  Widget _buildPieLabel({required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyles.sectionTitle(context).copyWith(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPerizinanCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.perizinan,
                  style: AppStyles.heading2(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '2025',
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.totalIzin,
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _totalIzin,
                    style: AppStyles.heading1(context).copyWith(
                      color: const Color(0xFF1976D2),
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTahfidzCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.tahfidz,
                  style: AppStyles.heading2(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '2025',
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Two column layout (Poin Pelanggaran & Total Prestasi)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.totalHafalan,
                          style: AppStyles.sectionTitle(context).copyWith(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalHafalan,
                          style: AppStyles.heading1(context).copyWith(
                            color: const Color(0xFF1976D2),
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.totalSetoran,
                          style: AppStyles.sectionTitle(context).copyWith(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalSetoran,
                          style: AppStyles.heading1(context).copyWith(
                            color: const Color(0xFF2E7D32),
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.setoranSetoran,
                          style: AppStyles.sectionTitle(context).copyWith(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetoranTerakhirCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.setoranTerakhir,
              style: AppStyles.heading2(context),
            ),
            const SizedBox(height: 16),
            // Setoran item
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _setoranTerakhir,
                        style: AppStyles.sectionTitle(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _setoranTanggal,
                        style: AppStyles.sectionTitle(context).copyWith(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _setoranTanggal,
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerkembanganSetoranCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.perkembanganSetoran,
              style: AppStyles.heading2(context),
            ),
            const SizedBox(height: 16),
            // Chart
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          const months = ['Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt'];
                          if (value.toInt() < months.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(months[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 300,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _setoranChartData.isEmpty
                          ? const [
                              FlSpot(0, 50),
                              FlSpot(1, 120),
                              FlSpot(2, 100),
                              FlSpot(3, 180),
                              FlSpot(4, 150),
                              FlSpot(5, 200),
                            ]
                          : _setoranChartData,
                      isCurved: true,
                      color: AppStyles.primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppStyles.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutabaahHarianCard(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.mutabaahHarian,
              style: AppStyles.heading2(context),
            ),
            const SizedBox(height: 20),
            // Circular score display
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyles.primaryColor,
                    ),
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          // Ambil hanya bagian pertama sebelum spasi (misal "9" dari "9 dari 9")
                          final displayScore = (_mutabaahScore.split(' ').isNotEmpty)
                              ? _mutabaahScore.split(' ').first
                              : _mutabaahScore;
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              displayScore,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: AppStyles.heading1(context).copyWith(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.skorHariIni,
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _mutabaahStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.sectionTitle(context).copyWith(
                        color: const Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAktivitasKesehatan(AppLocalizations localizations) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.aktivitasKesehatan,
                  style: AppStyles.heading2(context),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '2025',
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Two column layout
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning, color: Color(0xFFFFA726), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Poin Pelanggaran',
                              style: AppStyles.sectionTitle(context).copyWith(
                                fontSize: 12,
                                color: const Color(0xFFFFA726),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalPerihal.toString(),
                          style: AppStyles.heading1(context).copyWith(
                            color: const Color(0xFFFFA726),
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hati-hati',
                          style: AppStyles.sectionTitle(context).copyWith(
                            fontSize: 11,
                            color: const Color(0xFFFFA726),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Total Prestasi',
                              style: AppStyles.sectionTitle(context).copyWith(
                                fontSize: 12,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _totalTerapiKesehatan.toString(),
                          style: AppStyles.heading1(context).copyWith(
                            color: const Color(0xFF2E7D32),
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Total Sakit Semester Ini
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.totalSakitSemesterIni,
                    style: AppStyles.sectionTitle(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_totalSakitSemester}x',
                        style: AppStyles.sectionTitle(context).copyWith(
                          color: const Color(0xFFD32F2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Terakhir: -',
                          style: AppStyles.sectionTitle(context).copyWith(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.thermostat,
                        size: 18,
                        color: Color(0xFFD32F2F),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Jenis Pelanggaran
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.jenisPelanggaran,
                  style: AppStyles.sectionTitle(context),
                ),
                const SizedBox(height: 12),
                _buildViolationItem('Ringan', _pelanggaranRingan.toString()),
                const SizedBox(height: 8),
                _buildViolationItem('Sedang', _pelanggaranSedang.toString()),
                const SizedBox(height: 8),
                _buildViolationItem('Berat', _pelanggaranBerat.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationItem(String label, String count) {
    final colors = {
      'Ringan': const Color(0xFFFFF9C4),
      'Sedang': const Color(0xFFFFE0B2),
      'Berat': const Color(0xFFFFCDD2),
    };
    final textColors = {
      'Ringan': const Color(0xFFF57F17),
      'Sedang': const Color(0xFFF57C00),
      'Berat': const Color(0xFFD32F2F),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.sectionTitle(context).copyWith(
            fontSize: 12,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors[label] ?? Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: textColors[label] ?? Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
