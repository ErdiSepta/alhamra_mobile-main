import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/data/student_data.dart';
import '../../../core/models/absensi_model.dart';
import '../../../core/utils/app_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../shared/widgets/index.dart';
import '../../shared/widgets/student_selection_widget.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  // --- State Management ---
  late Map<String, AttendanceData> _allAttendanceData;
  late AttendanceData _selectedAttendance;
  String _selectedStudentName = StudentData.defaultStudent;
  bool _isStudentOverlayVisible = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  AttendanceDetail? _selectedAttendanceDetail;

  @override
  void initState() {
    super.initState();
    _generateMockData();
    _updateSelectedData();
    _selectedDay = DateTime.utc(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _selectedAttendanceDetail =
        _selectedAttendance.dailyStatus[_selectedDay!];
  }

  void _generateMockData() {
    _allAttendanceData = {
      for (var student in StudentData.allStudents)
        student: AttendanceData.createMock(
            (StudentData.allStudents.indexOf(student) + 1).toString())
    };
  }

  void _updateSelectedData() {
    _selectedAttendance = _allAttendanceData[_selectedStudentName]!;
    if (_selectedDay != null) {
      _selectedAttendanceDetail =
          _selectedAttendance.dailyStatus[_selectedDay!];
    }
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      appBar: CustomAppBar(
        title: 'Absensi',
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
                  child: _buildAttendanceDetails(),
                ),
              ),
            ],
          ),
          if (_isStudentOverlayVisible)
            SearchOverlayWidget(
              isVisible: _isStudentOverlayVisible,
              title: AppLocalizations.of(context).pilihSantri,
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
              searchHint: AppLocalizations.of(context).cariSantri,
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

  Widget _buildAttendanceDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCard(),
          const SizedBox(height: 24),
          _buildCalendarCard(),
          const SizedBox(height: 16),
          _buildSelectedDayDetailCard(),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return CustomCardWidget(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistika Keseluruhan', style: AppStyles.sectionTitle(context)),
          const SizedBox(height: 8),
          Text(
            'Selasa, 08:50 - 10:30 WIB (K-1 H.21)', // Mock data
            style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: _selectedAttendance.attendancePercentage / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppStyles.primaryColor),
                    ),
                    Center(
                      child: Text(
                        '${_selectedAttendance.attendancePercentage.toInt()}%',
                        style: AppStyles.bodyText(context)
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Alpa', _selectedAttendance.alphaCount, Colors.red),
                    _buildStatItem('Izin', _selectedAttendance.izinCount, Colors.orange),
                    _buildStatItem('Hadir', _selectedAttendance.hadirCount, Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${count}x',
          style: AppStyles.heading2(context).copyWith(color: color, fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return CustomCardWidget(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        locale: 'id_ID',
        calendarFormat: CalendarFormat.month,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppStyles.sectionTitle(context),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppStyles.primaryColor.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppStyles.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
            _focusedDay = focusedDay; // update `_focusedDay` here as well
            _selectedAttendanceDetail =
                _selectedAttendance.dailyStatus[_selectedDay!];
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final attendanceDetail = _selectedAttendance.dailyStatus[date];
            if (attendanceDetail != null) {
              Color markerColor;
              switch (attendanceDetail.status) {
                case AttendanceStatus.hadir:
                  markerColor = Colors.green;
                  break;
                case AttendanceStatus.izin:
                  markerColor = Colors.orange;
                  break;
                case AttendanceStatus.alpa:
                  markerColor = Colors.red;
                  break;
                default:
                  return null;
              }
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetailCard() {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }

    final detail = _selectedAttendanceDetail;
    final localizations = AppLocalizations.of(context);

    String statusText;
    Color statusColor;

    if (detail == null) {
      statusText = localizations.tidakAdaData;
      statusColor = Colors.grey;
    } else {
      switch (detail.status) {
        case AttendanceStatus.hadir:
          statusText = 'Hadir';
          statusColor = Colors.green;
          break;
        case AttendanceStatus.izin:
          statusText = 'Izin';
          statusColor = Colors.orange;
          break;
        case AttendanceStatus.alpa:
          statusText = 'Alpa';
          statusColor = Colors.red;
          break;
        case AttendanceStatus.libur:
          statusText = 'Libur';
          statusColor = Colors.blue;
          break;
      }
    }

    return CustomCardWidget(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedDay!.day.toString().padLeft(2, '0')}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.year}',
            style: AppStyles.sectionTitle(context),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: AppStyles.bodyText(context).copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (detail != null &&
              detail.reason != null &&
              detail.reason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              detail.status == AttendanceStatus.izin
                  ? localizations.alasanIzin
                  : detail.status == AttendanceStatus.alpa
                      ? localizations.keteranganAlpa
                      : localizations.tidakAdaData,
              style: AppStyles.bodyText(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.reason!,
              style: AppStyles.bodyText(context),
            ),
          ],
        ],
      ),
    );
  }
}
