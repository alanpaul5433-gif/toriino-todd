import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:toriino_todd/data/response/status.dart';
import 'package:toriino_todd/model/subscription/subscription_model.dart';
import 'package:toriino_todd/resources/colors/app_colors.dart';
import 'package:toriino_todd/utils/money.dart';
import 'package:toriino_todd/viewmodel/controller/subscription/subscription_viewmodel.dart';

/// Shared subscription screen for every role.
///
/// * Current state comes only from GET /subscriptions/me.
/// * Plans come from GET /subscriptions/plans (caller's role unless
///   [audience] is given). Prices are formatted with utils/money.dart and
///   savings are shown only when the server sent them.
/// * Subscribe → POST /subscriptions → PaymentSheet → poll /subscriptions/me.
/// * Cancel → POST /subscriptions/cancel → refresh /subscriptions/me.
class PlansView extends StatefulWidget {
  const PlansView({
    super.key,
    this.audience,
    this.onContinue,
    this.continueLabel = 'Skip',
  });

  /// Optional ?audience= override; defaults to the caller's role server-side.
  final String? audience;

  /// When set (onboarding), a top-right action moves on instead of a back
  /// arrow, e.g. to the role's bottom nav bar.
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  late final SubscriptionViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = Get.isRegistered<SubscriptionViewModel>()
        ? Get.find<SubscriptionViewModel>()
        : Get.put(SubscriptionViewModel());
    vm.notice.value = null;
    vm.refreshAll(audience: widget.audience);
  }

  TextStyle _style(double size,
          {FontWeight weight = FontWeight.w400, Color color = Colors.white}) =>
      GoogleFonts.dmSans(color: color, fontSize: size, fontWeight: weight);

  BoxDecoration get _card => BoxDecoration(
        color: AppColor.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColor.primaryColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => vm.refreshAll(audience: widget.audience),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  if (canPop && widget.onContinue == null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  Expanded(
                    child: Text('Subscription',
                        style: _style(18, weight: FontWeight.w600)),
                  ),
                  if (widget.onContinue != null)
                    Obx(() => TextButton(
                          onPressed: vm.isBusy ? null : widget.onContinue,
                          child: Text(widget.continueLabel,
                              style: _style(14)),
                        )),
                ],
              ),
              const SizedBox(height: 12),
              _notice(),
              _statusSection(),
              const SizedBox(height: 20),
              Text('Plans', style: _style(14, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              _plansSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notice() {
    return Obx(() {
      final msg = vm.notice.value;
      if (msg == null) return const SizedBox.shrink();
      final activating = vm.phase.value == CheckoutPhase.activating;
      return Container(
        key: const Key('subscription_notice'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: vm.noticeIsError.value
              ? AppColor.red.withValues(alpha: 0.25)
              : AppColor.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (activating) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(msg, style: _style(12))),
          ],
        ),
      );
    });
  }

  String _date(DateTime d) => DateFormat.yMMMd().format(d);

  Widget _statusSection() {
    return Obx(() {
      final me = vm.rxMe.value;
      final plans = vm.rxPlans.value.data;
      Widget child;
      switch (me.status) {
        case Status.error:
          child = _errorBox(me.massage ?? 'Could not load your subscription',
              () => vm.fetchMe());
          break;
        case Status.success:
          final s = me.data!;
          final planName = plans?.planById(s.planId)?.name ?? s.planId;
          final end = s.currentPeriodEnd;
          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.premium ? 'Premium active' : 'Your plan',
                  style: _style(14, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                s.hasSubscription && planName != null
                    ? '$planName — ${s.statusLabel}'
                    : s.statusLabel,
                style: _style(12),
              ),
              if (s.hasSubscription && end != null) ...[
                const SizedBox(height: 4),
                Text(
                  s.cancelAtPeriodEnd
                      ? 'Ends on ${_date(end)}'
                      : (s.premium
                          ? 'Renews on ${_date(end)}'
                          : 'Period ends ${_date(end)}'),
                  style: _style(11,
                      color: AppColor.white.withValues(alpha: 0.75)),
                ),
              ],
              if (s.canCancel) ...[
                const SizedBox(height: 12),
                Obx(() => _pillButton(
                      key: const Key('subscription_cancel'),
                      label: 'Cancel subscription',
                      busy: vm.cancelling.value,
                      color: AppColor.white.withValues(alpha: 0.20),
                      onTap: vm.isBusy ? null : _confirmCancel,
                    )),
              ],
            ],
          );
          break;
        default:
          child = const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _card,
        child: child,
      );
    });
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text(
            'Your plan stays active until the end of the current paid period.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep plan')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel subscription')),
        ],
      ),
    );
    if (ok == true) await vm.cancel();
  }

  Widget _plansSection() {
    return Obx(() {
      final state = vm.rxPlans.value;
      switch (state.status) {
        case Status.error:
          return _errorBox(state.massage ?? 'Could not load plans',
              () => vm.fetchPlans(audience: widget.audience));
        case Status.success:
          final data = state.data!;
          if (data.comingSoon) {
            return Container(
              key: const Key('plans_coming_soon'),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _card,
              child: Column(
                children: [
                  Text('Plans coming soon',
                      style: _style(16, weight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Subscription plans are not available yet. Check back later.',
                    textAlign: TextAlign.center,
                    style: _style(12),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              for (final p in data.plans) ...[
                _planCard(p, data),
                const SizedBox(height: 12),
              ],
            ],
          );
        default:
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
      }
    });
  }

  String? _periodLabel(int? months) {
    if (months == null) return null;
    if (months == 1) return 'per month';
    if (months == 12) return 'per year';
    return 'per $months months';
  }

  String? _savingsLabel(SubscriptionPlan p, SubscriptionPlansResponse data) {
    final s = p.savings;
    if (s == null) return null;
    final parts = <String>[
      if (s.percent != null && s.percent! > 0) 'Save ${formatPercent(s.percent!)}',
      if (s.amount != null && s.amount! > 0)
        '${s.percent != null && s.percent! > 0 ? '' : 'Save '}'
            '${formatMoney(s.amount!, p.currency)}',
    ];
    if (parts.isEmpty) return null;
    var label = parts.length == 2 ? '${parts[0]} (${parts[1]})' : parts[0];
    final compared = data.planById(s.comparedTo)?.name;
    if (compared != null) label = '$label vs $compared';
    return label;
  }

  Widget _planCard(SubscriptionPlan p, SubscriptionPlansResponse data) {
    final period = _periodLabel(p.months);
    final savings = _savingsLabel(p, data);
    return Container(
      key: Key('plan_${p.planId}'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(p.name,
                    style: _style(14, weight: FontWeight.w600)),
              ),
              if (p.price != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatMoney(p.price!, p.currency),
                        style: _style(16, weight: FontWeight.w700)),
                    if (period != null)
                      Text(period,
                          style: _style(11,
                              color: AppColor.white.withValues(alpha: 0.75))),
                  ],
                ),
            ],
          ),
          if (savings != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColor.red.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(savings, style: _style(11, weight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 12),
          Obx(() {
            final me = vm.rxMe.value.data;
            if (me != null && me.premium) {
              return Text(
                me.planId == p.planId
                    ? 'Your current plan'
                    : 'You already have an active plan',
                style: _style(12, weight: FontWeight.w600),
              );
            }
            final activating = vm.phase.value == CheckoutPhase.activating;
            return _pillButton(
              key: Key('subscribe_${p.planId}'),
              label: 'Subscribe',
              busy: vm.busyPlanId.value == p.planId,
              color: AppColor.red,
              onTap: (vm.isBusy || activating || me == null)
                  ? null
                  : () => vm.subscribe(p),
            );
          }),
        ],
      ),
    );
  }

  Widget _pillButton({
    Key? key,
    required String label,
    required bool busy,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: busy ? null : onTap,
      child: Opacity(
        opacity: onTap == null && !busy ? 0.5 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
          ),
          child: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(label, style: _style(14, weight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _errorBox(String message, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _card,
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: _style(12)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: _style(14, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
