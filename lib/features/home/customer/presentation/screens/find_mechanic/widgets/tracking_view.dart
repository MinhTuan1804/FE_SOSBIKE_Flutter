import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/config/app_config_provider.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:intl/intl.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({
    super.key,
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  String _selectedPaymentMethod = 'CASH'; // 'CASH' or 'BANK_TRANSFER'
  bool _paymentIntentCreated = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuoteIfNeeded();
    });
  }

  void _fetchQuoteIfNeeded() {
    final rescue = context.read<RescueProvider>();
    final status = rescue.activeOrderStatus;
    final orderId = rescue.currentOrderId;
    if (orderId != null &&
        (status == 'QUOTING' ||
            status == 'REPAIRING' ||
            status == 'COMPLETED' ||
            status == 'PAID')) {
      rescue.fetchOrderQuote(orderId).catchError((e) {
        debugPrint('Error pre-fetching quote: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rescue = context.watch<RescueProvider>();
    final status = rescue.activeOrderStatus ?? 'ACCEPTED';

    // Auto-fetch if status updates in UI
    if (rescue.activeQuote == null &&
        (status == 'QUOTING' ||
            status == 'REPAIRING' ||
            status == 'COMPLETED' ||
            status == 'PAID')) {
      _fetchQuoteIfNeeded();
    }

    return Column(
      children: [
        const Spacer(),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Indicator
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Views based on Order Status
              switch (status) {
                'ACCEPTED' => _buildAcceptedView(context, rescue),
                'ARRIVED' => _buildArrivedView(context, rescue),
                'QUOTING' => _buildQuotingView(context, rescue),
                'REPAIRING' => _buildRepairingView(context, rescue),
                'COMPLETED' => _buildCompletedView(context, rescue),
                'PAID' => _buildPaidView(context, rescue),
                _ => _buildAcceptedView(context, rescue), // Fallback
              },
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  // 1. ACCEPTED (Thợ đang di chuyển)
  Widget _buildAcceptedView(BuildContext context, RescueProvider rescue) {
    final feeRate = context.watch<AppConfigProvider>().config.platform.defaultPlatformFeeRate;
    final match = rescue.matchedMechanic ?? {};
    final mechanicName = match['mechanicName'] as String? ?? 'Thợ cứu hộ';
    final vehicleModel = match['vehicleModel'] as String? ?? 'N/A';
    final licensePlate = match['licensePlate'] as String? ?? 'N/A';
    final rating = match['mechanicRating']?.toString() ?? '5.0';
    final distanceKm = rescue.goongDistanceKm ?? (match['distanceKm'] != null ? (match['distanceKm'] as num).toDouble() : 2.5);
    final travelFee = match['travelFee'] as num? ?? 15000;
    final formattedFee = NumberFormat('#,##0', 'vi_VN').format(travelFee);
    final etaMins = rescue.goongDurationMins ?? (distanceKm * 4).toInt().clamp(2, 60);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMechanicProfileCard(
          avatarUrl: match['mechanicAvatarUrl'] as String?,
          name: mechanicName,
          subtitle: '$vehicleModel - $licensePlate',
          badgeText: 'Cách $etaMins phút',
        ),
        const SizedBox(height: 20),
        const Text(
          'Thợ đang di chuyển đến chỗ bạn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Đánh giá $rating',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(width: 6),
            ...List.generate(
              5,
              (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),
        _buildPriceRow('Phí di chuyển (${distanceKm.toStringAsFixed(1)} km)', '$formattedFeeđ'),
        const SizedBox(height: 8),
        _buildPriceRow('Phí nền tảng', '$feeRate%'),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'Hủy đặt thợ',
          onPressed: () => _showCancelConfirmation(context),
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        ),
      ],
    );
  }

  // 2. ARRIVED (Thợ đã đến nơi)
  Widget _buildArrivedView(BuildContext context, RescueProvider rescue) {
    final feeRate = context.watch<AppConfigProvider>().config.platform.defaultPlatformFeeRate;
    final match = rescue.matchedMechanic ?? {};
    final mechanicName = match['mechanicName'] as String? ?? 'Thợ cứu hộ';
    final vehicleModel = match['vehicleModel'] as String? ?? 'N/A';
    final licensePlate = match['licensePlate'] as String? ?? 'N/A';
    final travelFee = match['travelFee'] as num? ?? 15000;
    final formattedFee = NumberFormat('#,##0', 'vi_VN').format(travelFee);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMechanicProfileCard(
          avatarUrl: match['mechanicAvatarUrl'] as String?,
          name: mechanicName,
          subtitle: '$vehicleModel - $licensePlate',
          badgeText: 'Đã đến nơi',
          badgeColor: Colors.green,
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/screen/Tìm thợ.png',
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.motorcycle, size: 64, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang kiểm tra tình trạng xe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Thợ đang kiểm tra kỹ thuật xe máy của bạn để lên danh sách dịch vụ và báo giá chi tiết.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),
        _buildPriceRow('Phí di chuyển', '$formattedFeeđ'),
        const SizedBox(height: 8),
        _buildPriceRow('Phí nền tảng', '$feeRate%'),
      ],
    );
  }

  // 3. QUOTING (Thợ gửi báo giá)
  Widget _buildQuotingView(BuildContext context, RescueProvider rescue) {
    if (rescue.isLoading && rescue.activeQuote == null) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    final quote = rescue.activeQuote;
    final travelFee = quote?['travelFee'] as num? ?? 0;
    final nightSurcharge = quote?['nightSurcharge'] as num? ?? 0;
    final totalAmount = quote?['totalAmount'] as num? ?? 0;
    final lines = (quote?['lines'] as List?) ?? [];

    final formattedTotal = NumberFormat('#,##0', 'vi_VN').format(totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Báo giá từ thợ sửa xe',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vui lòng thảo luận trực tiếp với thợ trước khi thợ tiến hành sửa chữa.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        
        // Quote Details Box
        _buildQuoteLinesCard(lines, travelFee, nightSurcharge),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng chi phí ước tính',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '$formattedTotalđ',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[200]!),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.amber[800], size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đợi thợ bấm bắt đầu sửa sau khi bạn đồng ý.',
                  style: TextStyle(
                    color: Colors.amber[900],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. REPAIRING (Đang sửa chữa)
  Widget _buildRepairingView(BuildContext context, RescueProvider rescue) {
    final quote = rescue.activeQuote;
    final totalAmount = quote?['totalAmount'] as num? ?? 0;
    final formattedTotal = NumberFormat('#,##0', 'vi_VN').format(totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đang sửa chữa xe máy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thợ đang tiến hành sửa chữa theo các hạng mục đã thỏa thuận.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/screen/Tìm thợ-1.png',
                height: 130,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.build, size: 64, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đang sửa chữa...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),
        _buildPriceRow('Tổng cộng hóa đơn', '$formattedTotalđ', isBoldValue: true),
      ],
    );
  }

  // 5. COMPLETED (Hoàn thành sửa chữa -> Thanh toán)
  Widget _buildCompletedView(BuildContext context, RescueProvider rescue) {
    final quote = rescue.activeQuote;
    final totalAmount = quote?['totalAmount'] as num? ?? 0;
    final formattedTotal = NumberFormat('#,##0', 'vi_VN').format(totalAmount);
    final orderId = rescue.currentOrderId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thanh toán hóa đơn cứu hộ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thợ đã hoàn thành công việc. Hãy thanh toán để hoàn tất.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Số tiền cần thanh toán',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '$formattedTotalđ',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (!_paymentIntentCreated) ...[
          const Text(
            'Chọn phương thức thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'CASH';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedPaymentMethod == 'CASH'
                            ? AppColors.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: _selectedPaymentMethod == 'CASH'
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: _selectedPaymentMethod == 'CASH'
                              ? AppColors.primary
                              : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tiền mặt',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedPaymentMethod == 'CASH'
                                ? AppColors.primary
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMethod = 'BANK_TRANSFER';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedPaymentMethod == 'BANK_TRANSFER'
                            ? AppColors.primary
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: _selectedPaymentMethod == 'BANK_TRANSFER'
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(
                          Icons.qr_code_scanner_outlined,
                          color: _selectedPaymentMethod == 'BANK_TRANSFER'
                              ? AppColors.primary
                              : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Chuyển khoản',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _selectedPaymentMethod == 'BANK_TRANSFER'
                                ? AppColors.primary
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            text: _isProcessing ? 'Đang xử lý...' : 'Tiến hành thanh toán',
            onPressed: _isProcessing ? null : () => _handlePaymentStart(rescue, orderId),
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
          ),
        ] else ...[
          // Payment intent created
          if (_selectedPaymentMethod == 'BANK_TRANSFER') ...[
            _buildBankTransferDetailsCard(rescue),
            const SizedBox(height: 20),
            _buildPrimaryButton(
              text: _isProcessing ? 'Đang xác nhận...' : 'Tôi đã chuyển khoản thành công',
              onPressed: _isProcessing ? null : () => _handleConfirmPayment(rescue),
              backgroundColor: Colors.green,
              textColor: Colors.white,
            ),
          ] else ...[
            // Cash flow waiting confirmation
            Container(
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber[200]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.payment, size: 40, color: Colors.amber[800]),
                  const SizedBox(height: 10),
                  Text(
                    'Đang chờ đưa tiền mặt',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Hãy gửi tiền mặt trực tiếp cho thợ sửa xe. Sau khi giao tiền, bấm nút xác nhận bên dưới.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton(
              text: _isProcessing ? 'Đang xác nhận...' : 'Xác nhận đã trả tiền',
              onPressed: _isProcessing ? null : () => _handleConfirmPayment(rescue),
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentIntentCreated = false;
              });
            },
            child: const Text('Thay đổi phương thức thanh toán', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ],
    );
  }

  // 6. PAID (Đã thanh toán -> Hoàn thành)
  Widget _buildPaidView(BuildContext context, RescueProvider rescue) {
    return Column(
      children: [
        Image.asset(
          'assets/images/screen/HoanThanh.png',
          height: 180,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.check_circle_outline, size: 90, color: Colors.green),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Cứu hộ thành công!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Đơn cứu hộ của bạn đã được thanh toán và hoàn tất thành công. An tâm tiếp tục hành trình!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'Trở về trang chủ',
          onPressed: () {
            rescue.clearActiveOrderStatus();
            Navigator.of(context).pop();
          },
          backgroundColor: Colors.green,
          textColor: Colors.white,
        ),
      ],
    );
  }

  // Helper Widget Creators
  Widget _buildMechanicProfileCard({
    required String? avatarUrl,
    required String name,
    required String subtitle,
    required String badgeText,
    Color badgeColor = Colors.orange,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    )
                  : Image.asset(
                      'assets/images/main/avatar_placeholder.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(1.5),
                      child: const Icon(Icons.check, color: Colors.blue, size: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteLinesCard(List<dynamic> lines, num travelFee, num nightSurcharge) {
    final currencyFormatter = NumberFormat('#,##0', 'vi_VN');

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết các hạng mục:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ...lines.map((l) {
            final name = l['itemName'] as String? ?? 'N/A';
            final qty = l['quantity'] as num? ?? 1;
            final price = l['unitPrice'] as num? ?? 0;
            final total = l['totalPrice'] as num? ?? (price * qty);
            final type = l['itemType'] as String? ?? 'SERVICE';

            Color typeColor = Colors.blue;
            String typeName = 'Dịch vụ';
            if (type == 'PART') {
              typeColor = Colors.orange;
              typeName = 'Phụ tùng';
            } else if (type == 'LABOR') {
              typeColor = Colors.purple;
              typeName = 'Công thợ';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      typeName,
                      style: TextStyle(color: typeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${qty}x ${currencyFormatter.format(price)}đ', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('${currencyFormatter.format(total)}đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
          const Divider(height: 20, color: Color(0xFFEBEBEB)),
          _buildQuoteSummaryRow('Phí di chuyển', '${currencyFormatter.format(travelFee)}đ'),
          if (nightSurcharge > 0) ...[
            const SizedBox(height: 6),
            _buildQuoteSummaryRow('Phụ phí đêm muộn', '${currencyFormatter.format(nightSurcharge)}đ'),
          ],
        ],
      ),
    );
  }

  Widget _buildBankTransferDetailsCard(RescueProvider rescue) {
    final intent = rescue.paymentIntent ?? {};
    final amount = intent['amount'] as num? ?? 0;
    final code = intent['paymentCode'] as String? ?? 'ORD';
    final formattedAmt = NumberFormat('#,##0', 'vi_VN').format(amount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Chuyển khoản Ngân hàng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
          ),
          const SizedBox(height: 12),
          // Mock QR Image / Card
          Container(
            height: 130,
            width: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Icon(Icons.qr_code, size: 100, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          _buildBankInfoRow('Ngân hàng', 'MB Bank (Quân Đội)'),
          _buildBankInfoRow('Chủ tài khoản', 'SOSBIKE SERVICE CO.'),
          _buildBankInfoRow('Số tài khoản', '8888 8888 8888'),
          _buildBankInfoRow('Số tiền', '$formattedAmtđ', isHighlight: true),
          _buildBankInfoRow('Nội dung chuyển khoản', code, isCopyable: true),
        ],
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value, {bool isHighlight = false, bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? AppColors.primary : Colors.black87,
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 4),
                const Icon(Icons.copy, size: 12, color: Colors.grey),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSummaryRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }

  Widget _buildPriceRow(String label, String val, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          val,
          style: TextStyle(
            color: isBoldValue ? Colors.black : AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  // Core Payment Actions
  Future<void> _handlePaymentStart(RescueProvider rescue, String orderId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final intent = await rescue.createRescueOrderPayment(orderId, _selectedPaymentMethod);
      if (intent != null) {
        setState(() {
          _paymentIntentCreated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo thanh toán: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleConfirmPayment(RescueProvider rescue) async {
    final intent = rescue.paymentIntent;
    if (intent == null) return;

    final paymentId = intent['paymentId'] as String?;
    if (paymentId == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final txId = _selectedPaymentMethod == 'CASH' ? 'CASH_MOCK_TX' : 'BANK_TRANSFER_MOCK_TX';
      await rescue.confirmRescueOrderPayment(paymentId, txId);
      // Wait for SignalR to update the status to PAID automatically, 
      // but just in case, we can manually check if it was marked as paid.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xác nhận thanh toán: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận hủy'),
          content: const Text('Bạn có chắc chắn muốn hủy đặt thợ cứu hộ này không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Không'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Có, hủy đặt thợ', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                widget.onCancel(); // Return to dashboard
              },
            ),
          ],
        );
      },
    );
  }
}
