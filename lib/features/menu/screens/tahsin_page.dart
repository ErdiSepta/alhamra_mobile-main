import 'package:alhamra_1/features/shared/widgets/student_selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/data/student_data.dart';
import '../../../core/models/tahsin_model.dart';
import '../../../core/utils/app_styles.dart';
import '../../shared/widgets/index.dart';

class TahsinPage extends StatefulWidget {
  const TahsinPage({super.key});

  @override
  State<TahsinPage> createState() => _TahsinPageState();
}

class _TahsinPageState extends State<TahsinPage> {
  // --- State Management ---
  late Map<String, StudentTahsinProfile> _allTahsinData;
  late StudentTahsinProfile _selectedProfile;
  String _selectedStudentName = StudentData.defaultStudent;
  bool _isStudentOverlayVisible = false;
  String? _expandedEntryId;
  late List<TahsinEntry> _filteredEntries;
  final TextEditingController _searchController = TextEditingController();

  // --- Filter State ---
  String _selectedSortOrder = 'Terbaru';
  TahsinStatus? _selectedStatusFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _generateMockData();
    _selectedProfile = _allTahsinData[_selectedStudentName]!;
    _filteredEntries = _selectedProfile.entries;
    _searchController.addListener(_filterTahsinEntries);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _generateMockData() {
    _allTahsinData = {
      for (var student in StudentData.allStudents)
        student: StudentTahsinProfile.createMock(
            (StudentData.allStudents.indexOf(student) + 1).toString())
    };
  }

  void _updateSelectedData() {
    setState(() {
      _selectedProfile = _allTahsinData[_selectedStudentName]!;
      // Reset filters and search when student changes
      _searchController.clear();
      _selectedSortOrder = 'Terbaru';
      _selectedStatusFilter = null;
      _startDate = null;
      _endDate = null;
      _filterTahsinEntries(); // Apply reset filters
    });
  }

  void _filterTahsinEntries() {
    final query = _searchController.text.toLowerCase();
    var filtered = _selectedProfile.entries.where((entry) {
      final searchMatch = entry.materi.toLowerCase().contains(query);
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

      final isAfterStartDate =
          startDate == null || !entryDate.isBefore(startDate);
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
        title: 'Tahsin Qur’an',
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
                  child: _buildTahsinDetails(),
                ),
              ),
            ],
          ),
          if (_isStudentOverlayVisible)
            SearchOverlayWidget(
              isVisible: _isStudentOverlayVisible,
              title: 'Pilih Santri',
              items: StudentData.allStudents,
              selectedItem: _selectedStudentName,
              onItemSelected: (nama) {
                setState(() {
                  _selectedStudentName = nama;
                  _updateSelectedData();
                  _isStudentOverlayVisible = false;
                });
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
        students: StudentData.allStudents,
        onStudentChanged: (nama) {
          setState(() {
            _selectedStudentName = nama;
            _updateSelectedData();
          });
        },
        onOverlayVisibilityChanged: (visible) =>
            setState(() => _isStudentOverlayVisible = visible),
        avatarUrl: StudentData.getStudentAvatar(_selectedStudentName),
      ),
    );
  }

  Widget _buildTahsinDetails() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: _buildSearchAndFilter(),
        ),
        Expanded(
          child: _filteredEntries.isEmpty
              ? const Center(child: Text('Tidak ada data yang cocok.'))
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
                      return _buildTahsinItem(entry);
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tahsin Qur’an',
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
                  hintText: 'Cari Berdasarkan Materi',
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

  Widget _buildTahsinItem(TahsinEntry entry) {
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
                    entry.materi,
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
        if (isExpanded) _buildTahsinDetailCard(entry),
      ],
    );
  }

  Widget _buildTahsinDetailCard(TahsinEntry entry) {
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
          _buildDetailRow('Jumlah Baris', entry.jumlahBaris.toString()),
          const SizedBox(height: 12),
          _buildDetailRow('Keterangan', entry.keterangan),
          const SizedBox(height: 12),
          _buildDetailRow('Ustad Pembimbing', entry.ustadPembimbing),
          const SizedBox(height: 12),
          _buildDetailRow('Tanggal',
              DateFormat('d MMMM yyyy', 'id_ID').format(entry.tanggal)),
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
    TahsinStatus? tempStatus = _selectedStatusFilter;
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
                  Text('Filter Tahsin', style: AppStyles.heading2(context)),
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
                              _filterTahsinEntries();
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
      TahsinStatus? selectedValue, ValueChanged<TahsinStatus?> onChanged) {
    List<DropdownMenuItem<TahsinStatus?>> items = [
      const DropdownMenuItem<TahsinStatus?>(value: null, child: Text('Semua')),
    ];

    items.addAll(TahsinStatus.values.map((status) {
      return DropdownMenuItem<TahsinStatus?>(
        value: status,
        child: Text(_getTextForStatus(status)),
      );
    }).toList());

    return DropdownButtonFormField<TahsinStatus?>(
      value: selectedValue, 
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Pilih Status Penilaian',
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

  Color _getColorForStatus(TahsinStatus status) {
    switch (status) {
      case TahsinStatus.mumtaz:
        return Colors.green.shade600;
      case TahsinStatus.jayyidJiddan:
        return Colors.blue.shade600;
      case TahsinStatus.lancar:
        return Colors.teal.shade500;
      case TahsinStatus.murojaah:
        return Colors.purple.shade500;
      case TahsinStatus.pentashihan:
        return Colors.orange.shade700;
      case TahsinStatus.kurangLancar:
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  String _getTextForStatus(TahsinStatus status) {
    switch (status) {
      case TahsinStatus.murojaah:
        return 'Murojaah';
      case TahsinStatus.mumtaz:
        return 'Mumtaz';
      case TahsinStatus.jayyidJiddan:
        return 'Jayyid Jiddan';
      case TahsinStatus.lancar:
        return 'Lancar';
      case TahsinStatus.pentashihan:
        return 'Perbaikan';
      case TahsinStatus.kurangLancar:
        return 'Kurang Lancar';
      default:
        return 'N/A';
    }
  }
}