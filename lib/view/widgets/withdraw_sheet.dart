import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/utils/responsive.dart';

/// Withdrawal bottom sheet — bank payouts are coming soon via Stripe Connect.
/// Shows the available balance and a locked "coming soon" state.
Future<void> showWithdrawSheet(
  BuildContext context, {
  required double? availableBalance,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WithdrawSheet(availableBalance: availableBalance),
  );
}

class WithdrawSheet extends StatelessWidget {
  /// Server `availableBalance` from GET /earnings; the row is hidden when null.
  final double? availableBalance;

  const WithdrawSheet({super.key, required this.availableBalance});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColor.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        Responsive.w(5),
        Responsive.h(3),
        Responsive.w(5),
        Responsive.h(3) + bottomPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColor.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: Responsive.h(2)),

          Text(
            'Withdraw Earnings',
            style: GoogleFonts.rethinkSans(
              color: AppColor.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: Responsive.h(0.5)),

          // Available balance (server value)
          if (availableBalance != null) ...[
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(4),
              vertical: Responsive.h(1.5),
            ),
            decoration: BoxDecoration(
              color: AppColor.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Balance',
                  style: GoogleFonts.dmSans(
                    color: AppColor.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatMoney(availableBalance!),
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ],
          SizedBox(height: Responsive.h(3)),

          // Coming soon notice
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(5),
              vertical: Responsive.h(2.5),
            ),
            decoration: BoxDecoration(
              color: AppColor.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColor.white.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: AppColor.white.withValues(alpha: 0.4),
                  size: 36,
                ),
                SizedBox(height: Responsive.h(1.5)),
                Text(
                  'Bank Payouts Coming Soon',
                  style: GoogleFonts.rethinkSans(
                    color: AppColor.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: Responsive.h(0.8)),
                Text(
                  'We\'re integrating Stripe Connect to enable secure bank transfers. '
                  'Your earnings are safe and will be available for withdrawal once this feature launches.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColor.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.h(3)),

          // Disabled button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppColor.red.withValues(alpha: 0.3),
                padding: EdgeInsets.symmetric(vertical: Responsive.h(2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Withdrawals Coming Soon',
                style: GoogleFonts.dmSans(
                  color: AppColor.white.withValues(alpha: 0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
