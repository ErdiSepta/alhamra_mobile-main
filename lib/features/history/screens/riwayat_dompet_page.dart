import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_styles.dart';
import '../../../core/models/wallet_history.dart';
import '../../../core/models/pocket_money_history.dart';
import '../../../core/data/pocket_money_service.dart';
import '../../../core/data/canteen_service.dart';
import '../../shared/widgets/index.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/providers/auth_provider.dart';
import 'detail_dompet_page.dart';

class RiwayatDompetPage extends StatefulWidget {
  const RiwayatDompetPage({super.key});

  @override
  State<RiwayatDompetPage> createState() => _RiwayatDompetPageState();
}

class _RiwayatDompetPageState extends State<RiwayatDompetPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final bool _showFilter = false;
  String _selectedPeriod = 'Bulan Ini';
  String _selectedCategory = 'Pemasukan';
  final TextEditingController _searchController = TextEditingController();
  
  // Filter state variables
  String _selectedSortOrder = 'Terbaru';
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Category filters for wallet transactions
  final Map<String, bool> _categoryFilters = {
    'Top Up': true,
    'Pembayaran': true,
    'Transfer': true,
  };

  final PocketMoneyService _pocketMoneyService = PocketMoneyService();
  final CanteenService _canteenService = CanteenService();
  bool _loading = false;
  String? _errorMessage;
  List<WalletHistory> _apiTransactions = [];
  String? _lastSelectedStudent;

  // Dummy data untuk riwayat dompet
  final List<WalletHistory> _allTransactions = [
    WalletHistory(
      id: 'DMP-001',
      title: 'Dana Masuk Dari',
      subtitle: 'Muhammad Ilham',
      amount: 1200000,
      date: DateTime(2025, 7, 22, 12, 9),
      type: WalletTransactionType.topup,
      bankName: 'Bank Mandiri',
    ),
    WalletHistory(
      id: 'DMP-002',
      title: 'Pembayaran SPP',
      subtitle: 'November 2024',
      amount: 350000,
      date: DateTime(2025, 7, 21, 14, 30),
      type: WalletTransactionType.payment,
      bankName: 'Bank Mandiri',
    ),
    WalletHistory(
      id: 'DMP-003',
      title: 'Dana Masuk Dari',
      subtitle: 'Muhammad Ilham',
      amount: 800000,
      date: DateTime(2025, 7, 20, 10, 15),
      type: WalletTransactionType.topup,
      bankName: 'Bank Mandiri',
    ),
    WalletHistory(
      id: 'DMP-004',
      title: 'Transfer ke Uang Saku',
      subtitle: 'Transfer internal',
      amount: 500000,
      date: DateTime(2025, 7, 19, 16, 45),
      type: WalletTransactionType.transfer,
      bankName: 'Bank Mandiri',
    ),
    WalletHistory(
      id: 'DMP-005',
      title: 'Biaya Makan',
      subtitle: 'Oktober 2024',
      amount: 450000,
      date: DateTime(2025, 7, 18, 14, 20),
      type: WalletTransactionType.payment,
      bankName: 'Bank Mandiri',
    ),
    WalletHistory(
      id: 'DMP-006',
      title: 'Dana Masuk Dari',
      subtitle: 'Muhammad Ilham',
      amount: 600000,
      date: DateTime(2025, 7, 17, 11, 10),
      type: WalletTransactionType.topup,
      bankName: 'Bank Mandiri',
    ),
    WalletHistory(
      id: 'DMP-007',
      title: 'Biaya Seragam',
      subtitle: 'September 2024',
      amount: 275000,
      date: DateTime(2025, 7, 16, 19, 30),
      type: WalletTransactionType.payment,
      bankName: 'Bank Mandiri',
    ),
    WalletHistory(
      id: 'DMP-008',
      title: 'Transfer ke Tabungan',
      subtitle: 'Transfer eksternal',
      amount: 300000,
      date: DateTime(2025, 7, 15, 9, 0),
      type: WalletTransactionType.transfer,
      bankName: 'Bank Mandiri',
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
    // Auto refetch when selected student changes globally
    String? selectedStudent;
    try {
      selectedStudent = context.watch<AuthProvider>().selectedStudent;
    } catch (_) {
      selectedStudent = null;
    }
    if (selectedStudent != null && selectedStudent.isNotEmpty && _lastSelectedStudent != selectedStudent) {
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
            'Riwayat Dompet',
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
            // Tab Bar (standardized like Riwayat Tagihan)
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
                        _selectedSortOrder,
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
                  _buildTransactionList(_getFilteredTransactions().where((t) => t.isPositive).toList()),
                  _buildTransactionList(_getFilteredTransactions().where((t) => !t.isPositive).toList()),
                  _buildReportTab(), // Laporan dengan chart
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<WalletHistory> transactions) {
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
            const SizedBox(height: 16),
            Text(
              'Tidak ada transaksi yang dapat ditampilkan.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTransactions,
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(WalletHistory transaction) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDompetPage(transaction: transaction),
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
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconForTransactionType(transaction.type),
              color: Colors.pink[300],
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
                  transaction.formattedDateTime,
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
            transaction.formattedAmount,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTransactionType(WalletTransactionType type) {
    switch (type) {
      case WalletTransactionType.topup:
        return Icons.add_circle_outline;
      case WalletTransactionType.payment:
        return Icons.payment_outlined;
      case WalletTransactionType.transfer:
        return Icons.swap_horiz_outlined;
      case WalletTransactionType.refund:
        return Icons.refresh_outlined;
    }
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
                Builder(
                  builder: (context) {
                    final totals = _computeTotals();
                    final prefix = totals.selisih >= 0 ? 'Rp ' : '-Rp ';
                    return Text(
                      _formatRupiah(totals.selisihAbs, prefix: prefix),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.primaryColor,
                      ),
                    );
                  },
                ),
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
                          Builder(
                            builder: (context) {
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
                            },
                          ),
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
                          Builder(
                            builder: (context) {
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
                            },
                          ),
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
                  dataLabelSettings: DataLabelSettings(
                    isVisible: false,
                  ),
                ),
              ],
              annotations: <CircularChartAnnotation>[
                CircularChartAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
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
                        },
                      ),
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
          const SizedBox(height: 16),
          
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
    String tempSortOrder = _selectedSortOrder;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    Map<String, bool> tempCategoryFilters = Map.from(_categoryFilters);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HistoryFilterWidget(
        selectedSortOrder: tempSortOrder,
        startDate: tempStartDate,
        endDate: tempEndDate,
        categoryFilters: tempCategoryFilters,
        availableCategories: _categoryFilters.keys.toList(),
        onSortOrderChanged: (sortOrder) {
          tempSortOrder = sortOrder;
        },
        onStartDateChanged: (startDate) {
          tempStartDate = startDate;
        },
        onEndDateChanged: (endDate) {
          tempEndDate = endDate;
        },
        onCategoryFiltersChanged: (categoryFilters) {
          tempCategoryFilters = categoryFilters;
        },
        onApply: () {
          setState(() {
            _selectedSortOrder = tempSortOrder;
            _startDate = tempStartDate;
            _endDate = tempEndDate;
            _categoryFilters.clear();
            _categoryFilters.addAll(tempCategoryFilters);
          });
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _selectedSortOrder = 'Terbaru';
            _startDate = null;
            _endDate = null;
            _categoryFilters.updateAll((key, value) => true);
          });
        },
        title: 'Filter Riwayat Dompet',
      ),
    );
  }

  List<WalletHistory> _getFilteredTransactions() {
    final source = _apiTransactions.isNotEmpty ? _apiTransactions : _allTransactions;
    List<WalletHistory> filtered = List.from(source);
    
    // Filter by date range
    if (_startDate != null || _endDate != null) {
      filtered = filtered.where((transaction) {
        final transactionDate = transaction.date;
        
        if (_startDate != null && _endDate != null) {
          return transactionDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                 transactionDate.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null) {
          return transactionDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
        } else if (_endDate != null) {
          return transactionDate.isBefore(_endDate!.add(const Duration(days: 1)));
        }
        
        return true;
      }).toList();
    }
    
    // Filter by category
    filtered = filtered.where((transaction) {
      String category = _getTransactionCategory(transaction);
      return _categoryFilters[category] == true;
    }).toList();
    
    // Sort by selected order
    if (_selectedSortOrder == 'Terbaru') {
      // Newest date first
      filtered.sort((a, b) => b.date.compareTo(a.date));
    } else if (_selectedSortOrder == 'Terlama') {
      // Oldest date first
      filtered.sort((a, b) => a.date.compareTo(b.date));
    } else if (_selectedSortOrder == 'Nominal Tertinggi') {
      // Highest amount first
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_selectedSortOrder == 'Nominal Terendah') {
      // Lowest amount first
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    } else {
      // Fallback: newest first
      filtered.sort((a, b) => b.date.compareTo(a.date));
    }
    
    return filtered;
  }

  String _getTransactionCategory(WalletHistory transaction) {
    switch (transaction.type) {
      case WalletTransactionType.topup:
        return 'Top Up';
      case WalletTransactionType.payment:
        return 'Pembayaran';
      case WalletTransactionType.transfer:
        return 'Transfer';
      default:
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

  String _formatRupiah(int value, {String prefix = 'Rp '}) {
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '$prefix${s.replaceAllMapped(reg, (m) => '.')}';
  }

  ({DateTime start, DateTime end}) _reportRange() {
    final now = DateTime.now();
    // Jika user sudah mengatur rentang tanggal melalui filter utama,
    // gunakan rentang itu juga untuk Laporan.
    if (_startDate != null && _endDate != null) {
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      return (start: start, end: end);
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

  List<WalletHistory> _reportFiltered({required bool incoming}) {
    final source = _apiTransactions.isNotEmpty ? _apiTransactions : _allTransactions;
    final range = _reportRange();
    final list = source.where((t) {
      final typeOk = incoming ? t.isPositive : !t.isPositive;
      final inRange = !t.date.isBefore(range.start) && !t.date.isAfter(range.end);
      if (!(typeOk && inRange)) return false;

      // Terapkan juga filter kategori seperti di _getFilteredTransactions
      final category = _getTransactionCategory(t);
      if (_categoryFilters[category] != true) return false;

      return true;
    }).toList();

    // Urutkan sesuai _selectedSortOrder
    if (_selectedSortOrder == 'Terbaru') {
      list.sort((a, b) => b.date.compareTo(a.date));
    } else if (_selectedSortOrder == 'Terlama') {
      list.sort((a, b) => a.date.compareTo(b.date));
    } else if (_selectedSortOrder == 'Nominal Tertinggi') {
      list.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_selectedSortOrder == 'Nominal Terendah') {
      list.sort((a, b) => a.amount.compareTo(b.amount));
    } else {
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

  Future<void> _fetchTransactions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      // 1) Ambil transaksi kantin sebagai pengeluaran dompet
      final canteen = await _canteenService.fetchCanteenTransactions(page: 1, limit: 100);
      final mappedCanteen = canteen.map<WalletHistory>((t) {
        return WalletHistory(
          id: t.id,
          title: 'Pembelian Kantin',
          subtitle: t.subtitle,
          amount: t.amount,
          date: t.date,
          type: WalletTransactionType.payment,
          description: t.description,
          bankName: 'Kantin',
        );
      }).toList();

      // 2) Ambil transaksi uang saku, pilih yang berkaitan dengan Wallet Recharge
      final pocket = await _pocketMoneyService.fetchTransactions(page: 1, limit: 100);
      final recharge = pocket.where((t) {
        final desc = (t.description ?? t.subtitle).toLowerCase();
        return desc.contains('wallet recharge');
      }).map<WalletHistory>((t) {
        return WalletHistory(
          id: 'WR-${t.id}',
          title: 'Wallet Recharge',
          subtitle: t.subtitle,
          amount: t.amount,
          date: t.date,
          type: WalletTransactionType.topup,
          description: t.description,
          bankName: 'Uang Saku',
        );
      }).toList();

      // Gunakan hanya data nyata (kantin + wallet recharge) untuk API list.
      // _allTransactions hanya dipakai sebagai fallback saat API belum tersedia.
      final merged = <WalletHistory>[...mappedCanteen, ...recharge]
        ..sort((a, b) => b.date.compareTo(a.date));

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
}

class ChartData {
  ChartData(this.category, this.value, this.color);
  final String category;
  final double value;
  final Color color;
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
