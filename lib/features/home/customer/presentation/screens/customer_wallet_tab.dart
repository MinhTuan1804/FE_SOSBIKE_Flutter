import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/membership/data/models/membership_models.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/providers/membership_provider.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/screens/membership_screen.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/screens/customer_subscription_checkout_screen.dart';

/// Tab Thanh toán - hiển thị thông tin gói thành viên của khách hàng
class CustomerWalletTab extends StatefulWidget {
  const CustomerWalletTab({super.key});

  @override
  State<CustomerWalletTab> createState() => _CustomerWalletTabState();
}

class _CustomerWalletTabState extends State<CustomerWalletTab> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MembershipProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final membership = context.watch<MembershipProvider>();
    final subscription = membership.currentSubscription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 0),
          child: Text(
            'Thanh toán',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: membership.load,
            child: membership.isLoading && subscription == null && membership.plans.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                    children: [
                      _MembershipStatusCard(
                        subscription: subscription,
                        dateFormat: _dateFormat,
                      ),
                      if (membership.pendingSession != null) ...[
                        const SizedBox(height: 12),
                        _PendingPaymentBanner(
                          session: membership.pendingSession!,
                          onContinue: () async {
                            final plans = membership.plans;
                            CustomerMembershipPlan? targetPlan;
                            for (final p in plans) {
                              if (p.planId == membership.pendingSession!.planId) {
                                targetPlan = p;
                                break;
                              }
                            }
                            if (targetPlan == null) {
                              targetPlan = CustomerMembershipPlan(
                                planId: membership.pendingSession!.planId,
                                name: membership.pendingSession!.planName,
                                targetAudience: 'B2C',
                                price: membership.pendingSession!.price,
                                durationDays: 30,
                                billingCycle: 'MONTH',
                                isFree: false,
                                isCurrentPlan: false,
                                benefits: const [],
                              );
                            }

                            final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerSubscriptionCheckoutScreen(
                                  plan: targetPlan!,
                                  intent: membership.pendingSession!.intent,
                                  autoRenew: membership.pendingSession!.autoRenew,
                                  createdAt: membership.pendingSession!.createdAt,
                                ),
                              ),
                            );
                            if (context.mounted) {
                              context.read<MembershipProvider>().load();
                            }
                          },
                          onCancel: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: const Text('Hủy giao dịch', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                content: const Text('Bạn có chắc muốn hủy bỏ giao dịch đang chờ thanh toán này không?', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Đóng', style: TextStyle(color: Colors.white54)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                    child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await membership.clearPendingSession();
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      _MembershipPlansBanner(
                        onTap: () => _openMembership(context),
                      ),
                      if (membership.errorMessage != null &&
                          membership.errorMessage!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          membership.errorMessage!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _openMembership(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MembershipScreen()),
    );
  }
}

class _MembershipStatusCard extends StatelessWidget {
  const _MembershipStatusCard({
    required this.subscription,
    required this.dateFormat,
  });

  final CustomerSubscription? subscription;
  final DateFormat dateFormat;

  bool get _isActive {
    if (subscription == null) return false;
    return subscription!.endDate.isAfter(DateTime.now()) &&
        subscription!.status.toUpperCase() != 'EXPIRED';
  }

  @override
  Widget build(BuildContext context) {
    final active = _isActive;
    final planName = subscription?.planName.trim().isNotEmpty == true
        ? subscription!.planName
        : 'Chưa có gói';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE83838), Color(0xFFB81818), Color(0xFF8E1212)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Gói thành viên',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  active ? 'Đang dùng' : 'Chưa kích hoạt',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          if (active && subscription != null) ...[
            const SizedBox(height: 8),
            Text(
              'Hết hạn: ${dateFormat.format(subscription!.endDate.toLocal())}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subscription!.autoRenew)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tự gia hạn: Bật',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Khách hàng thanh toán gói qua mã QR — không trừ số dư ví.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembershipPlansBanner extends StatelessWidget {
  const _MembershipPlansBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF7A1010),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD54F), size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xem & đăng ký gói',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Thanh toán bằng QR / chuyển khoản',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingPaymentBanner extends StatelessWidget {
  const _PendingPaymentBanner({
    required this.session,
    required this.onContinue,
    required this.onCancel,
  });

  final PendingPaymentSession session;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  String _formatMoney(double value) {
    final number = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < number.length; i++) {
      final remaining = number.length - i;
      buffer.write(number[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.pending_actions_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIAO DỊCH CHƯA HOÀN TẤT',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Đang chờ thanh toán...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white60,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói: ${session.planName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Số tiền: ${_formatMoney(session.price)}đ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(
                    'Thanh toán tiếp',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
