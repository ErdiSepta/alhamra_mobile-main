import 'package:flutter/material.dart';

import '../../../core/data/student_data.dart';
import '../../../core/models/nilai_model.dart';
import '../../../core/utils/app_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../shared/widgets/index.dart';
import '../../shared/widgets/student_selection_widget.dart';
import 'nilai_detail_page.dart';

class NilaiPage extends StatefulWidget {
  const NilaiPage({super.key});
  @override
  State<NilaiPage> createState() => _NilaiPageState();
}

class _NilaiPageState extends State<NilaiPage> {
  // --- State Management ---
  late Map<String, StudentGradeProfile> _allGradeData;
  late StudentGradeProfile _selectedProfile;
  String _selectedStudentName = StudentData.defaultStudent;
  bool _isStudentOverlayVisible = false;

  // --- Filter State ---
  String? _selectedTahunAjaran;
  String? _selectedKelas;
  String? _selectedSemester;

  // Mock filter options
  final List<String> _tahunAjaranOptions = ['2023/2024', '2022/2023', '2021/2022'];
  final List<String> _kelasOptions = ['IX 9', 'IX 8', 'VIII 7'];
  final List<String> _semesterOptions = ['Ganjil', 'Genap'];

  @override
  void initState() {
    super.initState();
    _generateMockData();
    _updateSelectedData();
    // Initialize filters with default values
    _selectedTahunAjaran = _tahunAjaranOptions.first;
    _selectedKelas = _kelasOptions.first;
    _selectedSemester = _semesterOptions.first;
  }

  void _generateMockData() {
    _allGradeData = {
      for (var student in StudentData.allStudents)
        student: StudentGradeProfile.createMock(
            (StudentData.allStudents.indexOf(student) + 1).toString(), student)
    };
  }

  void _updateSelectedData() {
    _selectedProfile = _allGradeData[_selectedStudentName]!;
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      appBar: CustomAppBar(
        title: 'Nilai Santri',
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
                  child: _buildNilaiDetails(),
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

  Widget _buildNilaiDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataDiriCard(),
          const SizedBox(height: 24),
          _buildMataPelajaranList(),
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
          _buildDetailRow('Nama Lengkap', _selectedProfile.namaLengkap),
          const Divider(height: 24),
          _buildDetailRow('Nama Panggilan', _selectedProfile.namaPanggilan),
          const Divider(height: 24),
          _buildDetailRow('Tempat, Tanggal Lahir',
              '${_selectedProfile.tempatLahir}, ${_selectedProfile.tanggalLahir}'),
          const Divider(height: 24),
          _buildDetailRow('Kelas', _selectedProfile.kelas),
          const Divider(height: 24),
          _buildDetailRow('Jenis Kelamin', _selectedProfile.jenisKelamin),
        ],
      ),
    );
  }

  Widget _buildMataPelajaranList() {
    final diniyahSubjects = _selectedProfile.subjects
        .where((s) => s.category == SubjectCategory.diniyah)
        .toList();
    final umumSubjects = _selectedProfile.subjects
        .where((s) => s.category == SubjectCategory.umum)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Daftar Mata Pelajaran',
                style: AppStyles.sectionTitle(context)
                    .copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () {
                _showFilterBottomSheet();
              },
              icon: const Icon(Icons.filter_list, size: 20),
              label: const Text('Filter'),
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSubjectCategory('Diniyah (Keagamaan)', diniyahSubjects),
        const SizedBox(height: 24),
        _buildSubjectCategory('Umum', umumSubjects),
      ],
    );
  }

  Widget _buildSubjectCategory(String title, List<Subject> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppStyles.sectionTitle(context)
                .copyWith(color: AppStyles.darkGreyColor)),
        const SizedBox(height: 8),
        CustomCardWidget(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: subjects.map((subject) {
              return Column(
                children: [
                  ListTile(
                    title: Text(subject.name, style: AppStyles.bodyText(context)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => NilaiDetailPage(
                            subject: subject, studentName: _selectedProfile.namaLengkap),
                      ));
                    },
                  ),
                  if (subjects.last != subject)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppStyles.bodyText(context).copyWith(color: Colors.grey[600])),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppStyles.bodyText(context)
                .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet() {
    // Temporary state for the bottom sheet
    String? tempTahun = _selectedTahunAjaran;
    String? tempKelas = _selectedKelas;
    String? tempSemester = _selectedSemester;

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
                  Text('Filter Nilai', style: AppStyles.heading2(context)),
                  const SizedBox(height: 24),
                  _buildDropdown('Tahun Ajaran', tempTahun, _tahunAjaranOptions, (value) {
                    setModalState(() => tempTahun = value);
                  }),
                  const SizedBox(height: 16),
                  _buildDropdown('Kelas', tempKelas, _kelasOptions, (value) {
                    setModalState(() => tempKelas = value);
                  }),
                  const SizedBox(height: 16),
                  _buildDropdown('Semester', tempSemester, _semesterOptions, (value) {
                    setModalState(() => tempSemester = value);
                  }),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempTahun = _tahunAjaranOptions.first;
                              tempKelas = _kelasOptions.first;
                              tempSemester = _semesterOptions.first;
                            });
                          },
                          child: const Text('Reset'),
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
                              _selectedTahunAjaran = tempTahun;
                              _selectedKelas = tempKelas;
                              _selectedSemester = tempSemester;
                            });
                            Navigator.pop(context);
                            // TODO: Add logic to re-fetch or filter data based on new selections
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

  Widget _buildDropdown(String label, String? selectedValue, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue, 
      items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}