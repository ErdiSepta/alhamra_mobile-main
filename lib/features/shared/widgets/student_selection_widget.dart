import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/data/student_data.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/auth_provider.dart';
import 'search_overlay_widget.dart';
import 'student_selector_widget.dart';

/// A complete student selection widget that handles both the selector and overlay
/// This widget can be easily used in any page that needs student selection functionality
class StudentSelectionWidget extends StatefulWidget {
  final String selectedStudent;
  final List<String> students;
  final Function(String) onStudentChanged;
  final String? avatarUrl;
  final String? buttonText;
  final IconData buttonIcon;
  final String? overlayTitle;
  final String? searchHint;
  final Function(bool)? onOverlayVisibilityChanged;
  final bool syncWithGlobalSelection;

  const StudentSelectionWidget({
    super.key,
    required this.selectedStudent,
    required this.students,
    required this.onStudentChanged,
    this.avatarUrl,
    this.buttonText,
    this.buttonIcon = Icons.swap_horiz,
    this.overlayTitle,
    this.searchHint,
    this.onOverlayVisibilityChanged,
    this.syncWithGlobalSelection = true,
  });

  @override
  State<StudentSelectionWidget> createState() => _StudentSelectionWidgetState();
}

class _StudentSelectionWidgetState extends State<StudentSelectionWidget> {
  bool _isOverlayVisible = false;
  String? _lastSyncedStudent;

  void _toggleOverlay() {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
    });
    widget.onOverlayVisibilityChanged?.call(_isOverlayVisible);
  }

  void _onStudentSelected(String student) {
    setState(() {
      _isOverlayVisible = false;
    });
    try {
      Provider.of<AuthProvider>(context, listen: false).selectStudent(student);
    } catch (_) {}
    widget.onStudentChanged(student);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.syncWithGlobalSelection) {
      String? providerStudent;
      try {
        providerStudent = context.watch<AuthProvider>().selectedStudent;
      } catch (_) {
        providerStudent = null;
      }
      if (providerStudent != null && _lastSyncedStudent != providerStudent) {
        _lastSyncedStudent = providerStudent;
        if (widget.selectedStudent != providerStudent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.onStudentChanged(providerStudent!);
          });
        }
      }
    }

    final localizations = AppLocalizations.of(context);
    return StudentSelectorWidget(
      selectedStudent: widget.selectedStudent,
      onTap: _toggleOverlay,
      avatarUrl: widget.avatarUrl,
      buttonText: widget.buttonText ?? localizations.ganti,
      buttonIcon: widget.buttonIcon,
    );
  }
  
  Widget buildOverlay() {
    final localizations = AppLocalizations.of(context);
    return SearchOverlayWidget(
      isVisible: _isOverlayVisible,
      title: widget.overlayTitle ?? localizations.pilihSantri,
      items: widget.students,
      selectedItem: widget.selectedStudent,
      onItemSelected: _onStudentSelected,
      onClose: _toggleOverlay,
      searchHint: widget.searchHint ?? localizations.cariSantri,
      avatarUrl: widget.avatarUrl,
    );
  }
}

/// A simplified version that provides default values for common use cases
class DefaultStudentSelectionWidget extends StatelessWidget {
  final String selectedStudent;
  final Function(String) onStudentChanged;
  final String? avatarUrl;

  // Import centralized student data
  static const List<String> defaultStudents = StudentData.allStudents;

  // Default avatar URL
  static const String defaultAvatarUrl = StudentData.defaultAvatarUrl;

  const DefaultStudentSelectionWidget({
    super.key,
    required this.selectedStudent,
    required this.onStudentChanged,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return StudentSelectionWidget(
      selectedStudent: selectedStudent,
      students: defaultStudents,
      onStudentChanged: onStudentChanged,
      avatarUrl: avatarUrl ?? defaultAvatarUrl,
    );
  }
}
