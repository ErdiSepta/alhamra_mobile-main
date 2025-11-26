import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_styles.dart';

class HistoryFilterWidget extends StatefulWidget {
  final String selectedSortOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, bool>? categoryFilters;
  final List<String>? availableCategories;
  final Function(String) onSortOrderChanged;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Function(Map<String, bool>)? onCategoryFiltersChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;
  final String title;

  const HistoryFilterWidget({
    super.key,
    required this.selectedSortOrder,
    this.startDate,
    this.endDate,
    this.categoryFilters,
    this.availableCategories,
    required this.onSortOrderChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.onCategoryFiltersChanged,
    required this.onReset,
    required this.onApply,
    this.title = 'Filter & Urutkan',
  });

  @override
  State<HistoryFilterWidget> createState() => _HistoryFilterWidgetState();
}

class _HistoryFilterWidgetState extends State<HistoryFilterWidget> {
  late String _tempSortOrder;
  late DateTime? _tempStartDate;
  late DateTime? _tempEndDate;
  late Map<String, bool> _tempCategoryFilters;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _tempSortOrder = widget.selectedSortOrder;
    _tempStartDate = widget.startDate;
    _tempEndDate = widget.endDate;
    _tempCategoryFilters = Map.from(widget.categoryFilters ?? {});
    _validateDateRange();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort Order Section
                  Text(
                    'Urutkan',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _buildSortButton('Terbaru'),
                      const SizedBox(height: 8),
                      _buildSortButton('Terlama'),
                      const SizedBox(height: 8),
                      _buildSortButton('Nominal Tertinggi'),
                      const SizedBox(height: 8),
                      _buildSortButton('Nominal Terendah'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Date Range Section
                  Text(
                    'Rentang Tanggal',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Preset chips
                  Row(
                    children: [
                      _buildPresetChip('Bulan Ini', _isCurrentPreset('Bulan Ini')),
                      const SizedBox(width: 8),
                      _buildPresetChip('Bulan Lalu', _isCurrentPreset('Bulan Lalu')),
                      const SizedBox(width: 8),
                      _buildPresetChip('3 Bulan', _isCurrentPreset('3 Bulan')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateButton(
                          'Tanggal Mulai',
                          _tempStartDate,
                          (date) => setState(() => _tempStartDate = date),
                          onClear: () => setState(() => _tempStartDate = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateButton(
                          'Tanggal Akhir',
                          _tempEndDate,
                          (date) => setState(() => _tempEndDate = date),
                          onClear: () => setState(() => _tempEndDate = null),
                        ),
                      ),
                    ],
                  ),
                  if (_dateError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _dateError!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Category Filters Section (if available)
                  if (widget.availableCategories != null && widget.availableCategories!.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kategori',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final allSelected = _tempCategoryFilters.values.every((selected) => selected);
                            setState(() {
                              for (String category in widget.availableCategories!) {
                                _tempCategoryFilters[category] = !allSelected;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppStyles.primaryColor.withOpacity(0.3)),
                            ),
                            child: Text(
                              _tempCategoryFilters.values.every((selected) => selected) 
                                  ? 'Hapus Semua' 
                                  : 'Pilih Semua',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppStyles.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: widget.availableCategories!.map((category) => 
                        CheckboxListTile(
                          title: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: _tempCategoryFilters[category] ?? true,
                          onChanged: (value) {
                            setState(() {
                              _tempCategoryFilters[category] = value ?? false;
                            });
                          },
                          activeColor: AppStyles.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _tempSortOrder = 'Terbaru';
                        _tempStartDate = null;
                        _tempEndDate = null;
                        if (widget.availableCategories != null) {
                          _tempCategoryFilters = { for (var e in widget.availableCategories!) e : true };
                        }
                      });
                      widget.onReset();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppStyles.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Atur Ulang',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDateRangeValid()
                        ? () {
                      widget.onSortOrderChanged(_tempSortOrder);
                      widget.onStartDateChanged(_tempStartDate);
                      widget.onEndDateChanged(_tempEndDate);
                      if (widget.onCategoryFiltersChanged != null) {
                        widget.onCategoryFiltersChanged!(_tempCategoryFilters);
                      }
                      widget.onApply();
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Terapkan',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Date validation helpers
  bool _isDateRangeValid() {
    if (_tempStartDate != null && _tempEndDate != null) {
      return !_tempStartDate!.isAfter(_tempEndDate!);
    }
    return true;
  }

  void _validateDateRange() {
    setState(() {
      if (_tempStartDate != null && _tempEndDate != null && _tempStartDate!.isAfter(_tempEndDate!)) {
        _dateError = 'Tanggal Mulai tidak boleh setelah Tanggal Akhir';
      } else {
        _dateError = null;
      }
    });
  }

  Widget _buildSortButton(String label) {
    final isSelected = _tempSortOrder == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempSortOrder = label;
        });
      },
      child: Container(
        width: double.infinity,
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

  Widget _buildDateButton(String label, DateTime? date, Function(DateTime) onDateSelected, {VoidCallback? onClear}) {
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
          _validateDateRange();
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
              child: Icon(Icons.calendar_today, size: 18, color: AppStyles.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  const SizedBox(height: 2),
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
            if (date != null && onClear != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  onClear();
                  _validateDateRange();
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.black54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // Preset helpers
  bool _isCurrentPreset(String label) {
    if (_tempStartDate == null || _tempEndDate == null) return false;
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    if (label == 'Bulan Ini') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    } else if (label == 'Bulan Lalu') {
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      start = DateTime(prevMonth.year, prevMonth.month, 1);
      end = DateTime(prevMonth.year, prevMonth.month + 1, 0);
    } else {
      // 3 Bulan terakhir (termasuk bulan ini)
      final threeAgo = DateTime(now.year, now.month - 2, 1);
      start = DateTime(threeAgo.year, threeAgo.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    }
    return _sameDate(start, _tempStartDate!) && _sameDate(end, _tempEndDate!);
  }

  bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildPresetChip(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        DateTime start;
        DateTime end;
        if (label == 'Bulan Ini') {
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0);
        } else if (label == 'Bulan Lalu') {
          final prevMonth = DateTime(now.year, now.month - 1, 1);
          start = DateTime(prevMonth.year, prevMonth.month, 1);
          end = DateTime(prevMonth.year, prevMonth.month + 1, 0);
        } else {
          final threeAgo = DateTime(now.year, now.month - 2, 1);
          start = DateTime(threeAgo.year, threeAgo.month, 1);
          end = DateTime(now.year, now.month + 1, 0);
        }
        setState(() {
          _tempStartDate = start;
          _tempEndDate = end;
        });
        _validateDateRange();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppStyles.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppStyles.primaryColor : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

// Filter Button Widget for consistent filter button UI
class FilterButtonWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasActiveFilters;

  const FilterButtonWidget({
    super.key,
    required this.onTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: hasActiveFilters ? AppStyles.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActiveFilters ? AppStyles.primaryColor : Colors.grey[400]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              color: hasActiveFilters ? AppStyles.primaryColor : Colors.grey[600],
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasActiveFilters ? AppStyles.primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
