import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';

import '../../../core/models/pocket_money_history.dart';
import '../../../core/utils/app_styles.dart';
import '../../shared/widgets/history_filter_widget.dart';
import 'detail_uang_saku_page.dart';
import '../../../core/data/pocket_money_service.dart';
import '../../../core/providers/auth_provider.dart';

class RiwayatUangSakuPage extends StatefulWidget {
  const RiwayatUangSakuPage({super.key});

  @override
  State<RiwayatUangSakuPage> createState() => _RiwayatUangSakuPageState();
}

class _RiwayatUangSakuPageState extends State<RiwayatUangSakuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedPeriod = 'Bulan Ini';
  String _selectedCategory = 'Pemasukan';
  final PocketMoneyService _service = PocketMoneyService();
  bool _loading = false;
  String? _errorMessage;
  List<PocketMoneyHistory> _apiTransactions = [];
  String? _lastSelectedStudent;

  // Filter state variables
  // Separate filter states per tab
  String _selectedSortOrderIn = 'Terbaru';
  DateTime? _startDateIn;
  DateTime? _endDateIn;
  String _selectedSortOrderOut = 'Terbaru';
  DateTime? _startDateOut;
  DateTime? _endDateOut;
  // Report tab filter (date range only, UI tetap sama)
  String _reportSortOrder = 'Terbaru';
  DateTime? _reportStartDate;
  DateTime? _reportEndDate;

  // Category filters for pocket money
  final Map<String, bool> _categoryFiltersIn = {
    'Top Up': true,
    'Pembelian': true,
    'Transfer': true,
    'Penarikan': true,
    'Lainnya': true,
  };
  final Map<String, bool> _categoryFiltersOut = {
    'Top Up': true,
    'Pembelian': true,
    'Transfer': true,
    'Penarikan': true,
    'Lainnya': true,
  };

  // Dummy data untuk riwayat uang saku
  final List<PocketMoneyHistory> _allTransactions = [
    PocketMoneyHistory(
      id: 'US-001',
      title: 'Dana Masuk Dari',
      subtitle: 'Muhammad Ilham',
      amount: 1200000,
      date: DateTime(2025, 7, 22, 12, 9),
      type: PocketMoneyTransactionType.incoming,
      bankName: 'Bank Mandiri',
    ),
    PocketMoneyHistory(
      id: 'US-002',
      title: 'Pembelian Makanan',
      subtitle: 'Kantin Pesantren',
      amount: 25000,
      date: DateTime(2025, 7, 21, 13, 30),
      type: PocketMoneyTransactionType.outgoing,
      bankName: 'Uang Saku',
    ),
    PocketMoneyHistory(
      id: 'US-003',
      title: 'Dana Masuk Dari',
      subtitle: 'Muhammad Ilham',
      amount: 500000,
      date: DateTime(2025, 7, 20, 10, 15),
      type: PocketMoneyTransactionType.incoming,
      bankName: 'Bank Mandiri',
    ),
    PocketMoneyHistory(
      id: 'US-004',
      title: 'Pembelian Buku',
      subtitle: 'Toko Buku Al-Ikhlas',
      amount: 75000,
      date: DateTime(2025, 7, 19, 15, 0),
      type: PocketMoneyTransactionType.outgoing,
      bankName: 'Uang Saku',
    ),
    PocketMoneyHistory(
      id: 'US-005',
      title: 'Penarikan Tunai',
      subtitle: 'ATM Sekolah',
      amount: 100000,
      date: DateTime(2025, 7, 18, 11, 45),
      type: PocketMoneyTransactionType.outgoing,
      bankName: 'Uang Saku',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto refetch when selected student changes
    final selectedStudent = context.watch<AuthProvider>().selectedStudent;
    if (_lastSelectedStudent != selectedStudent) {
      _lastSelectedStudent = selectedStudent;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchTransactions();
      });
    }
    final baseTheme = Theme.of(context);
    final themed = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'Poppins'),
    );

    return Theme(
      data: themed,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppStyles.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Riwayat Uang Saku',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Tab Bar
            Container(
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
                tabs: const [
                  Tab(text: 'Pemasukan'),
                  Tab(text: 'Pengeluaran'),
                  Tab(text: 'Laporan'),
                ],
              ),
            ),
            // Filter Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.grey[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Semua',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _tabController.index == 0
                            ? _selectedSortOrderIn
                            : (_tabController.index == 1 ? _selectedSortOrderOut : _reportSortOrder),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _showFilterDialog,
                        child: Row(
                          children: [
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.tune,
                              size: 18,
                              color: AppStyles.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTransactionList(_getFilteredTransactions(incoming: true)),
                  _buildTransactionList(_getFilteredTransactions(incoming: false)),
                  _buildReportTab(), // Laporan dengan chart
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Report helpers =====
  String _formatRupiah(int value, {String prefix = 'Rp '}) {
    return '$prefix${NumberFormat.decimalPattern('id_ID').format(value)}';
  }

  ({DateTime start, DateTime end}) _reportRange() {
    final now = DateTime.now();
    // If explicit date range set from report filter, use it
    if (_reportStartDate != null && _reportEndDate != null) {
      return (start: _reportStartDate!, end: _reportEndDate!);
    }
    if (_selectedPeriod == 'Bulan Ini') {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return (start: start, end: end);
    } else if (_selectedPeriod == 'Bulan Lalu') {
      final prev = DateTime(now.year, now.month - 1, 1);
      final start = DateTime(prev.year, prev.month, 1);
      final end = DateTime(prev.year, prev.month + 1, 0, 23, 59, 59);
      return (start: start, end: end);
    } else {
      // 3 bulan terakhir termasuk bulan ini
      final threeAgo = DateTime(now.year, now.month - 2, 1);
      final start = DateTime(threeAgo.year, threeAgo.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return (start: start, end: end);
    }
  }

  List<PocketMoneyHistory> _reportFiltered({required bool incoming}) {
    final source = _apiTransactions.isNotEmpty ? _apiTransactions : _allTransactions;
    final range = _reportRange();
    final list = source.where((t) {
      final typeOk = incoming
          ? t.type == PocketMoneyTransactionType.incoming
          : t.type == PocketMoneyTransactionType.outgoing;
      final inRange = !t.date.isBefore(range.start) && !t.date.isAfter(range.end);
      return typeOk && inRange;
    }).toList();

    // Urutkan sesuai _reportSortOrder
    switch (_reportSortOrder) {
      case 'Terbaru':
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Terlama':
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Nominal Tertinggi':
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Nominal Terendah':
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  _Totals _computeTotals() {
    final incoming = _reportFiltered(incoming: true);
    final outgoing = _reportFiltered(incoming: false);
    final totalIn = incoming.fold<int>(0, (p, e) => p + e.amount);
    final totalOut = outgoing.fold<int>(0, (p, e) => p + e.amount);
    return _Totals(totalIn: totalIn, totalOut: totalOut);
  }

  Widget _buildTransactionList(List<PocketMoneyHistory> transactions) {
    if (_loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchTransactions, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchTransactions(),
      color: AppStyles.primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionItem(PocketMoneyHistory transaction) {
    final isTopUp = transaction.type == PocketMoneyTransactionType.incoming;
    final color = isTopUp ? AppStyles.primaryColor : Colors.pink[300];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailUangSakuPage(transaction: transaction),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isTopUp ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.bankName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(transaction.date),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isTopUp ? '+' : '-'}Rp${NumberFormat.decimalPattern('id_ID').format(transaction.amount)}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Filter
          Row(
            children: [
              _buildPeriodChip('Bulan Ini', _selectedPeriod == 'Bulan Ini'),
              const SizedBox(width: 8),
              _buildPeriodChip('Bulan Lalu', _selectedPeriod == 'Bulan Lalu'),
              const SizedBox(width: 8),
              _buildPeriodChip('3 Bulan', _selectedPeriod == '3 Bulan'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Period Label
          Text(
            _selectedPeriod,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Selisih',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final totals = _computeTotals();
                  return Text(
                    _formatRupiah(totals.selisihAbs, prefix: totals.selisih >= 0 ? 'Rp ' : '-Rp '),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppStyles.primaryColor,
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppStyles.primaryColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pemasukan',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Builder(builder: (context) {
                            final totals = _computeTotals();
                            return Text(
                              '+${_formatRupiah(totals.totalIn)}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppStyles.primaryColor,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.pink[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pengeluaran',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Builder(builder: (context) {
                            final totals = _computeTotals();
                            return Text(
                              '-${_formatRupiah(totals.totalOut)}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.pink[300],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Doughnut Chart
          SizedBox(
            height: 200,
            child: SfCircularChart(
              margin: EdgeInsets.zero,
              series: <CircularSeries>[
                DoughnutSeries<ChartData, String>(
                  dataSource: _getChartData(),
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.value,
                  pointColorMapper: (ChartData data, _) => data.color,
                  innerRadius: '70%',
                  radius: '90%',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: false,
                  ),
                ),
              ],
              annotations: <CircularChartAnnotation>[
                CircularChartAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(builder: (context) {
                        final totals = _computeTotals();
                        final pct = totals.percentOut;
                        return Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppStyles.primaryColor,
                          ),
                        );
                      }),
                      Text(
                        'Pengeluaran',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Category Sections
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Pemasukan';
                    });
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 2,
                        color: _selectedCategory == 'Pemasukan' ? AppStyles.primaryColor : Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: _selectedCategory == 'Pemasukan' ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedCategory == 'Pemasukan' ? AppStyles.primaryColor : Colors.grey[600],
                        ),
                        child: const Text('Pemasukan'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = 'Pengeluaran';
                    });
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 2,
                        color: _selectedCategory == 'Pengeluaran' ? AppStyles.primaryColor : Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: _selectedCategory == 'Pengeluaran' ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedCategory == 'Pengeluaran' ? AppStyles.primaryColor : Colors.grey[600],
                        ),
                        child: const Text('Pengeluaran'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Transaction List for Report
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey(_selectedCategory),
              children: (_selectedCategory == 'Pemasukan'
                      ? _reportFiltered(incoming: true).take(2)
                      : _reportFiltered(incoming: false).take(2))
                  .map((transaction) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildTransactionItem(transaction),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppStyles.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppStyles.primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final tabIndex = _tabController.index;
    final isIncomingTab = tabIndex == 0;
    final isOutgoingTab = tabIndex == 1;
    final isReportTab = tabIndex == 2;
    String tempSortOrder = isIncomingTab
        ? _selectedSortOrderIn
        : (isOutgoingTab ? _selectedSortOrderOut : _reportSortOrder);
    DateTime? tempStartDate = isIncomingTab
        ? _startDateIn
        : (isOutgoingTab ? _startDateOut : _reportStartDate);
    DateTime? tempEndDate = isIncomingTab
        ? _endDateIn
        : (isOutgoingTab ? _endDateOut : _reportEndDate);
    Map<String, bool> tempCategoryFilters = Map.from(
        isIncomingTab ? _categoryFiltersIn : _categoryFiltersOut);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryFilterWidget(
        selectedSortOrder: tempSortOrder,
        startDate: tempStartDate,
        endDate: tempEndDate,
        categoryFilters: isReportTab ? null : tempCategoryFilters,
        availableCategories: isReportTab
            ? null
            : (isIncomingTab ? _categoryFiltersIn : _categoryFiltersOut)
                .keys
                .toList(),
        onSortOrderChanged: (sortOrder) {
          tempSortOrder = sortOrder;
        },
        onStartDateChanged: (startDate) {
          tempStartDate = startDate;
        },
        onEndDateChanged: (endDate) {
          tempEndDate = endDate;
        },
        onCategoryFiltersChanged: isReportTab
            ? null
            : (categoryFilters) {
                tempCategoryFilters = categoryFilters;
              },
        onApply: () {
          setState(() {
            if (isIncomingTab) {
              _selectedSortOrderIn = tempSortOrder;
              _startDateIn = tempStartDate;
              _endDateIn = tempEndDate;
              _categoryFiltersIn
                ..clear()
                ..addAll(tempCategoryFilters);
            } else if (isOutgoingTab) {
              _selectedSortOrderOut = tempSortOrder;
              _startDateOut = tempStartDate;
              _endDateOut = tempEndDate;
              _categoryFiltersOut
                ..clear()
                ..addAll(tempCategoryFilters);
            } else {
              _reportSortOrder = tempSortOrder;
              _reportStartDate = tempStartDate;
              _reportEndDate = tempEndDate;
            }
          });
          // Tutup bottom sheet setelah filter diterapkan
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            if (isIncomingTab) {
              _selectedSortOrderIn = 'Terbaru';
              _startDateIn = null;
              _endDateIn = null;
              _categoryFiltersIn.updateAll((key, value) => true);
            } else if (isOutgoingTab) {
              _selectedSortOrderOut = 'Terbaru';
              _startDateOut = null;
              _endDateOut = null;
              _categoryFiltersOut.updateAll((key, value) => true);
            } else {
              _reportSortOrder = 'Terbaru';
              _reportStartDate = null;
              _reportEndDate = null;
            }
          });
        },
        title: 'Filter Riwayat Uang Saku',
      ),
    );
  }

  List<PocketMoneyHistory> _getFilteredTransactions({required bool incoming}) {
    // Use API data if available; fallback to dummy
    final source = _apiTransactions.isNotEmpty ? _apiTransactions : _allTransactions;
    // Start from type-specific slice
    List<PocketMoneyHistory> filtered = source
        .where((t) => incoming
            ? t.type == PocketMoneyTransactionType.incoming
            : t.type == PocketMoneyTransactionType.outgoing)
        .toList();

    // Filter by date range
    final DateTime? startDate = incoming ? _startDateIn : _startDateOut;
    final DateTime? endDate = incoming ? _endDateIn : _endDateOut;
    if (startDate != null || endDate != null) {
      filtered = filtered.where((transaction) {
        final transactionDate = transaction.date;

        if (startDate != null && endDate != null) {
          return transactionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              transactionDate.isBefore(endDate.add(const Duration(days: 1)));
        } else if (startDate != null) {
          return transactionDate.isAfter(startDate.subtract(const Duration(days: 1)));
        } else if (endDate != null) {
          return transactionDate.isBefore(endDate.add(const Duration(days: 1)));
        }

        return true;
      }).toList();
    }

    // Filter by category
    filtered = filtered.where((transaction) {
      String category = _getTransactionCategory(transaction);
      final cats = incoming ? _categoryFiltersIn : _categoryFiltersOut;
      return cats[category] == true;
    }).toList();

    // Sort by selected order
    final sortOrder = incoming ? _selectedSortOrderIn : _selectedSortOrderOut;
    switch (sortOrder) {
      case 'Terbaru':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Terlama':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Nominal Tertinggi':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Nominal Terendah':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return filtered;
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await _service.fetchTransactions(page: 1, limit: 100);
      // Sort desc by date to keep newest first
      final merged = <PocketMoneyHistory>[...list]..sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _apiTransactions = merged;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getTransactionCategory(PocketMoneyHistory transaction) {
    switch (transaction.type) {
      case PocketMoneyTransactionType.incoming:
        return 'Top Up';
      case PocketMoneyTransactionType.outgoing:
        if (transaction.title.toLowerCase().contains('pembelian')) {
          return 'Pembelian';
        }
        if (transaction.title.toLowerCase().contains('transfer')) {
          return 'Transfer';
        }
        if (transaction.title.toLowerCase().contains('penarikan')) {
          return 'Penarikan';
        }
        return 'Lainnya';
    }
  }

  List<ChartData> _getChartData() {
    final totals = _computeTotals();
    final total = (totals.totalIn + totals.totalOut).toDouble();
    final inPct = total == 0 ? 0.0 : (totals.totalIn / total) * 100.0;
    final outPct = total == 0 ? 0.0 : (totals.totalOut / total) * 100.0;
    return [
      ChartData('Pemasukan', inPct, AppStyles.primaryColor),
      ChartData('Pengeluaran', outPct, Colors.pink[300]!),
    ];
  }
}

class _Totals {
  _Totals({required this.totalIn, required this.totalOut})
      : selisih = totalIn - totalOut,
        selisihAbs = (totalIn - totalOut).abs(),
        percentOut = (totalIn + totalOut) == 0 ? 0 : (totalOut / (totalIn + totalOut)) * 100;
  final int totalIn;
  final int totalOut;
  final int selisih;
  final int selisihAbs;
  final double percentOut;
}

class ChartData {
  ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
}
