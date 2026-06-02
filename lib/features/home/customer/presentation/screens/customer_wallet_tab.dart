import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/membership/data/models/membership_models.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/providers/membership_provider.dart';
import 'package:fe_moblie_flutter/features/membership/presentation/screens/membership_screen.dart';

/// Tab **Thanh toán** khách — gói thành viên (QR), không ví trừ tiền / lịch sử giao dịch.
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
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: membership.load,
              child: membership.isLoading && subscription == null && membership.plans.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                      children: [
                        _MembershipStatusCard(
                          subscription: subscription,
                          dateFormat: _dateFormat,
                        ),
                        const SizedBox(height: 12),
                        _MembershipPlansBanner(
                          onTap: () => _openMembership(context),
                        ),
                        const SizedBox(height: 14),
                        const _QrPaymentNotice(),
                        if (membership.errorMessage != null &&
                            membership.errorMessage!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            membership.errorMessage!,
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _openMembership(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => const MembershipScreen(),
        fullscreenDialog: true,
      ),
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

class _QrPaymentNotice extends StatelessWidget {
  const _QrPaymentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thanh toán gói thành viên',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text(
                  'Sau khi chọn gói, hệ thống hiển thị mã QR và nội dung chuyển khoản. '
                  'Khách không dùng ví SOSBIKE để trừ phí gói (khác thợ sửa xe).',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
