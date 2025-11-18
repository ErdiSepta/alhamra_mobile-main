import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/data/student_data.dart';
import '../../../core/models/tahfidz_model.dart';
import '../../../core/utils/app_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../shared/widgets/index.dart';
import '../../shared/widgets/student_selection_widget.dart';
import '../../../core/data/tahfidz_service.dart';
import '../../../core/services/odoo_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class TahfidzPage extends StatefulWidget {
  const TahfidzPage({super.key});

  @override
  State<TahfidzPage> createState() => _TahfidzPageState();
}

class _TahfidzPageState extends State<TahfidzPage> {
  // --- State Management ---
  late Map<String, StudentTahfidzProfile> _allTahfidzData;
  late StudentTahfidzProfile _selectedProfile;
  final String _selectedStudentName = StudentData.defaultStudent;
  bool _isStudentOverlayVisible = false;
  String? _expandedEntryId;
  late List<TahfidzEntry> _filteredEntries;
  final TextEditingController _searchController = TextEditingController();
  final TahfidzService _service = TahfidzService();
  bool _loading = false;
  String? _errorMessage;
  List<String> _allStudents = const [];
  final Map<String, String> _nameToSiswaId = {};

  // --- Filter State ---
  String _selectedSortOrder = 'Terbaru';
  TahfidzStatus? _selectedStatusFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _generateMockData();
    _selectedProfile = _allTahfidzData[_selectedStudentName]!;
    _filteredEntries = _selectedProfile.entries;
    _searchController.addListener(_filterTahfidzEntries);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChildrenAndInitSelection();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _generateMockData() {
    _allTahfidzData = {
      for (var student in StudentData.allStudents)
        student: StudentTahfidzProfile.createMock(
            (StudentData.allStudents.indexOf(student) + 1).toString())
    };
  }

  void _updateSelectedData() {
    setState(() {
      // Reset filters and search when student changes
      _searchController.clear();
      _selectedSortOrder = 'Terbaru';
      _selectedStatusFilter = null;
      _startDate = null;
      _endDate = null;
      _filteredEntries = [];
      _loading = true;
    });
  }

  void _filterTahfidzEntries() {
    final query = _searchController.text.toLowerCase();
    var filtered = _selectedProfile.entries.where((entry) {
      final searchMatch = entry.surahName.toLowerCase().contains(query);
      final statusMatch =
          _selectedStatusFilter == null || entry.status == _selectedStatusFilter;

      // Normalize dates to ignore time component for correct comparison
      final entryDate =
          DateTime(entry.tanggal.year, entry.tanggal.month, entry.tanggal.day);
      final startDate = _startDate != null
          ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
          : null;
      final endDate = _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
          : null;

      final isAfterStartDate = startDate == null || !entryDate.isBefore(startDate);
      final isBeforeEndDate = endDate == null || !entryDate.isAfter(endDate);

      return searchMatch && statusMatch && isAfterStartDate && isBeforeEndDate;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      return _selectedSortOrder == 'Terbaru'
          ? b.tanggal.compareTo(a.tanggal)
          : a.tanggal.compareTo(b.tanggal);
    });

    setState(() {
      _filteredEntries = filtered;
    });
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      appBar: CustomAppBar(
        title: 'Tahfidz Qur’an',
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
                  child: _buildTahfidzDetails(),
                ),
              ),
            ],
          ),
          if (_isStudentOverlayVisible)
            SearchOverlayWidget(
              isVisible: _isStudentOverlayVisible,
              title: AppLocalizations.of(context).pilihSantri,
              items: _allStudents.isEmpty ? [StudentData.defaultStudent] : _allStudents,
              selectedItem: context.watch<AuthProvider>().selectedStudent,
              onItemSelected: (nama) async {
                // Tutup overlay seketika agar tidak menunggu proses lain
                setState(() { _isStudentOverlayVisible = false; });
                // Lanjutkan perubahan setelah frame berikutnya agar UI terasa cepat
                _updateSelectedData();
                final id = _nameToSiswaId[nama];
                if (id != null && id.isNotEmpty) {
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('siswa_id', id);
                  } catch (_) {}
                }
                try {
                  // ignore: use_build_context_synchronously
                  context.read<AuthProvider>().selectStudent(nama);
                } catch (_) {}
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadTahfidz();
                });
              },
              onClose: () => setState(() => _isStudentOverlayVisible = false),
              searchHint: AppLocalizations.of(context).cariSantri,
              avatarUrl: StudentData.getStudentAvatar(context.watch<AuthProvider>().selectedStudent.isEmpty
                  ? StudentData.defaultStudent
                  : context.watch<AuthProvider>().selectedStudent),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: StudentSelectionWidget(
        selectedStudent: context.watch<AuthProvider>().selectedStudent,
        students: _allStudents.isEmpty ? [StudentData.defaultStudent] : _allStudents,
        onStudentChanged: (nama) async {
          _updateSelectedData();
          final id = _nameToSiswaId[nama];
          if (id != null && id.isNotEmpty) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('siswa_id', id);
            } catch (_) {}
          }
          try {
            // ignore: use_build_context_synchronously
            context.read<AuthProvider>().selectStudent(nama);
          } catch (_) {}
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadTahfidz();
          });
        },
        onOverlayVisibilityChanged: (visible) =>
            setState(() => _isStudentOverlayVisible = visible),
        avatarUrl: StudentData.getStudentAvatar(
          context.watch<AuthProvider>().selectedStudent.isEmpty
              ? StudentData.defaultStudent
              : context.watch<AuthProvider>().selectedStudent,
        ),
      ),
    );
  }

  Widget _buildTahfidzDetails() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: _buildSearchAndFilter(),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    )
                  : (_filteredEntries.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context).tidakAdaDataCocok))
                      : Container(
                          margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredEntries.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredEntries[index];
                              return _buildTahfidzItem(entry);
                            },
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, indent: 16, endIndent: 16),
                          ),
                        )),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tahfidz Qur’an',
          style: AppStyles.sectionTitle(context)
              .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari Berdasarkan Surah',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: _showFilterBottomSheet,
              icon: const Icon(Icons.filter_list, size: 20),
              label: const Text('Filter'),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTahfidzItem(TahfidzEntry entry) {
    final isExpanded = _expandedEntryId == entry.id;
    final statusColor = _getColorForStatus(entry.status);
    final statusText = _getTextForStatus(entry.status);

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedEntryId = isExpanded ? null : entry.id;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.surahName,
                    style: AppStyles.bodyText(context).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statusText,
                      style: AppStyles.bodyText(context).copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.id,
                      style: AppStyles.bodyText(context).copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildTahfidzDetailCard(entry),
      ],
    );
  }

  Widget _buildTahfidzDetailCard(TahfidzEntry entry) {
    String dashIfEmpty(String? s) => (s == null || s.isEmpty) ? '-' : s;
    String dashIfZero(int? n) => (n == null || n == 0) ? '-' : n.toString();
    return Container(
      padding: const EdgeInsets.fromLTRB(36, 0, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildDetailRow('Tanggal', DateFormat('dd/MM/yyyy').format(entry.tanggal)),
          const SizedBox(height: 12),
          _buildDetailRow('Sesi', _getTextForStatus(entry.status)),
          const SizedBox(height: 12),
          _buildDetailRow('Surah', entry.surahName),
          const SizedBox(height: 12),
          _buildDetailRow('Ayat Awal', dashIfEmpty(entry.ayatAwal)),
          const SizedBox(height: 12),
          _buildDetailRow('Ayat Akhir', dashIfEmpty(entry.ayatAkhir)),
          const SizedBox(height: 12),
          _buildDetailRow('Jumlah Baris', entry.jumlahBaris.toString()),
          const SizedBox(height: 12),
          _buildDetailRow('Halaman Awal', dashIfZero(entry.pageAwal)),
          const SizedBox(height: 12),
          _buildDetailRow('Halaman Akhir', dashIfZero(entry.pageAkhir)),
          const SizedBox(height: 12),
          _buildDetailRow('Nilai', dashIfEmpty(entry.nilai)),
          const SizedBox(height: 12),
          _buildDetailRow('Ustadz', entry.ustadPembimbing.isEmpty ? '-' : entry.ustadPembimbing),
          const SizedBox(height: 12),
          _buildDetailRow('Status', entry.stateLabel ?? _getTextForStatus(entry.status)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style:
                AppStyles.bodyText(context).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    // Temporary state for the bottom sheet
    String tempSortOrder = _selectedSortOrder;
    TahfidzStatus? tempStatus = _selectedStatusFilter;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Tahfidz', style: AppStyles.heading2(context)),
                  const SizedBox(height: 24),
                  Text('Urutkan Berdasarkan',
                      style: AppStyles.bodyText(context)
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: _buildSortButton(
                              'Terbaru', tempSortOrder == 'Terbaru',
                              () => setModalState(() => tempSortOrder = 'Terbaru'))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildSortButton(
                              'Terlama', tempSortOrder == 'Terlama',
                              () => setModalState(() => tempSortOrder = 'Terlama'))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatusDropdown(tempStatus, (value) {
                    setModalState(() => tempStatus = value);
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker('Dari', tempStartDate,
                            (date) => setModalState(() => tempStartDate = date),
                            onClear: () =>
                                setModalState(() => tempStartDate = null)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDatePicker('Sampai', tempEndDate,
                            (date) => setModalState(() => tempEndDate = date),
                            onClear: () =>
                                setModalState(() => tempEndDate = null)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempSortOrder = 'Terbaru';
                              tempStatus = null;
                              tempStartDate = null;
                              tempEndDate = null;
                            });
                          },
                          child: const Text('Atur Ulang'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedSortOrder = tempSortOrder;
                              _selectedStatusFilter = tempStatus;
                              _startDate = tempStartDate;
                              _endDate = tempEndDate;
                              _filterTahfidzEntries();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortButton(String label, bool isSelected, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            isSelected ? AppStyles.primaryColor.withOpacity(0.1) : Colors.transparent,
        side: BorderSide(
            color: isSelected ? AppStyles.primaryColor : Colors.grey.shade300),
      ),
      child: Text(label,
          style:
              TextStyle(color: isSelected ? AppStyles.primaryColor : Colors.black87)),
    );
  }

  Widget _buildStatusDropdown(
      TahfidzStatus? selectedValue, ValueChanged<TahfidzStatus?> onChanged) {
    List<DropdownMenuItem<TahfidzStatus?>> items = [
      const DropdownMenuItem<TahfidzStatus?>(value: null, child: Text('Semua')),
    ];

    items.addAll(TahfidzStatus.values.map((status) {
      return DropdownMenuItem<TahfidzStatus?>(
        value: status,
        child: Text(_getTextForStatus(status)),
      );
    }).toList());

    return DropdownButtonFormField<TahfidzStatus?>(
      value: selectedValue, 
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Pilih Status Hafalan',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate,
      Function(DateTime) onDateSelected, {VoidCallback? onClear}) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2101),
          locale: const Locale('id', 'ID'),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppStyles.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_today,
                  size: 18, color: AppStyles.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppStyles.bodyText(context).copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedDate != null
                        ? DateFormat('d MMM yyyy', 'id_ID').format(selectedDate)
                        : 'Pilih tanggal',
                    style: AppStyles.bodyText(context).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: selectedDate != null
                          ? Colors.black87
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDate != null && onClear != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.close, size: 16, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorForStatus(TahfidzStatus status) {
    switch (status) {
      case TahfidzStatus.mumtaz:
        return Colors.green.shade600;
      case TahfidzStatus.jayyidJiddan:
        return Colors.blue.shade600;
      case TahfidzStatus.lancar:
        return Colors.teal.shade500;
      case TahfidzStatus.murojaah:
        return Colors.purple.shade500;
      case TahfidzStatus.pentashihan:
        return Colors.orange.shade700;
      case TahfidzStatus.kurangLancar:
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  String _getTextForStatus(TahfidzStatus status) {
    switch (status) {
      case TahfidzStatus.murojaah:
        return 'Murojaah';
      case TahfidzStatus.mumtaz:
        return 'Mumtaz';
      case TahfidzStatus.jayyidJiddan:
        return 'Jayyid Jiddan';
      case TahfidzStatus.lancar:
        return 'Lancar';
      case TahfidzStatus.pentashihan:
        return 'Pentashihan';
      case TahfidzStatus.kurangLancar:
        return 'Kurang Lancar';
      default:
        return 'N/A';
    }
  }

  Future<void> _loadTahfidz() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // Prefer siswa_id dari pilihan saat ini untuk menghindari salah anak
      final selectedName = context.read<AuthProvider>().selectedStudent;
      String? siswaId = _nameToSiswaId[selectedName];
      if (siswaId == null || siswaId.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          siswaId = prefs.getString('siswa_id');
        } catch (_) {}
      }
      final items = await _service.fetchRiwayat(page: 1, limit: 50, siswaId: siswaId);
      if (!mounted) return;
      final mapped = items.map<TahfidzEntry>((it) {
        final status = _mapStatus(it.state, it.nilaiName);
        final ket = _composeKeterangan(it);
        return TahfidzEntry(
          surahName: it.surahName,
          status: status,
          id: it.id,
          jumlahBaris: it.jmlBaris ?? 0,
          keterangan: ket,
          ustadPembimbing: it.ustadzName ?? '-',
          tanggal: it.tanggal,
          ayatAwal: it.ayatAwalText,
          ayatAkhir: it.ayatAkhirText,
          pageAwal: it.pageAwal,
          pageAkhir: it.pageAkhir,
          nilai: it.nilaiName,
          stateLabel: it.state,
        );
      }).toList()
        ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

      setState(() {
        _selectedProfile = StudentTahfidzProfile(studentId: _selectedProfile.studentId, entries: mapped);
        _filteredEntries = mapped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  TahfidzStatus _mapStatus(String state, String? nilai) {
    final s = state.toLowerCase();
    final n = (nilai ?? '').toLowerCase();
    if (n.contains('muro')) return TahfidzStatus.murojaah;
    if (n.contains('mumtaz')) return TahfidzStatus.mumtaz;
    if (n.contains('jidd')) return TahfidzStatus.jayyidJiddan;
    if (n.contains('jayyid')) return TahfidzStatus.lancar;
    if (n.contains('tashih') || n.contains('tashihan') || n.contains('pentas')) return TahfidzStatus.pentashihan;
    if (s == 'draft') return TahfidzStatus.murojaah;
    if (s == 'done' && n.isEmpty) return TahfidzStatus.lancar;
    return TahfidzStatus.lancar;
  }

  String _composeKeterangan(TahfidzServerItem it) {
    final ayat = it.ayatAwalText != null
        ? 'Ayat ${it.ayatAwalText}${it.ayatAkhirText != null ? '–${it.ayatAkhirText}' : ''}'
        : '';
    final nilai = it.nilaiName != null && it.nilaiName!.isNotEmpty ? it.nilaiName! : '';
    final ketServer = (it.keterangan ?? '').isNotEmpty ? it.keterangan! : '';
    return [ayat, nilai, ketServer].where((e) => e.isNotEmpty).join(' • ');
  }

  Future<void> _loadChildrenAndInitSelection() async {
    try {
      final odoo = OdooApiService();
      await odoo.loadSession();
      final children = await odoo.getChildren();
      final names = <String>[];
      _nameToSiswaId.clear();
      for (final c in children) {
        final name = (c['name'] ?? c['nama'] ?? c['nama_lengkap'] ?? c['full_name'] ?? '').toString();
        final id = (c['siswa_id'] ?? c['student_id'] ?? c['id'] ?? c['partner_id'] ?? '').toString();
        if (name.isNotEmpty && id.isNotEmpty) {
          names.add(name);
          _nameToSiswaId[name] = id;
        }
      }
      if (!mounted) return;
      setState(() {
        _allStudents = names.isEmpty ? StudentData.allStudents : names;
      });
      final provider = context.read<AuthProvider>();
      var selected = provider.selectedStudent;
      if (selected.isEmpty || !_nameToSiswaId.containsKey(selected)) {
        if (names.isNotEmpty) {
          selected = names.first;
          provider.selectStudent(selected);
        }
      }
      if (selected.isNotEmpty && _nameToSiswaId.containsKey(selected)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('siswa_id', _nameToSiswaId[selected]!);
      }
      await _loadTahfidz();
    } catch (_) {}
  }
}
