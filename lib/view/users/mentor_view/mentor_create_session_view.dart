import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/viewmodel/controller/mentor/mentor_session_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorCreateSessionView extends StatefulWidget {
  const MentorCreateSessionView({super.key});

  @override
  State<MentorCreateSessionView> createState() => _MentorCreateSessionViewState();
}

class _MentorCreateSessionViewState extends State<MentorCreateSessionView> {
  // Shared
  bool _isGroup = false;
  final _topicController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // 1-on-1 specific
  final _studentIdController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  // Group specific
  final _descriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _priceController = TextEditingController();
  int? _selectedDuration; // 30 / 60 / 90

  @override
  void dispose() {
    _topicController.dispose();
    _studentIdController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    _maxParticipantsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColor.red, surface: AppColor.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColor.red, surface: AppColor.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submit() {
    final topic = _topicController.text.trim();

    if (topic.isEmpty) {
      _snack('Please enter a session topic');
      return;
    }
    if (_selectedDate == null) {
      _snack('Please select a date');
      return;
    }
    if (_selectedTime == null) {
      _snack('Please select a time');
      return;
    }

    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final vm = Get.find<MentorSessionViewmodel>();

    if (_isGroup) {
      // --- Group session ---
      if (_selectedDuration == null) {
        _snack('Please select a duration');
        return;
      }
      final maxText = _maxParticipantsController.text.trim();
      final priceText = _priceController.text.trim();
      if (maxText.isEmpty) {
        _snack('Please enter max participants');
        return;
      }
      final maxParticipants = int.tryParse(maxText);
      if (maxParticipants == null || maxParticipants < 2 || maxParticipants > 20) {
        _snack('Max participants must be between 2 and 20');
        return;
      }
      if (priceText.isEmpty) {
        _snack('Please enter a price per seat');
        return;
      }
      final price = double.tryParse(priceText);
      if (price == null || price < 0) {
        _snack('Price must be a valid number');
        return;
      }

      final data = <String, dynamic>{
        'sessionType': 'group',
        'topic': topic,
        'dateTime': dt.toIso8601String(),
        'duration': _selectedDuration,
        'maxParticipants': maxParticipants,
        'price': price,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
      };

      vm.createSession(data, onSuccess: () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      // --- 1-on-1 session ---
      final studentId = _studentIdController.text.trim();
      final durationText = _durationController.text.trim();

      if (studentId.isEmpty) {
        _snack('Please enter the student ID');
        return;
      }
      if (durationText.isEmpty) {
        _snack('Please enter duration');
        return;
      }
      final duration = int.tryParse(durationText);
      if (duration == null || duration <= 0) {
        _snack('Duration must be a positive number');
        return;
      }

      final data = <String, dynamic>{
        'sessionType': '1on1',
        'topic': topic,
        'studentId': studentId,
        'dateTime': dt.toIso8601String(),
        'duration': duration,
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };

      vm.createSession(data, onSuccess: () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final vm = Get.find<MentorSessionViewmodel>();

    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.padding(left: 2, right: 2, top: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  ),
                  SizedBox(width: Responsive.w(2)),
                  Text(
                    'Create Session',
                    style: GoogleFonts.rethinkSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),

              // 1-on-1 / Group toggle
              _buildSessionTypeToggle(),
              SizedBox(height: Responsive.h(2)),

              // Topic field (shared)
              _field("Session Topic", controller: _topicController),
              SizedBox(height: Responsive.h(1.5)),

              // Mode-specific fields
              if (_isGroup) ..._buildGroupFields(context) else ..._build1on1Fields(context),

              SizedBox(height: Responsive.h(3)),
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: vm.isCreating.value ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: vm.isCreating.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isGroup ? 'Create Group Session' : 'Create Session',
                          style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              )),
              SizedBox(height: Responsive.h(2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTypeToggle() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _toggleOption('1-on-1', !_isGroup),
          _toggleOption('Group', _isGroup),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isGroup = label == 'Group'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? AppColor.red : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _build1on1Fields(BuildContext context) {
    return [
      _field("Student ID", controller: _studentIdController),
      SizedBox(height: Responsive.h(1.5)),
      _dateTimeRow(context),
      SizedBox(height: Responsive.h(1.5)),
      _field("Duration (minutes)", controller: _durationController, keyboardType: TextInputType.number),
      SizedBox(height: Responsive.h(1.5)),
      TextFormField(
        controller: _notesController,
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        decoration: _inputDecoration("Notes (optional)"),
      ),
    ];
  }

  List<Widget> _buildGroupFields(BuildContext context) {
    return [
      TextFormField(
        controller: _descriptionController,
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        decoration: _inputDecoration("Description (optional)"),
      ),
      SizedBox(height: Responsive.h(1.5)),
      _field(
        "Max Participants (2–20)",
        controller: _maxParticipantsController,
        keyboardType: TextInputType.number,
      ),
      SizedBox(height: Responsive.h(1.5)),
      _dateTimeRow(context),
      SizedBox(height: Responsive.h(1.5)),
      _durationSelector(),
      SizedBox(height: Responsive.h(1.5)),
      _field(
        "Price per Seat (\$)",
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  Widget _dateTimeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickDate,
            child: _displayField(
              _selectedDate == null
                  ? "Select Date"
                  : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              Icons.calendar_today,
            ),
          ),
        ),
        SizedBox(width: Responsive.w(3)),
        Expanded(
          child: GestureDetector(
            onTap: _pickTime,
            child: _displayField(
              _selectedTime == null
                  ? "Select Time"
                  : _selectedTime!.format(context),
              Icons.access_time,
            ),
          ),
        ),
      ],
    );
  }

  Widget _durationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Duration",
          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [30, 60, 90].map((mins) {
            final selected = _selectedDuration == mins;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDuration = mins),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColor.red : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: selected ? AppColor.red : AppColor.primaryColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${mins}min',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _field(String hint, {required TextEditingController controller, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      decoration: _inputDecoration(hint),
    );
  }

  Widget _displayField(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColor.primaryColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.primaryColor),
          borderRadius: BorderRadius.circular(28),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.focusedBorder),
          borderRadius: BorderRadius.circular(28),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.red),
          borderRadius: BorderRadius.circular(28),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColor.primaryColor),
          borderRadius: BorderRadius.circular(28),
        ),
      );
}
