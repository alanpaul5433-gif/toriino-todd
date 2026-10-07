import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/view/users/student_view/lesson_video_view.dart';

/// Opens the public (CloudFront) intro video in the app's video player.
void openIntroVideo(BuildContext context, String url) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => LessonVideoView(videoUrl: url, title: 'Intro Video'),
    ),
  );
}

/// The "Intro Video" card on mentor/teacher profiles. Plays [url] when set,
/// otherwise says there is no intro video yet.
class IntroVideoTile extends StatelessWidget {
  final String? url;
  const IntroVideoTile({super.key, this.url});

  @override
  Widget build(BuildContext context) {
    final u = url ?? '';
    final frame = SvgPicture.asset("assets/icons/Frame 1410120834.svg");
    if (u.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(opacity: 0.4, child: frame),
          const SizedBox(height: 6),
          const Text(
            'No intro video yet',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => openIntroVideo(context, u),
      child: Stack(
        alignment: Alignment.center,
        children: [
          frame,
          const Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}
