import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:getxmvvm/resources/colors/app_colors.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              spacing: 16,
              children: [
                Row(
                  spacing: 2,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset("assets/icons/Arrow - Right 3.svg"),
                    ),
                    Text(
                      'Privacy Policy',
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
                Text(
                  'Lorem ipsum dolor sit amet consectetur. Non egestas ornare volutpat lectus scelerisque nulla risus. Tellus commodo odio mi convallis risus ipsum elementum dis. Egestas dictum nisl leo netus aliquet tincidunt. Turpis accumsan iaculis odio adipiscing nulla sollicitudin non.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
                Text(
                  'Lorem ipsum dolor sit amet consectetur. Mi mattis purus duis diam felis elit. Facilisis semper convallis tellus morbi leo. At adipiscing nisl odio netus tristique elit convallis sodales duis. Egestas fermentum cursus cras adipiscing nibh.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
                Text(
                  'Lorem ipsum dolor sit amet consectetur. Mi mattis purus duis diam felis elit. Facilisis semper convallis tellus morbi leo. At adipiscing nisl odio netus tristique elit convallis sodales duis. Egestas fermentum cursus cras adipiscing nibh.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
                Text(
                  'Lorem ipsum dolor sit amet consectetur. Mi mattis purus duis diam felis elit. Facilisis semper convallis tellus morbi leo. At adipiscing nisl odio netus tristique elit convallis sodales duis. Egestas fermentum cursus cras adipiscing nibh.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
                Text(
                  'Lorem ipsum dolor sit amet consectetur. Mi mattis purus duis diam felis elit. Facilisis semper convallis tellus morbi leo. At adipiscing nisl odio netus tristique elit convallis sodales duis. Egestas fermentum cursus cras adipiscing nibh.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
                  ),
                ),
                Text(
                  'Lorem ipsum dolor sit amet consectetur. Mi mattis purus duis diam felis elit. Facilisis semper convallis tellus morbi leo. At adipiscing nisl odio netus tristique elit convallis sodales duis. Egestas fermentum cursus cras adipiscing nibh.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    height: 1.67,
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
