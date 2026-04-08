import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:getxmvvm/getx_controllers/advanceddrawercontroller.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/utils/utils.dart';
import 'package:getxmvvm/view/users/student_view/bottom_filter.dart';
import 'package:getxmvvm/view/users/student_view/notification_view.dart';
import 'package:getxmvvm/widgets/auth_button.dart';
import 'package:getxmvvm/viewmodel/controller/student/course_viewmodel.dart';
import 'package:getxmvvm/data/response/status.dart';
import 'package:google_fonts/google_fonts.dart';

class CourseView extends StatelessWidget {
  CourseView({super.key});

  final CourseViewmodel courseController = Get.put(CourseViewmodel());

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.0.w),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Courses",
                      style: TextStyle(
                        color: AppColor.secconderyColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                    //  GestureDetector(
                    //   onTap: () => Navigator.pop(context),
                    //   child: Row(
                    //     spacing: 4,
                    //     children: [
                    //       SvgPicture.asset(
                    //         width: Responsive.w(6),
                    //         height: Responsive.w(6),
                    //         "assets/icons/Arrow - Right 3.svg",
                    //       ),
                    //       Text(
                    //         "Courses",
                    //         style: TextStyle(
                    //           color: AppColor.secconderyColor,
                    //           fontWeight: FontWeight.w600,
                    //           fontSize: 16.sp,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ),
                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(),
                          ),
                        ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: Responsive.padding(
                          left: 2,
                          right: 2,
                          bottom: 2,
                          top: 2,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/notification.svg',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () {
                      return customDrawerController.toggleDrawer();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.backGroundColor.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: Responsive.padding(
                          left: 2,
                          right: 2,
                          bottom: 2,
                          top: 2,
                        ),
                        child: SvgPicture.asset('assets/icons/menu.svg'),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: "Search by title, mentor, or tag",
                        hintStyle: TextStyle(
                          color: AppColor.secconderyColor,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColor.secconderyColor,
                        ),
                        filled: true,
                        fillColor: AppColor.backGroundColor.withValues(
                          alpha: 0.1,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () => _showFilterSuggestipon(context),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.red,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(8.0.w),
                        child: SvgPicture.asset(
                          'assets/icons/filter.svg',
                          // Using a placeholder icon
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: Obx(() {
                  final response = courseController.rxCourses.value;
                  if (response.status == Status.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (response.status == Status.error) {
                    return Center(child: Text('Error loading courses', style: TextStyle(color: AppColor.white)));
                  }
                  final courses = response.data?.courses ?? [];
                  return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: EdgeInsets.all(8.0.w),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          color: AppColor.white.withValues(alpha: 0.08),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        "assets/icons/Frame 1000002079.svg",
                                        // Using a placeholder icon
                                        colorFilter: ColorFilter.mode(
                                          AppColor.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      SizedBox(width: 10.w),
                                      Text(
                                        "\$${courses[index].price?.toStringAsFixed(2) ?? '0.00'}",
                                        style: TextStyle(
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _enrollBottomSheet(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        color: AppColor.red,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8.0.h,
                                          horizontal: 16.0.w,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Enroll",
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: AppColor.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 5.w),
                                            SvgPicture.asset(
                                              "assets/icons/arrow.svg",
                                              // Using a placeholder icon
                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Colors.white,
                                                    BlendMode.srcIn,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "Duration: ${courses[index].duration ?? 'N/A'}",
                                style: TextStyle(
                                  color: AppColor.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    courses[index].title ?? 'Course',
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      color: AppColor.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: AssetImage(
                                          "assets/images/mentor.png",
                                        ),
                                        radius: 20.r,
                                        backgroundColor:
                                            AppColor.secconderyColor,
                                      ),
                                      SizedBox(width: 10.w),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            courses[index].category ?? 'Category',
                                            style: TextStyle(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          Text(
                                            courses[index].level ?? 'Level',
                                            style: TextStyle(
                                              color: AppColor.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: AppColor.white,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        "${courses[index].rating ?? 0}",
                                        style: TextStyle(
                                          color: AppColor.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _enrollBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: AppColor.primaryColor,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: Responsive.w(5),
          right: Responsive.w(5),
          top: Responsive.h(3),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "UI/UX Design Basics",
                  style: TextStyle(
                    color: AppColor.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.close, color: AppColor.white),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(2)),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage("assets/images/mentor.png"),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chance Calzoni',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Teacher',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: Responsive.h(2)),
            const Divider(color: Colors.grey),
            SizedBox(height: Responsive.h(2)),
            _cousreinfo("Course Category", "Design"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Course Duration", "2–5h"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Language", "English"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Rating", "4.5"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Price Info", "\$19.99"),
            SizedBox(height: Responsive.h(1)),
            _cousreinfo("Platform Fee", "\$4.99"),
            SizedBox(height: Responsive.h(2)),
            Text(
              "It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            SizedBox(height: Responsive.h(2)),
            AuthButton(
              buttontext: "Proceed to Payment",
              onPress: () {
                Navigator.pop(context); // Close the bottom sheet
                _showPaymentAlert(context); // Show the payment alert
              },
              loading: false,
            ),
            SizedBox(height: Responsive.h(2)),
          ],
        ),
      );
    },
  );
}

Widget _cousreinfo(String text1, String text2) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        text1,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
        ),
      ),
      Text(
        text2,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

void _showFilterSuggestipon(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const FilterBottomSheet(),
  );
}

void _showPaymentAlert(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.0.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/icons/checkmark-circle-02.svg"),
              SizedBox(height: 15.h),
              Text(
                "Course Purchased!",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                "It is a long established fact that a reader will be distracted by the readable content of a page.",
                style: TextStyle(color: AppColor.white, fontSize: 16.sp),
              ),
              SizedBox(height: 10.h),

              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  Utils.toastMassage("Successful");
                },
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
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
              ),
            ],
          ),
        ),
      );
    },
  );
}
