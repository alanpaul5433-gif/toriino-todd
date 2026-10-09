import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/model/mentor/mentor_model.dart';
import 'package:toriino_todd/repository/mentor_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/view/users/student_view/availability_view.dart';
import 'package:toriino_todd/widgets/components/starrating.dart';
import 'package:toriino_todd/widgets/intro_video_tile.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorPublicProfile extends StatefulWidget {
  final MentorModel? mentor;
  const MentorPublicProfile({super.key, this.mentor});

  @override
  State<MentorPublicProfile> createState() => _MentorPublicProfileState();
}

class _MentorPublicProfileState extends State<MentorPublicProfile> {
  MentorModel? _mentor;

  @override
  void initState() {
    super.initState();
    _mentor = widget.mentor;
    _refreshMentor();
  }

  /// GET /mentors/{id} returns the full record (incl. introVideoUrl, which
  /// list payloads may omit).
  Future<void> _refreshMentor() async {
    final id = widget.mentor?.userId ?? '';
    if (id.isEmpty) return;
    try {
      final value = await MentorRepo().getMentorById(id);
      if (!mounted || value is! Map<String, dynamic>) return;
      setState(() => _mentor = MentorModel.fromJson(value));
    } catch (_) {
      // Keep showing the data we were given.
    }
  }

  @override
  Widget build(BuildContext context) {
    final mentor = _mentor;
    Responsive.init(context);
    if (mentor == null) {
      return Scaffold(
        backgroundColor: AppColor.primaryColor,
        body: const SafeArea(
          child: Center(
            child: Text(
              'Profile not available',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: SvgPicture.asset(
                        "assets/icons/Arrow - Right 3 (1).svg",
                      ),
                    ),
                    SizedBox(width: Responsive.w(2)),
                    Text(
                      'Mentor Profile',
                      style: GoogleFonts.rethinkSans(
                        color: AppColor.white,
                        fontSize: Responsive.textScaleFactor * 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),

                //Profile Pic Name Domain and Share Icon
                SizedBox(height: Responsive.h(2)),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        CircleAvatar(
                          radius: Responsive.w(10),
                          backgroundImage: (mentor.avatarUrl != null && mentor.avatarUrl!.isNotEmpty)
                              ? NetworkImage(mentor.avatarUrl!) as ImageProvider
                              : const AssetImage("assets/icons/Ellipse 6 (1).png"),
                        ),
                        SizedBox(width: Responsive.w(2)),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  mentor.name ?? '--',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: Responsive.textScaleFactor * 18,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: -0.30,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              (mentor.expertise?.isNotEmpty == true) ? '${mentor.expertise!.first} Specialist' : '--',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: Responsive.textScaleFactor * 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.white.withValues(alpha: 0.08),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SvgPicture.asset('assets/icons/share.svg'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      'Industry',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.20,
                      ),
                    ),

                    Text(
                      (mentor.expertise?.isNotEmpty == true) ? mentor.expertise!.first : '--',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      'Years of Experience',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.20,
                      ),
                    ),

                    Text(
                      '--',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.20,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                Text(
                  mentor.bio ?? '--',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: Responsive.sp(10),
                    fontWeight: FontWeight.w400,
                    height: 1.50,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Row(
                      children: [
                        SvgPicture.asset("assets/icons/mic.svg"),
                        Text(
                          '--',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.textScaleFactor * 10,
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.20,
                          ),
                        ),
                      ],
                    ),

                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: mentor.hourlyRate != null ? '\$${mentor.hourlyRate!.toInt()}/' : '--',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 12,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.20,
                            ),
                          ),
                          TextSpan(
                            text: mentor.hourlyRate != null ? 'hr' : '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.textScaleFactor * 12,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                //Divider
                Row(children: [Expanded(child: Divider())]),

                Text(
                  'Expertise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),

                //Skill cipsviewview
                Wrap(
                  spacing: 5,
                  runSpacing: 10,
                  children: (mentor.expertise != null && mentor.expertise!.isNotEmpty)
                      ? mentor.expertise!.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: ShapeDecoration(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(width: 1, color: Colors.white.withValues(alpha: 0.40)),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              height: 1.50,
                            ),
                          ),
                        )).toList()
                      : [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(width: 1, color: Colors.white.withValues(alpha: 0.40)),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '--',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'DM Sans'),
                            ),
                          ),
                        ],
                ),
                SizedBox(height: Responsive.h(2)),

                Text(
                  'Intro Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.textScaleFactor * 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: Responsive.h(2)),

                //video view
                // Container(
                //   width: double.infinity,

                // ),
                IntroVideoTile(url: mentor.introVideoUrl),
                SizedBox(height: Responsive.h(2)),

                //rating row
                Row(
                  children: [
                    StarRatingWidget(
                      initialRating: mentor.rating ?? 0.0,
                      readOnly: true,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(mentor.rating ?? 0.0).toStringAsFixed(1)} (${mentor.totalSessions ?? 0} reviews)',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                //reivew and viewa all
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reviews',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'View all',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        height: 1.60,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(2)),

                //comments card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 9,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 9,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: ShapeDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              "assets/icons/Ellipse 6.png",
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 3,
                                        children: [
                                          Text(
                                            '--',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'DM Sans',
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.30,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: List.generate(
                                              5,
                                              (index) => Container(
                                                width: 13,
                                                height: 13,
                                                margin: const EdgeInsets.only(
                                                  right: 2,
                                                ),

                                                child: Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.white,
                                                ), //
                                                // decoration:
                                                // const BoxDecoration(
                                                //   color: Colors.amber,
                                                //   shape:
                                                //       BoxShape.circle,
                                                // ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '15 Days Ago',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 325,
                              child: Text(
                                "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(2)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 9,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    spacing: 9,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: ShapeDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              "assets/icons/Ellipse 6.png",
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                          shape: OvalBorder(),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        spacing: 3,
                                        children: [
                                          Text(
                                            '--',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'DM Sans',
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.30,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: List.generate(
                                              5,
                                              (index) => Container(
                                                width: 13,
                                                height: 13,
                                                margin: const EdgeInsets.only(
                                                  right: 2,
                                                ),

                                                child: Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.white,
                                                ), //
                                                // decoration:
                                                // const BoxDecoration(
                                                //   color: Colors.amber,
                                                //   shape:
                                                //       BoxShape.circle,
                                                // ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '15 Days Ago',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 325,
                              child: Text(
                                "I'm a data scientist with 5+ years of experience mentoring professionals and students in machine learning, Python, and data visualization",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(2)),

                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AvailabilityView(
                            mentorId: mentor.userId ?? '',
                            mentorName: mentor.name ?? '',
                          ),
                        ),
                      ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: AppColor.red,
                    ),
                    child: Padding(
                      padding: Responsive.padding(
                        left: 1,
                        right: 1,
                        top: 2,
                        bottom: 2,
                      ),
                      child: Text(
                        'Book a session',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
