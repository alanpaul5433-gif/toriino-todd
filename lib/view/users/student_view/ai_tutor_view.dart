import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/viewmodel/controller/common/ai_tutor_viewmodel.dart';
import 'package:google_fonts/google_fonts.dart';

class AiTutorView extends StatelessWidget {
  AiTutorView({super.key});

  final AiTutorViewmodel chatController = Get.put(AiTutorViewmodel());

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  SvgPicture.asset('assets/icons/Toriino AI.svg', height: 28),
                  SizedBox(width: Responsive.w(2)),
                  Text(
                    "AI Tutor",
                    style: GoogleFonts.rethinkSans(
                      color: AppColor.white,
                      fontSize: Responsive.textScaleFactor * 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      chatController.messages.clear();
                      chatController.onInit();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        color: AppColor.red,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            SvgPicture.asset("assets/icons/plus-sign.svg", height: 14),
                            SizedBox(width: 4),
                            Text(
                              "New Chat",
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: AppColor.white.withValues(alpha: 0.1)),

            // Chat messages
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: chatController.messages.length + (chatController.isTyping.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator
                    if (index == chatController.messages.length && chatController.isTyping.value) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColor.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.red,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "AI is thinking...",
                                    style: GoogleFonts.dmSans(
                                      color: AppColor.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final msg = chatController.messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!msg.isUser) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColor.red,
                              child: SvgPicture.asset('assets/icons/robotic.svg', height: 16),
                            ),
                            SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: msg.isUser
                                    ? AppColor.red
                                    : AppColor.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    msg.time,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (msg.isUser) SizedBox(width: 8),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColor.primaryColor,
                border: Border(top: BorderSide(color: AppColor.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chatController.messageController,
                      style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Ask anything...",
                        hintStyle: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColor.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => chatController.sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => chatController.sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.red,
                      ),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
