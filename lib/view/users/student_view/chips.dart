import 'package:flutter/material.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';

class ChipSelection extends StatefulWidget {
  const ChipSelection({super.key});

  @override
  ChipSelectionState createState() => ChipSelectionState();
}

class ChipSelectionState extends State<ChipSelection> {
  int _selectedIndex = 0;
  final List<String> _chipLabels = ['All', 'Payment', 'Booking'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:AppColor.primaryColor,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_chipLabels.length, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: _selectedIndex == index 
                      ? AppColor.red
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _chipLabels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _selectedIndex == index 
                        ? Colors.white 
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}