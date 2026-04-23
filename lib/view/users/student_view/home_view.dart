import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/getx_controllers/advanceddrawercontroller.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/view/users/mentor_view/mentor_public_profile.dart';
import 'package:toriino_todd/view/users/student_view/availability_view.dart';
import 'package:toriino_todd/view/users/student_view/browsetecaher.dart';
import 'package:toriino_todd/view/users/student_view/course_view.dart';
import 'package:toriino_todd/view/users/student_view/my_taken_cousre_view.dart';
import 'package:toriino_todd/view/users/student_view/mycourse_view.dart';
import 'package:toriino_todd/view/users/student_view/notification_view.dart';
import 'package:toriino_todd/view/users/student_view/student_private_profile_view.dart';
import 'package:toriino_todd/view/users/student_view/teacher_profile.dart';
import 'package:toriino_todd/viewmodel/controller/login/user_prefrence/users_prefrence.dart';
import 'package:toriino_todd/viewmodel/controller/student/home_viewmodel.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/widgets/auth_button.dart';
import 'package:toriino_todd/widgets/components/custom_recent_quiz.dart';
import 'package:toriino_todd/widgets/custom_button.dart';
import 'package:toriino_todd/widgets/custom_ongoing_widget_card.dart';
import 'package:toriino_todd/widgets/custom_recommended_mentors.dart';
import 'package:toriino_todd/widgets/custom_recommended_teacher.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  UsersPrefrence usersPrefrence = UsersPrefrence();
  final HomeViewmodel homeController = Get.put(HomeViewmodel());
  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final CustomDrawerController customDrawerController =
        Get.find<CustomDrawerController>();
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: Responsive.padding(left: 2, right: 2, bottom: 1, top: 1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentProfile(),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              child: Image.asset("assets/images/michel.png"),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Obx(() {
                            final profile = homeController.rxProfile.value;
                            final name = profile.status == Status.success
                                ? profile.data?.name ?? 'User'
                                : 'User';
                            final userId = profile.status == Status.success
                                ? profile.data?.userId ?? ''
                                : '';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hi $name",
                                  style: GoogleFonts.dmSans(
                                    color: AppColor.secconderyColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: Responsive.sp(10),
                                  ),
                                ),
                                Row(
                                  spacing: Responsive.w(1),
                                  children: [
                                    Text(
                                      "ID: ${userId.length > 8 ? userId.substring(0, 8) : userId}",
                                      style: GoogleFonts.dmSans(
                                        color: AppColor.secconderyColor,
                                        fontWeight: FontWeight.w400,
                                        fontSize: Responsive.sp(10),
                                      ),
                                    ),
                                    SvgPicture.asset('assets/icons/copy.svg'),
                                  ],
                                ),
                              ],
                            );
                          }),
                          SizedBox(width: 8.w),
                        ],
                      ),
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
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
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
                    SizedBox(width: Responsive.w(2)),
                    GestureDetector(
                      onTap: () {
                        return customDrawerController.toggleDrawer();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.backGroundColor.withValues(
                            alpha: 0.1,
                          ),
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
                SizedBox(height: 24.h),
                Obx(() {
                  final coursesCount = homeController.rxCourses.value.status == Status.success
                      ? homeController.rxCourses.value.data?.count ?? 0
                      : 0;
                  return Row(
                    spacing: Responsive.w(2),
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MycourseView()),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColor.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(22.r),
                            ),
                            child: Padding(
                              padding: Responsive.padding(left: 2, right: 2, top: 1, bottom: 1),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Courses in\nProgress", style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.sp(10))),
                                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                    Text(coursesCount.toString().padLeft(2, '0'), style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.textScaleFactor * 20)),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => customDrawerController.changeIndex(2),
                          child: Container(
                            decoration: BoxDecoration(color: AppColor.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(22.r)),
                            child: Padding(
                              padding: Responsive.padding(left: 2, right: 2, top: 1, bottom: 1),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Session\n Booked", style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.sp(10))),
                                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                    Text("04", style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.textScaleFactor * 20)),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: AppColor.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(22.r)),
                          child: Padding(
                            padding: Responsive.padding(left: 2, right: 2, top: 1, bottom: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Certificates\n Earned", style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.sp(10))),
                                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                  Text("02", style: GoogleFonts.dmSans(color: AppColor.secconderyColor, fontSize: Responsive.textScaleFactor * 20)),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                SizedBox(height: Responsive.h(1)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: AppColor.white.withValues(alpha: 0.1),
                  ),
                  width: double.infinity,
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ask the AI Tutor 24/7",
                            style: GoogleFonts.dmSans(
                              color: AppColor.secconderyColor,
                              fontSize: Responsive.sp(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Get instant academic help, practice quizzes,\nexplanations powered by AI.",
                            style: GoogleFonts.dmSans(
                              color: AppColor.secconderyColor,
                              fontSize: Responsive.sp(12),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          CustomButton(
                            width: 191.w,
                            backgroundColor: AppColor.red,
                            textColor: AppColor.secconderyColor,
                            text: 'Upgrade to Premium',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(1)),

                OngoingCourseCard(
                  courseNo: 01,
                  headerText: 'Ongoing Course',
                  courseTitle: 'UI/UX Design Basics',
                  duration: '2 days ago',
                  courseStatus: 'completion',
                  mentorName: 'Chance Calzoni',
                  rating: 4.8,
                  continuetocousre: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MyTakenCousreView()),
                    );
                  },
                ),
                SizedBox(height: Responsive.h(1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recommended Mentors",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(builder: (_) => BrowseMentor()),
                            // );
                              customDrawerController.changeIndex(
                            2,
                          ); // Navigate to BrowseMentor
                          },
                          child: Text(
                            "View ALl",
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              color: AppColor.white,
                              fontSize: Responsive.sp(10),
                            ),
                          ),
                        ),
                        SvgPicture.asset("assets/icons/eva_arrow-up-fill.svg"),
                      ],
                    ),
                  ],
                ),
                Obx(() {
                  final mentorsResponse = homeController.rxMentors.value;
                  if (mentorsResponse.status == Status.success && mentorsResponse.data != null && mentorsResponse.data!.mentors.isNotEmpty) {
                    final mentor = mentorsResponse.data!.mentors[0];
                    return CustomRecommendedMentors(
                      headerText: 'Recommended Mentors',
                      imagePath: 'assets/icons/Ellipse 6 (1).png',
                      name: mentor.name ?? 'Mentor',
                      role: (mentor.expertise != null && mentor.expertise!.isNotEmpty) ? mentor.expertise!.first : 'Specialist',
                      rating: mentor.rating ?? 0.0,
                      description: mentor.bio ?? '',
                      languages: 'English, German',
                      pricePerHour: '\$${mentor.hourlyRate?.toInt() ?? 0}/hr',
                      onViewProfileTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MentorPublicProfile()));
                      },
                      onBookSessionTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AvailabilityView()));
                      },
                    );
                  }
                  return CustomRecommendedMentors(
                    headerText: 'Recommended Mentors',
                    imagePath: 'assets/icons/Ellipse 6 (1).png',
                    name: 'Loading...',
                    role: '',
                    rating: 0,
                    description: '',
                    languages: '',
                    pricePerHour: '',
                    onViewProfileTap: () {},
                    onBookSessionTap: () {},
                  );
                }),
                SizedBox(height: Responsive.h(1)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recommended Teachers",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                        fontSize: Responsive.sp(14),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => BrowseTecher()),
                            );
                          //     customDrawerController.changeIndex(
                          //   1,
                          // ); // Navigate to BrowseMentor
                          },
                          child: Text(
                            "View ALl",
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              color: AppColor.white,
                              fontSize: Responsive.sp(10),
                            ),
                          ),
                        ),
                        SvgPicture.asset("assets/icons/eva_arrow-up-fill.svg"),
                      ],
                    ),
                  ],
                ),
                Obx(() {
                  final mentorsResponse = homeController.rxMentors.value;
                  if (mentorsResponse.status == Status.success && mentorsResponse.data != null && mentorsResponse.data!.mentors.length > 1) {
                    final teacher = mentorsResponse.data!.mentors[1];
                    return CustomRecommendedTeacher(
                      headerText: teacher.name ?? 'Teacher',
                      imagePath: 'assets/images/abram.png',
                      name: teacher.name ?? 'Teacher',
                      role: (teacher.expertise != null && teacher.expertise!.isNotEmpty) ? teacher.expertise!.first : 'Expert',
                      rating: teacher.rating ?? 0.0,
                      description: teacher.bio ?? '',
                      languages: 'English, German',
                      pricePerHour: '\$${teacher.hourlyRate?.toInt() ?? 0}/hr',
                      onViewProfileTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherProfile()));
                      },
                      onBookSessionTap: () {},
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Upcoming Session",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                        fontSize: Responsive.textScaleFactor * 19,
                      ),
                    ),
                    Row(
                      children: [
                        // SessionsView
                        GestureDetector(
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(builder: (_) => SessionsView()),
                            // );
                                customDrawerController.changeIndex(
                            3,
                          ); 
                          },
                          child: Text(
                            "View ALl",
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              color: AppColor.white,
                            fontSize: Responsive.sp(10),
                            ),
                          ),
                        ),
                        SvgPicture.asset("assets/icons/eva_arrow-up-fill.svg"),
                      ],
                    ),
                  ],
                ),
                CustomRecentQuizCard(
                  title: 'Spoken English with Emerson G.',
                  subtitle: 'Tomorrow at 4:00 PM',
                  icon: 'assets/icons/alarm.svg',
                  iconBackgroundColor: AppColor.backGroundColor,
                  arrowColor: AppColor.secconderyColor,
                  firstIconBgColor: AppColor.backGroundColor,
                  onTap: () {
                    if (kDebugMode) {
                      print('Quiz card tapped');
                    }
                  },
                ),
                CustomRecentQuizCard(
                  title: 'Spoken English with Carter',
                  subtitle: 'Tomorrow at 4:00 PM',
                  icon: 'assets/icons/alarm.svg',
                  iconBackgroundColor: AppColor.backGroundColor,
                  arrowColor: AppColor.secconderyColor,
                  firstIconBgColor: AppColor.backGroundColor,
                  onTap: () {
                    if (kDebugMode) {
                      print('Quiz card tapped');
                    }
                  },
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Popular Courses",
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        color: AppColor.white,
                        fontSize: Responsive.textScaleFactor * 19,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CourseView()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            "View ALl",
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              color: AppColor.white,
                             fontSize: Responsive.sp(10),
                            ),
                          ),
                          SvgPicture.asset(
                            "assets/icons/eva_arrow-up-fill.svg",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(1)),
                Obx(() {
                  final coursesResponse = homeController.rxCourses.value;
                  if (coursesResponse.status == Status.success && coursesResponse.data != null && coursesResponse.data!.courses.isNotEmpty) {
                    final course = coursesResponse.data!.courses[0];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: AppColor.white.withValues(alpha: 0.1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                        child: Column(
                          spacing: 10,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  SvgPicture.asset("assets/icons/money-03 (1).svg"),
                                  Text(
                                    course.price == 0 ? "FREE" : "\$${course.price?.toStringAsFixed(2)}",
                                    style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor),
                                  ),
                                ]),
                                CustomButton(backgroundColor: AppColor.red, width: Responsive.w(30), text: "Enroll", onTap: () { _enrollBottomSheet(context); }),
                              ],
                            ),
                            Text("Duration: ${course.duration ?? 'N/A'}", style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                            Text(course.title ?? 'Course', style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 22, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  CircleAvatar(radius: 16, backgroundImage: AssetImage("assets/images/mentor.png")),
                                  SizedBox(width: 10.w),
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(course.category ?? '', style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                                    Text(course.level ?? '', style: GoogleFonts.dmSans(fontSize: Responsive.textScaleFactor * 12, fontWeight: FontWeight.bold, color: AppColor.secconderyColor)),
                                  ]),
                                ]),
                                Row(children: [
                                  Icon(Icons.star, color: AppColor.white, size: Responsive.textScaleFactor * 16),
                                  SizedBox(width: 4.w),
                                  Text("${course.rating ?? 0}", style: GoogleFonts.dmSans(color: AppColor.white, fontSize: Responsive.textScaleFactor * 16)),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
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
                  backgroundColor: AppColor.secconderyColor,
                  child: Icon(Icons.person, color: AppColor.white),
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
