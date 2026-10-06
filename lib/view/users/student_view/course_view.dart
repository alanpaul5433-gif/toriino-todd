import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/model/course/course_model.dart';
import 'package:toriino_todd/repository/course_repo.dart';
import 'package:toriino_todd/services/stripe_service.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/student_view/bottom_filter.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:toriino_todd/viewmodel/controller/student/course_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
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
                                      _enrollBottomSheet(context, courses[index]);
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

void _enrollBottomSheet(BuildContext context, CourseModel course) {
  final price = course.price ?? 0;
  final fee = (price * 0.25).toStringAsFixed(2);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: AppColor.primaryColor,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        bool paying = false;
        void pay() {
          if (paying) return;
          setSheetState(() => paying = true);
          StripeService.purchaseCourse(
            courseId: course.courseId ?? '',
            courseTitle: course.title ?? 'Course',
          ).then((result) {
            if (result['success'] == true) {
              Navigator.pop(sheetContext);
              CourseRepo().enrollCourse(course.courseId ?? '').then((_) {
                _showEnrollSuccessDialog(context, course.title ?? 'Course');
              }).catchError((_) {
                _showEnrollSuccessDialog(context, course.title ?? 'Course');
              });
            } else {
              setSheetState(() => paying = false);
              Utils.toastMassage(result['message'] ?? 'Payment failed');
            }
          });
        }
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
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
                  Flexible(
                    child: Text(
                      course.title ?? 'Course',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColor.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: paying ? null : () => Navigator.pop(sheetContext),
                    child: Icon(Icons.close, color: AppColor.white),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColor.red,
                    child: Icon(Icons.person, color: AppColor.white),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.category ?? 'Teacher',
                        style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        course.level ?? '',
                        style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(2)),
              const Divider(color: Colors.grey),
              SizedBox(height: Responsive.h(2)),
              _cousreinfo("Course Category", course.category ?? '—'),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Course Duration", course.duration ?? '—'),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Level", course.level ?? '—'),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Rating", "${course.rating ?? 0}"),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Price", price == 0 ? "FREE" : "\$${price.toStringAsFixed(2)}"),
              SizedBox(height: Responsive.h(1)),
              _cousreinfo("Platform Fee", price == 0 ? "\$0.00" : "\$$fee"),
              SizedBox(height: Responsive.h(2)),
              if (course.description != null && course.description!.isNotEmpty)
                Text(
                  course.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w400, height: 1.5),
                ),
              SizedBox(height: Responsive.h(2)),
              AuthButton(
                buttontext: "Proceed to Payment",
                onPress: pay,
                loading: paying,
              ),
              SizedBox(height: Responsive.h(2)),
            ],
          ),
        );
      },
    ),
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

void _showEnrollSuccessDialog(BuildContext context, String courseTitle) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
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
                "You're Enrolled!",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'You now have access to "$courseTitle". Head to My Courses to start learning.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColor.white, fontSize: 14.sp, height: 1.5),
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
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
                            "Start Learning",
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
