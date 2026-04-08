import 'package:flutter/material.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';

class SortByDropdown extends StatefulWidget {
  const SortByDropdown({super.key});

  @override
  State<SortByDropdown> createState() => _SortByDropdownState();
}

class _SortByDropdownState extends State<SortByDropdown> {
  String selectedValue = 'Monthly';

  final List<String> sortOptions = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sort by: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        DropdownButton<String>(
          value: selectedValue,
          underline: Container(), // Remove default underline
          icon: Icon(Icons.arrow_drop_down, color: AppColor.red),
          style: TextStyle(
            color: AppColor.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (String? newValue) {
            setState(() {
              selectedValue = newValue!;
            });
          },
          items:
              sortOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
        ),
      ],
    );
  }
}
