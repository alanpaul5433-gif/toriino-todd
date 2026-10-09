import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toriino_todd/model/payment/pricing_model.dart';
import 'package:toriino_todd/repository/payments_repo.dart';
import 'package:toriino_todd/repository/session_repo.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/services/stripe_service.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/utils/responsive.dart';
import 'package:toriino_todd/utils/utils.dart';
import 'package:toriino_todd/viewmodel/controller/student/home_viewmodel.dart';
import 'package:toriino_todd/viewmodel/controller/student/session_viewmodel.dart';
import 'package:toriino_todd/widgets/auth_button.dart';

/// Opens the 1-on-1 booking sheet for [mentorId].
///
/// Every amount shown comes from GET /payments/quote?mentorId=&duration=;
/// the app never calculates money. Booking flow:
///   1. POST /sessions (no price — the server prices it from the mentor's rate)
///   2. POST /payments/create-intent session_booking (useWallet: true)
///   3. paidWithWallet → done; clientSecret → Stripe PaymentSheet.
Future<void> showSessionBookingSheet(
  BuildContext context, {
  required String mentorId,
  required String mentorName,
  required DateTime scheduledAt,
  required int durationMinutes,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    backgroundColor: AppColor.primaryColor,
    builder: (_) => SessionBookingSheet(
      mentorId: mentorId,
      mentorName: mentorName,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      hostContext: context,
    ),
  );
}

class SessionBookingSheet extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final DateTime scheduledAt;
  final int durationMinutes;

  /// The page that opened the sheet — used for the result dialog after the
  /// sheet closes.
  final BuildContext hostContext;

  const SessionBookingSheet({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.hostContext,
  });

  @override
  State<SessionBookingSheet> createState() => _SessionBookingSheetState();
}

class _SessionBookingSheetState extends State<SessionBookingSheet> {
  final _paymentsRepo = PaymentsRepo();
  final _sessionRepo = SessionRepo();

  PaymentQuoteModel? _quote;
  String? _quoteError;
  bool _loadingQuote = true;
  bool _paying = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _loadingQuote = true;
      _quoteError = null;
    });
    try {
      final q = await _paymentsRepo.quoteForMentor(
        widget.mentorId,
        durationMinutes: widget.durationMinutes,
      );
      if (!mounted) return;
      setState(() {
        _quote = q;
        _loadingQuote = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoteError = Utils.errorMessage(e);
        _loadingQuote = false;
      });
    }
  }

  Future<void> _book() async {
    if (_paying || _quote == null) return;
    setState(() {
      _paying = true;
      _status = 'Booking your session…';
    });

    // Step 1: create the session. The server sets the price from the mentor's
    // hourly rate × duration — the app sends no price.
    String? sessionId;
    try {
      final result = await _sessionRepo.bookSession({
        'mentorId': widget.mentorId,
        'dateTime': widget.scheduledAt.toIso8601String(),
        'duration': widget.durationMinutes,
        'sessionType': 'one-on-one',
      });
      if (result is Map) {
        final nested = result['session'];
        final id = result['sessionId'] ??
            (nested is Map ? nested['sessionId'] : null);
        if (id is String && id.isNotEmpty) sessionId = id;
      }
    } catch (e) {
      _fail(Utils.errorMessage(e));
      return;
    }
    if (sessionId == null) {
      _fail('Session setup failed. Please try again.');
      return;
    }

    // Step 2: pay through the server (wallet all-or-nothing, else card).
    if (mounted) setState(() => _status = 'Processing payment…');
    final pay = await StripeService.payForSession(sessionId: sessionId);

    if (!pay.isPaid && pay.outcome != SessionPaymentOutcome.alreadyPaid) {
      // Not paid — release the pre-created session.
      try {
        await _sessionRepo.updateSessionStatus(sessionId, 'cancelled');
      } catch (_) {}
      if (pay.outcome == SessionPaymentOutcome.cancelled) {
        if (mounted) {
          setState(() {
            _paying = false;
            _status = null;
          });
        }
        Utils.toastMassage(pay.message);
        return;
      }
      _fail(pay.message);
      return;
    }

    // Refresh the session lists that are alive so the booking shows up.
    if (Get.isRegistered<HomeViewmodel>()) {
      Get.find<HomeViewmodel>().fetchSessions();
    }
    if (Get.isRegistered<SessionViewmodel>()) {
      Get.find<SessionViewmodel>().fetchSessions();
    }

    if (!mounted) return;
    Navigator.pop(context);
    final host = widget.hostContext;
    if (!host.mounted) return;
    switch (pay.outcome) {
      case SessionPaymentOutcome.paidWithWallet:
        _showResultDialog(
          host,
          title: 'Session booked!',
          body: pay.walletBalance != null
              ? 'Paid from your wallet. Remaining wallet balance: '
                  '${formatMoney(pay.walletBalance!, _quote?.currency)}.'
              : 'Paid from your wallet. Your session is confirmed.',
        );
        break;
      case SessionPaymentOutcome.paidByCard:
        _showResultDialog(
          host,
          title: 'Payment received',
          body: 'Your session will be confirmed as soon as the payment is '
              'processed. You\'ll find it under Sessions.',
        );
        break;
      default:
        _showResultDialog(host, title: 'Already paid', body: pay.message);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _paying = false;
      _status = null;
    });
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColor.primaryColor,
        title: Text('Could not book',
            style: GoogleFonts.dmSans(
                color: AppColor.white, fontWeight: FontWeight.w700)),
        content: Text(message,
            style: GoogleFonts.dmSans(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColor.red)),
          ),
        ],
      ),
    );
  }

  String _durationLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final q = _quote;
    final currency = q?.currency;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: Responsive.w(5),
        right: Responsive.w(5),
        top: Responsive.h(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _paying ? null : () => Navigator.pop(context),
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
              SizedBox(width: Responsive.textScaleFactor * 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Mentor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.textScaleFactor * 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.mentorName.trim().isNotEmpty)
                      Text(
                        widget.mentorName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: Responsive.textScaleFactor * 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(2)),
          const Divider(color: Colors.grey),
          SizedBox(height: Responsive.h(2)),
          _row('Session Type', '1-on-1'),
          SizedBox(height: Responsive.h(1)),
          _row('Duration', _durationLabel(widget.durationMinutes)),
          SizedBox(height: Responsive.h(1)),
          if (_loadingQuote)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(color: AppColor.red),
              ),
            )
          else if (_quoteError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _quoteError!,
                      style: GoogleFonts.dmSans(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadQuote,
                    child: const Text('Retry',
                        style: TextStyle(color: AppColor.red)),
                  ),
                ],
              ),
            )
          else if (q != null) ...[
            if (q.price != null) ...[
              _row('Price', formatMoney(q.price!, currency)),
              SizedBox(height: Responsive.h(1)),
            ],
            if (q.platformFee != null) ...[
              _row(
                q.platformFeePercent != null
                    ? 'Platform fee (${formatPercent(q.platformFeePercent!)}, included)'
                    : 'Platform fee (included)',
                formatMoney(q.platformFee!, currency),
              ),
              SizedBox(height: Responsive.h(1)),
            ],
            if (q.walletBalance != null) ...[
              _row('Wallet balance', formatMoney(q.walletBalance!, currency)),
              SizedBox(height: Responsive.h(1)),
            ],
            if (q.paidFromWallet)
              _row('Paid from wallet', formatMoney(q.walletApplied!, currency))
            else if (q.amountDue != null)
              _row('Charged to card', formatMoney(q.amountDue!, currency)),
            SizedBox(height: Responsive.h(1)),
            if (q.amountDue != null)
              _row('Amount due', formatMoney(q.amountDue!, currency),
                  bold: true),
          ],
          if (_status != null) ...[
            SizedBox(height: Responsive.h(1)),
            Text(
              _status!,
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12),
            ),
          ],
          SizedBox(height: Responsive.h(2)),
          // Booking needs a valid server quote first.
          if (q != null)
            AuthButton(
              buttontext: q.paidFromWallet
                  ? 'Book & pay from wallet'
                  : 'Proceed to Payment',
              onPress: _paying ? () {} : _book,
              loading: _paying,
            ),
          SizedBox(height: Responsive.h(2)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.textScaleFactor * 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white,
            fontSize: Responsive.textScaleFactor * (bold ? 14 : 12),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

void _showResultDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColor.primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icons/checkmark-circle-02.svg'),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: AppColor.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppColor.white, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: AppColor.red,
                ),
                child: Text(
                  'Got It',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColor.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
