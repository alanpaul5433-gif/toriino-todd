import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/view/users/student_view/chips.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 5,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Notification',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Rethink Sans',
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.20,
                    ),
                  ),
                ],
              ),
              ChipSelection(),
              Container(
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white.withValues(alpha: 0.10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            width: 30,
                            height: 30,
                            "assets/icons/checkmark-circle-02.svg",
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        // ← ADD THIS WRAPPER
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Approved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2), // ← ADD SPACING
                            Text(
                              'Your course Design Thinking for Beginners has been approved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                              overflow: TextOverflow.ellipsis, // ← KEEP THIS
                              maxLines: 2, // ← ADD THIS LINE
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white.withValues(alpha: 0.10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            width: 30,
                            height: 30,
                            "assets/icons/checkmark-circle-02.svg",
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        // ← ADD THIS WRAPPER
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Student Enrolled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2), // ← ADD SPACING
                            Text(
                              '3 students enrolled in your course Advanced Graphic Design today.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                              overflow: TextOverflow.ellipsis, // ← KEEP THIS
                              maxLines: 2, // ← ADD THIS LINE
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white.withValues(alpha: 0.10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            width: 30,
                            height: 30,
                            "assets/icons/invoice.svg",
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        // ← ADD THIS WRAPPER
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Failed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2), // ← ADD SPACING
                            Text(
                              'Payment withdraw failed. Please try again',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                              overflow: TextOverflow.ellipsis, // ← KEEP THIS
                              maxLines: 2, // ← ADD THIS LINE
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColor.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.red.withValues(alpha: 0.10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            width: 30,
                            height: 30,
                            "assets/icons/information-square.svg",
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                      Expanded(
                        // ← ADD THIS WRAPPER
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2), // ← ADD SPACING
                            Text(
                              'We’ve updated our terms of service. Review here.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                              overflow: TextOverflow.ellipsis, // ← KEEP THIS
                              maxLines: 2, // ← ADD THIS LINE
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}















































// import 'package:flutter/material.dart';

// class NotificationsScreen extends StatelessWidget {
//   const NotificationsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () {},
//         ),
//         title: Text(
//           'Notification',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           Padding(
//             padding: EdgeInsets.only(right: 16.0),
//             child: Text(
//               '9:41',
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Tab Bar
//           Container(
//             height: 50,
//             decoration: BoxDecoration(
//               border: Border(
//                 bottom: BorderSide(color: Colors.grey.shade300),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TabButton(
//                     text: 'All',
//                     isActive: true,
//                     onTap: () {},
//                   ),
//                 ),
//                 Expanded(
//                   child: TabButton(
//                     text: 'Payment',
//                     isActive: false,
//                     onTap: () {},
//                   ),
//                 ),
//                 Expanded(
//                   child: TabButton(
//                     text: 'Booking',
//                     isActive: false,
//                     onTap: () {},
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // Notifications List
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.all(16),
//               children: [
//                 NotificationCard(
//                   icon: Icons.check_circle,
//                   iconColor: Colors.green,
//                   title: 'Course Approved',
//                   description: 'Your course Design Thinking for Beginners has been approved',
//                   time: '2 hours ago',
//                 ),
                
//                 SizedBox(height: 16),
                
//                 NotificationCard(
//                   icon: Icons.group,
//                   iconColor: Colors.blue,
//                   title: 'New Student Enrolled',
//                   description: '3 students enrolled in your course Advanced Graphic Design today.',
//                   time: '5 hours ago',
//                 ),
                
//                 SizedBox(height: 16),
                
//                 NotificationCard(
//                   icon: Icons.error,
//                   iconColor: Colors.red,
//                   title: 'Payment Failed',
//                   description: 'Payment withdraw failed. Please try again.',
//                   time: '1 day ago',
//                 ),
                
//                 SizedBox(height: 16),
                
//                 NotificationCard(
//                   icon: Icons.update,
//                   iconColor: Colors.orange,
//                   title: 'Update',
//                   description: 'We\'ve updated our terms of service. Review here.',
//                   time: '2 days ago',
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TabButton extends StatelessWidget {
//   final String text;
//   final bool isActive;
//   final VoidCallback onTap;

//   const TabButton({
//     required this.text,
//     required this.isActive,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isActive ? Colors.blue : Colors.transparent,
//               width: 2,
//             ),
//           ),
//         ),
//         child: Center(
//           child: Text(
//             text,
//             style: TextStyle(
//               color: isActive ? Colors.blue : Colors.grey,
//               fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//               fontSize: 14,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class NotificationCard extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final String title;
//   final String description;
//   final String time;

//   const NotificationCard({
//     required this.icon,
//     required this.iconColor,
//     required this.title,
//     required this.description,
//     required this.time,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       padding: EdgeInsets.all(16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Icon
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: iconColor.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: iconColor,
//               size: 20,
//             ),
//           ),
          
//           SizedBox(width: 12),
          
//           // Content
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
                
//                 SizedBox(height: 4),
                
//                 Text(
//                   description,
//                   style: TextStyle(
//                     color: Colors.grey.shade700,
//                     fontSize: 14,
//                   ),
//                 ),
                
//                 SizedBox(height: 8),
                
//                 Text(
//                   time,
//                   style: TextStyle(
//                     color: Colors.grey.shade500,
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }