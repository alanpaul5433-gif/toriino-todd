import 'dart:ui';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/widgets/components/starrating.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // ignore: prefer_final_fields
  String _selectedDuration = '1 h';
  String _selectedLanguage = 'English';
  String _selectedCategory = 'All';
  String _selectedLevel = 'Beginner';
  double _rating = 4.0;
  RangeValues _priceRange = const RangeValues(0, 100);
  double _minPrice = 0;
  double _maxPrice = 100;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // color: Colors.white,
          gradient: LinearGradient(
            begin: AlignmentGeometry.topLeft,
            end: AlignmentGeometry.bottomRight,
            colors: [
              AppColor.white.withValues(alpha: 0.3),
              AppColor.white.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    color: AppColor.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColor.white),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration Section
                    _buildSectionHeader('Duration'),
                    const SizedBox(height: 10),
                    _buildDurationOptions(),
                    const SizedBox(height: 20),

                    // Language Section
                    _buildSectionHeader('Language'),
                    const SizedBox(height: 10),
                    _buildLanguageDropdown(),
                    const SizedBox(height: 20),

                    // Course Category Section
                    _buildSectionHeader('Course Category'),
                    const SizedBox(height: 10),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 20),

                    // Course Level Section
                    _buildSectionHeader('Course Level'),
                    const SizedBox(height: 10),
                    _buildLevelDropdown(),
                    const SizedBox(height: 20),

                    // Ratings Section
                    _buildSectionHeader('Ratings'),
                    const SizedBox(height: 10),
                    _buildRatingSlider(),
                    const SizedBox(height: 20),

                    // Price Range Section
                    _buildSectionHeader('Price Range'),
                    const SizedBox(height: 10),
                    _buildPriceRangeSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Apply Button
            GestureDetector(
              onTap: () {
                // Apply filters logic here
                _applyFilters();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.red,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Apply',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.20,
                    ),
                  ),
                ),

                //  ElevatedButton(
                // onPressed: () {
                //   // Apply filters logic here
                //   _applyFilters();
                //   Navigator.pop(context);
                // },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor:
                //        AppColor.red, // Use your AppColor.primaryColor
                //     padding: const EdgeInsets.symmetric(vertical: 15),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //   ),
                //   child: const Text(
                //     'Apply',
                //     style: GoogleFonts.dmSans(
                //       color: Colors.white,
                //       fontSize: 16,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 16,
        color: AppColor.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDurationOptions() {
    // final durations = ['1 h', '7 h', '10 h'];

    return
    // Row(
    //   children:
    //       durations.map((duration) {
    //         return Expanded(
    //           child: Padding(
    //             padding: const EdgeInsets.only(right: 10),
    //             child: FilterChip(
    //               backgroundColor: AppColor.white,
    //               selected: _selectedDuration == duration,
    //               label: Text(duration),
    //               onSelected: (selected) {
    //                 setState(() {
    //                   _selectedDuration = duration;
    //                 });
    //               },
    //               selectedColor: AppColor.red.withValues(alpha: 0.2),
    //               checkmarkColor: AppColor.red,
    //               labelStyle: GoogleFonts.dmSans(
    //                 color:
    //                     _selectedDuration == duration
    //                         ? AppColor.red
    //                         : AppColor.primaryColor,
    //               ),
    //               shape: RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.circular(8),
    //                 side: BorderSide(
    //                   color:
    //                       _selectedDuration == duration
    //                           ? AppColor.red
    //                           : AppColor.primaryColor,
    //                 ),
    //               ),
    //             ),
    //           ),
    //         );
    //       }).toList(),
    // );
    Column(
      children: [
        Slider(
          thumbColor: AppColor.white,
          activeColor: AppColor.red,
          value: _rating,
          min: 0,
          max: 10,
          divisions: 5,
          label: _rating.toStringAsFixed(1),
          onChanged: (value) {
            setState(() {
              _rating = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 hr',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
            Text(
              '10 hr',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Hours: ${_rating.toStringAsFixed(1)}+',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.20,
          ),
        ),
        // Text(
        //   'Rating: ${_rating.toStringAsFixed(1)}+',
        //   style: const GoogleFonts.dmSans(

        //     fontWeight: FontWeight.w500),
        // ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.white),
        borderRadius: BorderRadius.circular(22),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          isExpanded: true,
          dropdownColor: AppColor.primaryColor,
          iconEnabledColor: AppColor.white,
          items:
              languages.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLanguage = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = [
      'All',
      'Programming',
      'Design',
      'Business',
      'Music',
      'Health',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.white),
        borderRadius: BorderRadius.circular(22),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          iconEnabledColor: AppColor.white,
          value: _selectedCategory,
          isExpanded: true,
          items:
              categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLevelDropdown() {
    final levels = ['Beginner', 'Intermediate', 'Advanced', 'All Levels'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.white),
        borderRadius: BorderRadius.circular(22),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLevel,
          iconEnabledColor: AppColor.white,
          isExpanded: true,
          items:
              levels.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.20,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedLevel = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRatingSlider() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.white),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ratings',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
            ),
            StarRatingWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      children: [
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 200,
          divisions: 20,
          inactiveColor: AppColor.red.withValues(alpha: 0.2),
          activeColor: AppColor.red,
          labels: RangeLabels(
            '\$${_priceRange.start.round()}',
            '\$${_priceRange.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values;
              _minPrice = values.start;
              _maxPrice = values.end;
            });
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildPriceInputField('Min', _minPrice, (value) {
                setState(() {
                  _minPrice = double.tryParse(value) ?? _minPrice;
                  _priceRange = RangeValues(_minPrice, _priceRange.end);
                });
              }),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildPriceInputField('Max', _maxPrice, (value) {
                setState(() {
                  _maxPrice = double.tryParse(value) ?? _maxPrice;
                  _priceRange = RangeValues(_priceRange.start, _maxPrice);
                });
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceInputField(
    String label,
    double value,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.20,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColor.white),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.20,
            ),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.20,
              ),
              border: InputBorder.none,
              hintText: label,
            ),
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            controller: TextEditingController(text: value.round().toString()),
          ),
        ),
      ],
    );
  }

  void _applyFilters() {
    // Implement your filter logic here
    if (kDebugMode) {
      print('Applied Filters:');
      print('Duration: $_selectedDuration');
      print('Language: $_selectedLanguage');
      print('Category: $_selectedCategory');
      print('Level: $_selectedLevel');
      print('Rating: $_rating');
      print('Price Range: \$${_minPrice.round()} - \$${_maxPrice.round()}');
    }

    // You can use GetX to update the controller or call a callback function
    // Example: Get.find<YourFilterController>().updateFilters(...);
  }
}
