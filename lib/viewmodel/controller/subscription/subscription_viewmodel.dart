import 'package:get/get.dart';
import 'package:toriino_todd/data/response/api_response.dart';
import 'package:toriino_todd/model/subscription/subscription_model.dart';
import 'package:toriino_todd/repository/subscription_repo.dart';
import 'package:toriino_todd/services/stripe_service.dart';
import 'package:toriino_todd/utils/utils.dart';

/// Presents the Stripe PaymentSheet; returns {success, cancelled?, message}.
typedef PaymentSheetPresenter = Future<Map<String, dynamic>> Function(
    String clientSecret);

enum CheckoutPhase {
  idle,

  /// POST /subscriptions in flight / PaymentSheet open.
  paying,

  /// Sheet succeeded; polling GET /subscriptions/me for premium == true.
  activating,

  /// Server confirmed premium.
  activated,

  /// Polling ended without premium — the webhook may still be processing.
  activationPending,
}

/// Plans + the caller's subscription state. Premium is only ever read from
/// GET /subscriptions/me; nothing is marked active locally.
class SubscriptionViewModel extends GetxController {
  SubscriptionViewModel({
    SubscriptionRepo? repo,
    PaymentSheetPresenter? presentSheet,
    this.pollInterval = const Duration(seconds: 2),
    this.pollAttempts = 15,
  })  : _repo = repo ?? SubscriptionRepo(),
        _presentSheet = presentSheet ?? StripeService.presentSubscriptionSheet;

  final SubscriptionRepo _repo;
  final PaymentSheetPresenter _presentSheet;
  final Duration pollInterval;
  final int pollAttempts;

  final rxMe = Rx<ApiResponse<SubscriptionStatus>>(ApiResponse.loading());
  final rxPlans =
      Rx<ApiResponse<SubscriptionPlansResponse>>(ApiResponse.loading());

  final phase = CheckoutPhase.idle.obs;

  /// planId currently being purchased (drives the button spinner).
  final busyPlanId = RxnString();
  final cancelling = false.obs;

  /// Last user-facing outcome (server messages shown as-is).
  final notice = RxnString();
  final noticeIsError = false.obs;

  bool get isPremium => rxMe.value.data?.premium == true;
  bool get isBusy =>
      busyPlanId.value != null ||
      cancelling.value ||
      phase.value == CheckoutPhase.activating;

  Future<void> fetchMe({bool silent = false}) async {
    if (!silent || rxMe.value.data == null) rxMe.value = ApiResponse.loading();
    try {
      rxMe.value = ApiResponse.success(await _repo.getMine());
    } catch (e) {
      if (!silent || rxMe.value.data == null) {
        rxMe.value = ApiResponse.error(Utils.errorMessage(e));
      }
    }
  }

  Future<void> fetchPlans({String? audience}) async {
    rxPlans.value = ApiResponse.loading();
    try {
      rxPlans.value =
          ApiResponse.success(await _repo.getPlans(audience: audience));
    } catch (e) {
      rxPlans.value = ApiResponse.error(Utils.errorMessage(e));
    }
  }

  Future<void> refreshAll({String? audience}) =>
      Future.wait([fetchMe(), fetchPlans(audience: audience)]);

  void _setNotice(String? message, {bool error = false}) {
    notice.value = message;
    noticeIsError.value = error;
  }

  Future<void> subscribe(SubscriptionPlan plan) async {
    if (isBusy) return;
    busyPlanId.value = plan.planId;
    phase.value = CheckoutPhase.paying;
    _setNotice(null);

    final SubscriptionCheckout checkout;
    try {
      checkout = await _repo.subscribe(plan.planId);
    } catch (e) {
      // 503 Stripe not configured / 403 wrong role / 404 not available /
      // 409 already subscribed — the server's own message.
      _finish(CheckoutPhase.idle, Utils.errorMessage(e), error: true);
      return;
    }

    final secret = checkout.clientSecret;
    if (secret == null) {
      _finish(CheckoutPhase.idle, 'Payment setup error: missing client secret',
          error: true);
      return;
    }

    final result = await _presentSheet(secret);
    if (isClosed) return;
    if (result['success'] != true) {
      _finish(
        CheckoutPhase.idle,
        result['message']?.toString() ?? 'Payment failed',
        error: result['cancelled'] != true,
      );
      return;
    }

    busyPlanId.value = null;
    phase.value = CheckoutPhase.activating;
    _setNotice('Payment received — activating your plan…');

    for (var i = 0; i < pollAttempts; i++) {
      await Future.delayed(pollInterval);
      if (isClosed) return;
      try {
        final me = await _repo.getMine();
        if (isClosed) return;
        rxMe.value = ApiResponse.success(me);
        if (me.premium) {
          _finish(CheckoutPhase.activated, 'Your plan is active.');
          return;
        }
      } catch (_) {
        // Keep polling; a transient failure is not an outcome.
      }
    }
    _finish(
      CheckoutPhase.activationPending,
      'Your payment was received and activation is being processed. '
      'Please check back shortly.',
    );
  }

  void _finish(CheckoutPhase p, String message, {bool error = false}) {
    if (isClosed) return;
    busyPlanId.value = null;
    phase.value = p;
    _setNotice(message, error: error);
  }

  Future<void> cancel() async {
    if (isBusy) return;
    cancelling.value = true;
    _setNotice(null);
    try {
      final msg = await _repo.cancel();
      if (isClosed) return;
      _setNotice(msg ?? 'Cancellation requested.');
    } catch (e) {
      if (isClosed) return;
      _setNotice(Utils.errorMessage(e), error: true);
    } finally {
      if (!isClosed) cancelling.value = false;
    }
    if (!isClosed) await fetchMe(silent: true);
  }
}
