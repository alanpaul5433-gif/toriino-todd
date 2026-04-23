import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';

class ExpertiseSelectionWidget extends StatefulWidget {
  final List<String> initialExpertise;
  final ValueChanged<List<String>> onExpertiseChanged;

  const ExpertiseSelectionWidget({
   super.key,
    this.initialExpertise = const [],
    required this.onExpertiseChanged,
  }) ;

  @override
  ExpertiseSelectionWidgetState createState() =>
      ExpertiseSelectionWidgetState();
}

class ExpertiseSelectionWidgetState extends State<ExpertiseSelectionWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _expertiseList = [];

  @override
  void initState() {
    super.initState();
    _expertiseList = List.from(widget.initialExpertise);
  }

  void _addExpertise(String expertise) {
    if (expertise.isNotEmpty && !_expertiseList.contains(expertise)) {
      setState(() {
        _expertiseList.add(expertise);
        _textController.clear();
      });
      widget.onExpertiseChanged(_expertiseList);
    }
  }

  void _removeExpertise(String expertise) {
    setState(() {
      _expertiseList.remove(expertise);
    });
    widget.onExpertiseChanged(_expertiseList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field for adding new expertise
        TextFormField(
          controller: _textController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            hintText: 'Add Expertise',
            filled: true,
            fillColor: AppColor.white.withValues(alpha:  0.08),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: Colors.red),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SvgPicture.asset(
                'assets/icons/mentoring.svg',
                width: 24,
                height: 24,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: AppColor.white),
              onPressed: () => _addExpertise(_textController.text.trim()),
            ),
          ),
          style: TextStyle(color: AppColor.white),
          onFieldSubmitted: (value) => _addExpertise(value.trim()),
        ),

        SizedBox(height: 16),

        // Display selected expertise as chips
        if (_expertiseList.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _expertiseList.map((expertise) {
                  return Chip(
                    label: Text(
                      expertise,
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColor.red,
                    deleteIcon: Icon(
                      Icons.close,
                      size: Responsive.textScaleFactor * 16,
                      color: AppColor.white,
                    ),
                    onDeleted: () => _removeExpertise(expertise),
                  );
                }).toList(),
          ),
      ],
    );
  }
}
