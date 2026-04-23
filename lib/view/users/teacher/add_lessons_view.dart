import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';

class CourseContentWidget extends StatefulWidget {
  const CourseContentWidget({super.key});

  @override
  State<CourseContentWidget> createState() => _CourseContentWidgetState();
}

class _CourseContentWidgetState extends State<CourseContentWidget> {
  bool _isExpanded = false;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.withOpacity(0.2),
        //     spreadRadius: 1,
        //     blurRadius: 3,
        //     offset: const Offset(0, 1),
        //   ),
        // ],
      ),
      child: ExpansionTile(
        key: UniqueKey(),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        leading: SvgPicture.asset("assets/icons/Frame menu.svg"),
        title: Text(
          'UI Explaination',
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * 12,
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x26FF0000),
              ),child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: SvgPicture.asset("assets/icons/delete.svg"),),
              ),
            ),SizedBox(width: Responsive.w(1),),
            
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
          ],
        ),
        children: [
          // Video player section
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video thumbnail/placeholder
                Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                // Play button
                if (!_isPlaying)
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 48,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPlaying = true;
                      });
                      // Here you would implement actual video playback
                    },
                  ),
                // Video controls
                if (_isPlaying)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.pause, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isPlaying = false;
                            });
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: 0.3,
                            onChanged: (value) {},
                            activeColor: Colors.white,
                            inactiveColor: Colors.white54,
                          ),
                        ),
                        const Text(
                          '10:30',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // PDF attachment section
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Intro to Wireframes',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PDF 15 mb',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blue),
                  onPressed: () {
                    // Implement download functionality
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
