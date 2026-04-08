import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/view/users/student_view/bottom_nav_bar_holder.dart';
import 'package:google_fonts/google_fonts.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});
  @override
  InterestSelectionScreenState createState() =>
      InterestSelectionScreenState();
}

class InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final List<Map<String, String>> categories = [
    {'name': 'Technology', 'emoji': '💻'},
    {'name': 'Language Learning', 'emoji': '🗣️'},
    {'name': 'Career Advice', 'emoji': '💼'},
    {'name': 'Business', 'emoji': '📈'},
    {'name': 'Programming', 'emoji': '👨‍💻'},
    {'name': 'Writing', 'emoji': '✍️'},
    {'name': 'Science', 'emoji': '🔬'},
    {'name': 'Art & Design', 'emoji': '🎨'},
    {'name': 'Music', 'emoji': '🎵'},
    {'name': 'Reading', 'emoji': '📚'},
    {'name': 'Film & Media', 'emoji': '🎬'},
    {'name': 'Self Improvement', 'emoji': '💪'},
    {'name': 'Public Speaking', 'emoji': '🎤'},
    {'name': 'Math', 'emoji': '🧮'},
    {'name': 'Critical Thinking', 'emoji': '🤔'},
    {'name': 'Mindfulness', 'emoji': '🧘'},
    {'name': 'Sustainability', 'emoji': '🌱'},
    {'name': 'AI & Automation', 'emoji': '🤖'},
    {'name': 'Study Techniques', 'emoji': '📝'},
    {'name': 'Communication', 'emoji': '💬'},
    {'name': 'Other', 'emoji': '✨'},
  ];

  Set<String> selectedCategories = Set();
  bool get hasMinimumSelection => selectedCategories.length >= 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Let’s Select Your Learning Interests',
                style: GoogleFonts.dmSans(
                  color: AppColor.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Choose at least 2 topics you’re interested in.',
                style: GoogleFonts.dmSans(
                  color: AppColor.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        categories.map((category) {
                          final isSelected = selectedCategories.contains(
                            category['name'],
                          );
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedCategories.remove(category['name']);
                                } else {
                                  selectedCategories.add(
                                    category['name'] ?? "",
                                  );
                                }
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppColor.red.withValues(alpha: 0.08)
                                        :AppColor.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.red
                                          :AppColor.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    category['emoji']!,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    category['name']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isSelected
                                              ? AppColor.white
                                              : AppColor.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed:
              //         hasMinimumSelection
              //             ? () {
              //               // Handle continue action
              //               ScaffoldMessenger.of(context).showSnackBar(
              //                 SnackBar(
              //                   content: Text(
              //                     'Selected ${selectedCategories.length} categories',
              //                   ),
              //                 ),
              //               );
              //             }
              //             : null,
              //     style: ElevatedButton.styleFrom(
              //       padding: EdgeInsets.symmetric(vertical: 16),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       backgroundColor:
              //           hasMinimumSelection ? Colors.red : Colors.grey[300],
              //     ),
              //     child: Text(
              //       'Continue',
              //       style: TextStyle(
              //         fontSize: 16,
              //         color:
              //             hasMinimumSelection ? Colors.white : Colors.grey[600],
              //       ),
              //     ),
              //   ),
              // ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap:
                        () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MainWrapper()),
                        ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: AppColor.red,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Continue",
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: AppColor.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SvgPicture.asset("assets/icons/arrow.svg"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:getxmvvm/resources/colors/app_colors.dart';
// import 'package:google_fonts/google_fonts.dart';

// class CategorySelectionScreen extends StatefulWidget {
//   @override
//   _CategorySelectionScreenState createState() =>
//       _CategorySelectionScreenState();
// }

// class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
//   final List<String> allCategories = [
//     'Technology',
//     'Language Learning',
//     'Career Advice',
//     'Business',
//     'Programming',
//     'Writing',
//     'Science',
//     'Art & Design',
//     'Music',
//     'Reading',
//     'Film & Media',
//     'Self Improvement',
//     'Public Speaking',
//     'Math',
//     'Critical Thinking',
//     'Mindfulness',
//     'Sustainability',
//     'AI & Automation',
//     'Study Techniques',
//     'Communication',
//     'Other',
//   ];

//   List<String> filteredCategories = [];
//   Set<String> selectedCategories = {};
//   TextEditingController searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     filteredCategories = allCategories;
//     searchController.addListener(_filterCategories);
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   void _filterCategories() {
//     final query = searchController.text.toLowerCase();
//     setState(() {
//       filteredCategories =
//           allCategories.where((category) {
//             return category.toLowerCase().contains(query);
//           }).toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColor.primaryColor,

//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: TextField(
//                 controller: searchController,
//                 decoration: InputDecoration(
//                   prefixIcon: Icon(Icons.search),
//                   hintText: 'Search categories...',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   contentPadding: EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   '${selectedCategories.length} selected',
//                   style: TextStyle(
//                     color: Colors.blue,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.all(16),
//                 child: Wrap(
//                   spacing: 8.0,
//                   runSpacing: 8.0,
//                   children:
//                       filteredCategories.map((category) {
//                         return FilterChip(
//                           label: Text(category),
//                           selected: selectedCategories.contains(category),
//                           onSelected: (selected) {
//                             setState(() {
//                               if (selected) {
//                                 selectedCategories.add(category);
//                               } else {
//                                 selectedCategories.remove(category);
//                               }
//                             });
//                           },
//                           selectedColor: AppColor.primaryColor.withOpacity(0.8),
//                           checkmarkColor: AppColor.red,
//                           labelStyle: TextStyle(
//                             color:
//                                 selectedCategories.contains(category)
//                                     ? AppColor.white
//                                     : Colors.black,
//                           ),
//                           shape: StadiumBorder(
//                             side: BorderSide(
//                               color:
//                                   selectedCategories.contains(category)
//                                       ? AppColor.primaryColor.withOpacity(0.8)
//                                       : Colors.grey[300]!,
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                 ),
//               ),
//             ),
//             if (selectedCategories.isNotEmpty)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                    Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(28),
//                         color: AppColor.red,
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 8.0,
//                           horizontal: 16.0,
//                         ),
//                         child: Row(
//                           children: [
//                             Text(
//                               "Continue",
//                               style: GoogleFonts.dmSans(
//                                 fontSize: 14,
//                                 color: AppColor.white,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                             SvgPicture.asset("assets/icons/arrow.svg"),
//                           ],
//                         ),
//                       ),
//                     ),
//                   // Container(
//                   //   padding: EdgeInsets.all(16),
//                   //   width: double.infinity,
//                   //   child: ElevatedButton(
//                   //     onPressed: () {
//                   //       // Handle continue action
//                   //       ScaffoldMessenger.of(context).showSnackBar(
//                   //         SnackBar(
//                   //           content: Text(
//                   //             'Selected ${selectedCategories.length} categories',
//                   //           ),
//                   //         ),
//                   //       );
//                   //     },
//                   //     child: Text('Continue'),
//                   //     style: ElevatedButton.styleFrom(
//                   //       padding: EdgeInsets.symmetric(vertical: 16),
//                   //       shape: RoundedRectangleBorder(
//                   //         borderRadius: BorderRadius.circular(12),
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
