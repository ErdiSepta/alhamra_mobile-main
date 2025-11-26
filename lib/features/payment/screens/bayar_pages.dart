import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_styles.dart';
import '../../../core/data/student_data.dart';
import '../../../core/models/bill.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/data/payment_service.dart';
import '../../../core/data/auth_service.dart';
import '../../../core/services/odoo_api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../shared/widgets/index.dart';
import '../../shared/widgets/student_selection_widget.dart';
import 'custom_status_menunggu_page.dart';
import 'status_berhasil_page.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key, this.initialTabIndex = 0});
  
  final int initialTabIndex;

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _listController = ScrollController();
  String _selectedStudent = StudentData.defaultStudent;
  List<String> _students = StudentData.allStudents;
  final Map<String, String> _nameToSiswaId = {};
  bool _isStudentOverlayVisible = false;
  bool _isLoadingStudents = false;
  String? _currentSiswaId;
  
  // Filter state variables
  String _selectedSortOrder = 'Terbaru';
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Payment type filters
  final Map<String, bool> _paymentTypeFilters = {
    'SPP': true,
    'Seragam': true,
    'Makan': true,
    'Buku': true,
    'Kegiatan': true,
    'Lainnya': true,
  };

  // Payment data loaded from API
  final PaymentService _paymentService = PaymentService();
  List<PaymentItem> _allPayments = [];
  bool _isLoadingPayments = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        _scrollListToTop();
      }
    });
    _initStudentsFromServer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentsFromServer();
    });
  }

  Future<void> _onStudentChanged(String student) async {
    setState(() {
      _selectedStudent = student;
    });

    // Persist siswa_id berdasarkan nama santri yang dipilih
    final id = _nameToSiswaId[student];
    if (id != null && id.isNotEmpty) {
      _currentSiswaId = id;
      // ignore: avoid_print
      print('[StatusPage] Student changed to "$student" with siswaId=$id');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('siswa_id', id);
      } catch (_) {}
    }

    // Update provider agar halaman lain juga ikut berubah
    try {
      context.read<AuthProvider>().selectStudent(student);
    } catch (_) {}

    // Reload data pembayaran untuk santri terpilih
    // ignore: avoid_print
    print('[StatusPage] Reloading payments after student change');
    await _loadPaymentsFromServer();
  }

  Future<void> _initStudentsFromServer() async {
    setState(() {
      _isLoadingStudents = true;
    });
    try {
      final odoo = OdooApiService();
      await odoo.loadSession();
      final children = await odoo.getChildren();

      final names = <String>[];
      _nameToSiswaId.clear();
      for (final c in children) {
        final name = (c['name'] ?? c['nama'] ?? '').toString();
        final id = c['id']?.toString() ?? '';
        if (name.isNotEmpty && id.isNotEmpty) {
          names.add(name);
          _nameToSiswaId[name] = id;
        }
      }

      if (!mounted) return;

      // Tentukan selected berdasarkan nama terakhir di SharedPreferences,
      // bila tidak ada gunakan AuthProvider, lalu fallback ke yang pertama
      String selected = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        selected = prefs.getString('selected_student_name') ?? '';
      } catch (_) {}

      final provider = context.read<AuthProvider>();
      if (selected.isEmpty) {
        selected = provider.selectedStudent;
      }
      if ((selected.isEmpty || !_nameToSiswaId.containsKey(selected)) && names.isNotEmpty) {
        selected = names.first;
        provider.selectStudent(selected);
      }

      // Simpan siswa_id terpilih ke SharedPreferences
      if (selected.isNotEmpty && _nameToSiswaId.containsKey(selected)) {
        final prefs = await SharedPreferences.getInstance();
        final siswaId = _nameToSiswaId[selected]!;
        _currentSiswaId = siswaId;
        await prefs.setString('siswa_id', siswaId);
      }

      setState(() {
        _students = names.isNotEmpty ? names : _students;
        if (selected.isNotEmpty) {
          _selectedStudent = selected;
        }
      });
    } catch (_) {
      // Jika gagal, biarkan fallback ke StudentData default
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  Future<void> _loadPaymentsFromServer() async {
    setState(() {
      _isLoadingPayments = true;
    });
    try {
      var sessionId = await AuthService.getSessionId();
      var siswaId = _currentSiswaId ?? await AuthService.getSiswaId();

      // Fallback: baca session dari prefs / OdooApiService jika perlu
      if (sessionId == null || sessionId.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          sessionId = prefs.getString('odoo_session_id');
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
            _currentSiswaId = siswaId;
            await prefs.setString('siswa_id', siswaId);
          }
        } catch (_) {}
      }

      if (sessionId == null || sessionId.isEmpty || siswaId == null || siswaId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session atau Siswa tidak tersedia. Silakan login.')),
          );
        }
        return;
      }

      // Debug prints
      // ignore: avoid_print
      print('[StatusPage] Using sessionId=$sessionId siswaId=$siswaId');

      final bills = await _paymentService.fetchBillsForSiswa(
        sessionId: sessionId,
        siswaId: siswaId,
        page: 1,
        limit: 50,
      );

      // ignore: avoid_print
      print('[StatusPage] Fetched bills count=${bills.length}');

      final selectedStudentName = context.read<AuthProvider>().selectedStudent;
      final displayName = selectedStudentName.isEmpty ? _selectedStudent : selectedStudentName;

      final items = bills.map((bill) {
        PaymentStatus status;
        switch (bill.status) {
          case BillStatus.paid:
            status = PaymentStatus.lunas;
            break;
          case BillStatus.partial:
            status = PaymentStatus.sebagian;
            break;
          case BillStatus.unpaid:
          case BillStatus.pending:
          default:
            status = PaymentStatus.belumLunas;
            break;
        }

        return PaymentItem(
          id: bill.id,
          type: bill.title,
          studentName: displayName,
          amount: bill.amount,
          dueDate: bill.dueDate,
          status: status,
        );
      }).toList();

      // ignore: avoid_print
      print('[StatusPage] Mapped payments count=${items.length}');

      if (!mounted) return;
      setState(() {
        _allPayments = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pembayaran: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPayments = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  List<PaymentItem> _getFilteredPayments() {
    List<PaymentItem> filtered = _allPayments;
    
    // Filter by tab
    final currentTab = _tabController.index;
    if (currentTab == 1) { // Menunggu - only yellow cards (belumLunas/sebagian)
      filtered = filtered.where((p) => p.status == PaymentStatus.belumLunas || p.status == PaymentStatus.sebagian).toList();
    } else if (currentTab == 2) { // Terkonfirmasi - only green cards (lunas)
      filtered = filtered.where((p) => p.status == PaymentStatus.lunas).toList();
    }
    
    // Filter by payment types
    filtered = filtered.where((payment) {
      final values = _paymentTypeFilters.values.toList();
      final anySelected = values.any((v) => v);
      final allSelected = values.every((v) => v);

      // If no categories are selected at all, show nothing
      if (!anySelected) {
        return false;
      }

      // If all categories are selected (default state), do not filter by type
      if (allSelected) {
        return true;
      }

      // Otherwise, map payment.type ke kategori dan cek apakah dipilih
      final cat = _getPaymentCategory(payment);
      return _paymentTypeFilters[cat] == true;
    }).toList();
    
    // Filter by date range
    if (_startDate != null && _endDate != null) {
      filtered = filtered.where((payment) {
        return payment.dueDate.isAfter(_startDate!) && payment.dueDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Sort by selected order
    switch (_selectedSortOrder) {
      case 'Terbaru':
        // Newest due date first
        filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case 'Terlama':
        // Oldest due date first
        filtered.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case 'Nominal Tertinggi':
        // Highest nominal first
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Nominal Terendah':
        // Lowest nominal first
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        filtered.sort((a, b) => b.dueDate.compareTo(a.dueDate));
    }
    
    return filtered;
  }

  String _getPaymentCategory(PaymentItem payment) {
    final text = payment.type.toLowerCase();

    if (text.contains('spp')) return 'SPP';
    if (text.contains('seragam')) return 'Seragam';
    if (text.contains('makan')) return 'Makan';
    if (text.contains('buku')) return 'Buku';
    if (text.contains('kegiatan') || text.contains('ekstrakurikuler')) return 'Kegiatan';
    return 'Lainnya';
  }

  @override
  Widget build(BuildContext context) {
    // Listen to global selected student so changes from other pages keep this page in sync
    String? providerStudent;
    try {
      providerStudent = context.watch<AuthProvider>().selectedStudent;
    } catch (_) {
      providerStudent = null;
    }
    if (providerStudent != null && providerStudent.isNotEmpty && providerStudent != _selectedStudent) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() {
          _selectedStudent = providerStudent!;
        });
        final id = _nameToSiswaId[_selectedStudent];
        if (id != null && id.isNotEmpty) {
          _currentSiswaId = id;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('siswa_id', id);
          } catch (_) {}
        }
        await _loadPaymentsFromServer();
      });
    }
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Blue gradient header section
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
              // White content section
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      _buildTabBar(),
                      _buildFilterSection(),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5F7FA),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildPaymentList(), // Semua
                              _buildPaymentList(), // Menunggu
                              _buildPaymentList(), // Terkonfirmasi
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Add overlay at the top level to ensure it appears above all content
          if (_isStudentOverlayVisible)
            SearchOverlayWidget(
              isVisible: _isStudentOverlayVisible,
              title: AppLocalizations.of(context).pilihSantri,
              items: _students,
              selectedItem: _selectedStudent,
              onItemSelected: (student) async {
                await _onStudentChanged(student);
                if (!mounted) return;
                setState(() {
                  _isStudentOverlayVisible = false;
                });
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(AppLocalizations.of(context).pembayaran, style: AppStyles.heading1(context)),
        ],
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Opacity(
      opacity: _isLoadingStudents ? 0.5 : 1,
      child: AbsorbPointer(
        absorbing: _isLoadingStudents,
        child: StudentSelectionWidget(
          selectedStudent: _selectedStudent,
          students: _students.isEmpty ? [StudentData.defaultStudent] : _students,
          onStudentChanged: _onStudentChanged,
          onOverlayVisibilityChanged: (visible) {
            setState(() {
              _isStudentOverlayVisible = visible;
            });
          },
          avatarUrl: StudentData.defaultAvatarUrl,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppStyles.primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppStyles.primaryColor,
        indicatorWeight: 2,
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
        onTap: (index) {
          _scrollListToTop();
          setState(() {});
        },
        tabs: [
          Tab(text: AppLocalizations.of(context).semua),
          Tab(text: AppLocalizations.of(context).diproses),
          Tab(text: AppLocalizations.of(context).selesai),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left area: sort chips (always visible) + active filter chips (if any)
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.start,
              runSpacing: 4,
              spacing: 4,
              children: [
                ..._buildSortChips(),
                if (_hasActiveFilters) _buildActiveFilters(),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Filter button (right)
          GestureDetector(
            onTap: _showFilterDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppStyles.getButtonBorderRadius(context) / 2),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).filter,
                    style: AppStyles.bodyText(context).copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppStyles.primaryColor),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.tune,
                    size: 14,
                    color: AppStyles.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    final hasDate = _startDate != null && _endDate != null;
    final selectedTypes = _paymentTypeFilters.entries.where((e) => e.value).length;
    final hasTypeSelection = selectedTypes > 0 && selectedTypes < _paymentTypeFilters.length;
    return hasDate || hasTypeSelection;
  }

  List<Widget> _buildSortChips() {
    final isTerbaru = _selectedSortOrder == 'Terbaru';
    final chipStyle = AppStyles.bodyText(context).copyWith(fontSize: 11);
    return [
      ChoiceChip(
        label: Text(AppLocalizations.of(context).terbaru, style: chipStyle),
        selected: isTerbaru,
        onSelected: (v) {
          if (!isTerbaru) {
            setState(() => _selectedSortOrder = 'Terbaru');
          }
        },
        selectedColor: AppStyles.primaryColor.withOpacity(0.15),
        side: BorderSide(color: isTerbaru ? AppStyles.primaryColor : Colors.grey.shade300),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        labelStyle: chipStyle.copyWith(
          color: isTerbaru ? AppStyles.primaryColor : Colors.black87,
          fontWeight: isTerbaru ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      ChoiceChip(
        label: Text(AppLocalizations.of(context).terlama, style: chipStyle),
        selected: !isTerbaru,
        onSelected: (v) {
          if (isTerbaru) {
            setState(() => _selectedSortOrder = 'Terlama');
          }
        },
        selectedColor: AppStyles.primaryColor.withOpacity(0.15),
        side: BorderSide(color: !isTerbaru ? AppStyles.primaryColor : Colors.grey.shade300),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        labelStyle: chipStyle.copyWith(
          color: !isTerbaru ? AppStyles.primaryColor : Colors.black87,
          fontWeight: !isTerbaru ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    ];
  }

  Widget _buildActiveFilters() {
    final chips = <Widget>[];

    // Payment type chips (show only when not all are selected)
    final allCount = _paymentTypeFilters.length;
    final selectedEntries = _paymentTypeFilters.entries.where((e) => e.value).toList();
    if (selectedEntries.isNotEmpty && selectedEntries.length < allCount) {
      for (final entry in selectedEntries) {
        chips.add(Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 4),
          child: InputChip(
            label: Text(entry.key, style: AppStyles.bodyText(context).copyWith(fontSize: 11)),
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            onDeleted: () {
              setState(() {
                _paymentTypeFilters[entry.key] = false;
              });
            },
            deleteIcon: const Icon(Icons.close, size: 14),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey[300]!),
          ),
        ));
      }
    }

    // Date range chip
    if (_startDate != null && _endDate != null) {
      final label = '${_formatDateDisplay(_startDate!)} - ${_formatDateDisplay(_endDate!)}';
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        child: InputChip(
          avatar: const Icon(Icons.date_range, size: 14),
          label: Text(label, style: AppStyles.bodyText(context).copyWith(fontSize: 11)),
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          onDeleted: () {
            setState(() {
              _startDate = null;
              _endDate = null;
            });
          },
          deleteIcon: const Icon(Icons.close, size: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ));
    }

    // Sort order chip (only when not default)
    if (_selectedSortOrder != 'Terbaru') {
      chips.add(Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 4),
        child: InputChip(
          avatar: const Icon(Icons.sort, size: 14),
          label: Text('Urut: $_selectedSortOrder', style: AppStyles.bodyText(context).copyWith(fontSize: 11)),
          labelPadding: const EdgeInsets.symmetric(horizontal: 6),
          onDeleted: () {
            setState(() {
              _selectedSortOrder = 'Terbaru';
            });
          },
          deleteIcon: const Icon(Icons.close, size: 14),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ));
    }

    // Clear all chip
    chips.add(Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: ActionChip(
        avatar: const Icon(Icons.clear_all, size: 14),
        label: Text(AppLocalizations.of(context).delete, style: AppStyles.bodyText(context).copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        onPressed: () {
          setState(() {
            _selectedSortOrder = 'Terbaru';
            _startDate = null;
            _endDate = null;
            _paymentTypeFilters.updateAll((key, value) => true);
          });
        },
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey[300]!),
      ),
    ));

    return Wrap(children: chips);
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // ensure it overlays bottom navbar
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryFilterWidget(
        title: 'Filter Pembayaran',
        selectedSortOrder: _selectedSortOrder,
        startDate: _startDate,
        endDate: _endDate,
        categoryFilters: Map.from(_paymentTypeFilters),
        availableCategories: _paymentTypeFilters.keys.toList(),
        onSortOrderChanged: (v) => _selectedSortOrder = v,
        onStartDateChanged: (d) => _startDate = d,
        onEndDateChanged: (d) => _endDate = d,
        onCategoryFiltersChanged: (map) => _paymentTypeFilters
          ..clear()
          ..addAll(map),
        onApply: () {
          setState(() {});
          _scrollListToTop();
          // Tutup bottom sheet setelah filter diterapkan
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedSortOrder = 'Terbaru';
            _startDate = null;
            _endDate = null;
            _paymentTypeFilters.updateAll((key, value) => true);
          });
        },
      ),
    );
  }

  Widget _buildSortButton(String label, StateSetter setModalState) {
    final isSelected = _selectedSortOrder == label;
    return GestureDetector(
      onTap: () {
        setModalState(() {
          _selectedSortOrder = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppStyles.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppStyles.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, Function(DateTime) onDateSelected) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
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
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? _formatDateDisplay(date) : 'Pilih tanggal',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: date != null ? Colors.black87 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  Widget _buildPaymentList() {
    if (_isLoadingPayments) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredPayments = _getFilteredPayments();

    if (filteredPayments.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      controller: _listController,
      itemCount: filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = filteredPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  void _scrollListToTop() {
    if (_listController.hasClients) {
      _listController.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  Widget _buildEmptyState() {
    return CustomEmptyStateWidget(
      icon: Icons.payment_outlined,
      title: AppLocalizations.of(context).tidakAdaPembayaran,
      subtitle: AppLocalizations.of(context).cobaUbahFilter,
    );
  }

  Widget _buildPaymentCard(PaymentItem payment) {
    Color cardColor;
    Color statusColor;
    String statusText;
    
    switch (payment.status) {
      case PaymentStatus.lunas:
        cardColor = const Color(0xFF00C896); // Green for lunas
        statusColor = const Color(0xFF00A67E);
        statusText = AppLocalizations.of(context).lunas;
        break;
      case PaymentStatus.belumLunas:
      case PaymentStatus.sebagian:
        cardColor = const Color(0xFFFFC107); // Yellow for menunggu (both belumLunas and sebagian)
        statusColor = const Color(0xFFFF8F00);
        statusText = payment.status == PaymentStatus.belumLunas ? AppLocalizations.of(context).belumLunas : AppLocalizations.of(context).sudahLunas;
        break;
    }
    
    final radius = AppStyles.getCardBorderRadius(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        children: [
          // Header with payment type
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
            ),
            child: Text(
              _translatePaymentType(payment.type),
              style: AppStyles.sectionTitle(context).copyWith(
                color: Colors.white,
              ),
            ),
          ),
          // Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(radius),
                bottomRight: Radius.circular(radius),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID Invoice', style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600], fontSize: 12)),
                        Text(
                          payment.id,
                          style: AppStyles.bodyText(context).copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: AppStyles.bodyText(context).copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).namaSantri, style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600], fontSize: 12)),
                        Text(
                          _selectedStudent,
                          style: AppStyles.bodyText(context).copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          payment.status == PaymentStatus.lunas ? AppLocalizations.of(context).dikonfirmasi : AppLocalizations.of(context).tenggatBayar,
                          style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          _formatDate(payment.dueDate),
                          style: AppStyles.bodyText(context).copyWith(fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).nominalBayar, style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600], fontSize: 12)),
                        Text(
                          _formatCurrency(payment.amount),
                          style: AppStyles.saldoValue(context).copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to appropriate detail page based on payment status
                        if (payment.status == PaymentStatus.lunas) {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) => StatusBerhasilPage(amount: payment.amount),
                              fullscreenDialog: true,
                            ),
                          );
                        } else {
                          // For belumLunas and sebagian (menunggu status)
                          // Create PaymentData for CustomStatusMenungguPage
                          final paymentData = PaymentData(
                            bills: [
                              Bill(
                                id: payment.id,
                                title: payment.type,
                                subtitle: 'Pembayaran ${payment.type}',
                                amount: payment.amount,
                                dueDate: payment.dueDate,
                                status: payment.status == PaymentStatus.belumLunas ? BillStatus.unpaid : BillStatus.partial,
                                period: '${payment.dueDate.month}/${payment.dueDate.year}',
                              ),
                            ],
                            studentName: payment.studentName,
                            paymentMethod: 'Transfer Bank',
                            virtualAccount: '1234567890123456',
                            totalAmount: payment.amount,
                            paymentDate: DateTime.now(),
                            invoiceId: payment.id,
                            senderName: 'Muhammad Faithfullah Ilhamy Azda',
                            administrator: 'Diah Al Quwari',
                          );
                          
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (context) => CustomStatusMenungguPage(paymentData: paymentData),
                              fullscreenDialog: true,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppStyles.getButtonBorderRadius(context) / 2),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).lihatDetail,
                        style: AppStyles.bodyText(context).copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatCurrency(int amount) {
    return 'Rp. ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
  
  String _translatePaymentType(String type) {
    final localizations = AppLocalizations.of(context);
    switch (type) {
      case 'Uang Tahunan':
        return localizations.uangTahunan;
      case 'SPP Santri':
        return localizations.sppSantri;
      case 'Seragam':
        return localizations.seragam;
      case 'Uang Pembangunan':
        return localizations.uangPembangunan;
      case 'Uang Sumbangan':
        return localizations.uangSumbangan;
      default:
        return type;
    }
  }
}

class PaymentItem {
  final String id;
  final String type;
  final String studentName;
  final int amount;
  final DateTime dueDate;
  final PaymentStatus status;

  PaymentItem({
    required this.id,
    required this.type,
    required this.studentName,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}

enum PaymentStatus {
  belumLunas,
  sebagian,
  lunas,
}
