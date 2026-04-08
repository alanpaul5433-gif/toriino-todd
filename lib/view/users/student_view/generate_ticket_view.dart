import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:getxmvvm/resources/colors/app_colors.dart';
import 'package:getxmvvm/utils/responsive.dart';
import 'package:getxmvvm/utils/utils.dart';
import 'package:getxmvvm/widgets/auth_button.dart';
import 'package:getxmvvm/widgets/components/edit.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatenewTicticketView extends StatelessWidget {
  CreatenewTicticketView({super.key});
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final FocusNode subjectFoucs = FocusNode();
  final FocusNode messageFoucs = FocusNode();
  final FocusNode buttonFoucs = FocusNode();
  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 10,
            children: [
              Row(
                children: [
                  // GestureDetector(
                  //   onTap: () => Navigator.pop(context),
                  //   child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                  // ),
                  // SizedBox(width: Responsive.w(1)),
                  Text(
                    "Create Support Ticket",
                    style: TextStyle(
                      fontSize: Responsive.textScaleFactor * 24,
                      color: AppColor.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              EditProfileTextfeild(
                text: 'Subject...',
                controller: subjectController,
                focusNode: subjectFoucs,
                nextfocusNode: messageFoucs,
                svgPath: '',
              ),

              TextFormField(
                maxLines: 5,
                controller: messageController,
                focusNode: messageFoucs,
                style: TextStyle(color: AppColor.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColor.white.withValues(alpha: 0.05),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.red),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.primaryColor),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  hint: Text(
                    "Message",
                    style: TextStyle(color: AppColor.white),
                  ),
                ),
                onFieldSubmitted: (value) {
                  Utils.fieldFoucsChange(context, messageFoucs, buttonFoucs);
                },
              ),
              Spacer(),

              AuthButton(
                buttontext: 'Submit',
                loading: false,
                onPress: () {
                  _showPaymentAlert(context);
                },
              ),
              SizedBox(height: Responsive.h(1)),
            ],
          ),
        ),
      ),
    );
  }
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
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset("assets/icons/checkmark-circle-02.svg"),
              SizedBox(height: 15),
              Text(
                "Your Response Sumbited",
                style: TextStyle(
                  color: AppColor.white,
                  fontSize: Responsive.textScaleFactor * 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 15),
              Text(
                "It is a long established fact that a reader will be distracted by the readable content of a page.",
                style: TextStyle(color: AppColor.white, fontSize: Responsive.textScaleFactor * 16),
              ),
              SizedBox(height: 10),

              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
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
                            "Ok",
                            style: GoogleFonts.dmSans(
                              fontSize:  Responsive.textScaleFactor *14,
                              color: AppColor.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          // SvgPicture.asset("assets/icons/arrow.svg"),
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
