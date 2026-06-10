import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _TrackingViewState extends State<TrackingView> with SingleTickerProviderStateMixin {
  String _selectedPaymentMethod = 'CASH'; // 'CASH' or 'BANK_TRANSFER'
  bool _paymentIntentCreated = false;
  bool _isProcessing = false;
  
  // Dynamic rotation for repairing wrench icon
  double _wrenchRotation = 0.0;
  Timer? _wrenchTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuoteIfNeeded();
    });
    // Wrench rotation loop for repairing state animation
    _wrenchTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _wrenchRotation += 0.2;
        });
      }
    });
  }

  @override
  void dispose() {
    _wrenchTimer?.cancel();
    super.dispose();
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

  // 1. ACCEPTED (Thá»£ Ä‘ang di chuyá»ƒn)
  Widget _buildAcceptedView(BuildContext context, RescueProvider rescue) {
    final feeRate = context.watch<AppConfigProvider>().config.platform.defaultPlatformFeeRate;
    final match = rescue.matchedMechanic ?? {};
    final mechanicName = match['mechanicName'] as String? ?? 'Thá»£ cá»©u há»™';
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
          badgeText: 'CÃ¡ch $etaMins phÃºt',
        ),
        const SizedBox(height: 20),
        const Text(
          'Thá»£ Ä‘ang di chuyá»ƒn Ä‘áº¿n chá»— báº¡n',
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
              'ÄÃ¡nh giÃ¡ $rating',
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
        _buildPriceRow('PhÃ­ di chuyá»ƒn (${distanceKm.toStringAsFixed(1)} km)', '$formattedFeeÄ‘'),
        const SizedBox(height: 8),
        _buildPriceRow('PhÃ­ ná»n táº£ng', '$feeRate%'),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'Há»§y Ä‘áº·t thá»£',
          onPressed: () => _showCancelConfirmation(context),
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        ),
      ],
    );
  }

  // 2. ARRIVED (Thá»£ Ä‘Ã£ Ä‘áº¿n nÆ¡i - Äang kiá»ƒm tra xe)
  Widget _buildArrivedView(BuildContext context, RescueProvider rescue) {
    final feeRate = context.watch<AppConfigProvider>().config.platform.defaultPlatformFeeRate;
    final match = rescue.matchedMechanic ?? {};
    final mechanicName = match['mechanicName'] as String? ?? 'Thá»£ cá»©u há»™';
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
          badgeText: 'ÄÃ£ Ä‘áº¿n nÆ¡i',
          badgeColor: Colors.green,
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              const Text(
                'Äang kiá»ƒm tra tÃ¬nh tráº¡ng xe',
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
                  'Thá»£ Ä‘ang thá»±c hiá»‡n kiá»ƒm tra ká»¹ thuáº­t Ä‘á»ƒ láº­p danh sÃ¡ch lá»—i vÃ  bÃ¡o giÃ¡ chi tiáº¿t cho báº¡n.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 18),
              
              // Diagnostic UI Code representing physical checks
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.analytics_outlined, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Há»† THá»NG CHáº¨N ÄOÃN SOSBIKE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.blue[900],
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDiagnosticItem('Kiá»ƒm tra tá»•ng quan Ä‘á»™ng cÆ¡', true),
                    _buildDiagnosticItem('Kiá»ƒm tra Ã¡p suáº¥t lá»‘p & sÄƒm xe', true),
                    _buildDiagnosticItem('Kiá»ƒm tra há»‡ thá»‘ng phanh trÆ°á»›c/sau', true),
                    _buildDiagnosticItem('Äo Ä‘iá»‡n Ã¡p bÃ¬nh áº¯c-quy', false, isPulsing: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),
        _buildPriceRow('PhÃ­ di chuyá»ƒn', '$formattedFeeÄ‘'),
        const SizedBox(height: 8),
        _buildPriceRow('PhÃ­ ná»n táº£ng', '$feeRate%'),
      ],
    );
  }

  Widget _buildDiagnosticItem(String text, bool isCompleted, {bool isPulsing = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : (isPulsing ? Colors.blue : Colors.grey),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isPulsing ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? Colors.black87 : (isPulsing ? Colors.blue[900] : Colors.grey[600]),
              ),
            ),
          ),
          if (isPulsing)
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(Colors.blue)),
            ),
        ],
      ),
    );
  }

  // 3. QUOTING (Thá»£ gá»­i bÃ¡o giÃ¡ -> KhÃ¡ch hÃ ng chá»n Ä‘á»“ng Ã½)
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
    final membershipDiscountAmount = quote?['membershipDiscountAmount'] as num? ?? 0;
    final totalAmount = quote?['totalAmount'] as num? ?? 0;
    final lines = (quote?['lines'] as List?) ?? [];
    final orderId = rescue.currentOrderId ?? '';

    final formattedTotal = NumberFormat('#,##0', 'vi_VN').format(totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BÃ¡o giÃ¡ chi tiáº¿t tá»« thá»£',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Vui lÃ²ng xÃ¡c nháº­n Ä‘á»“ng Ã½ cÃ¡c dá»‹ch vá»¥ vÃ  linh kiá»‡n bÃªn dÆ°á»›i Ä‘á»ƒ thá»£ tiáº¿n hÃ nh sá»­a chá»¯a.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        
        // Quote Details Box
        _buildQuoteLinesCard(lines, travelFee, nightSurcharge, membershipDiscountAmount),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tá»•ng chi phÃ­ sá»­a chá»¯a',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '$formattedTotalÄ‘',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: _isProcessing ? 'Äang gá»­i xÃ¡c nháº­n...' : 'XÃ¡c nháº­n & Äá»“ng Ã½ sá»­a chá»¯a',
          onPressed: _isProcessing ? null : () => _handleApproveQuote(rescue, orderId),
          backgroundColor: Colors.green,
          textColor: Colors.white,
        ),
      ],
    );
  }

  // 4. REPAIRING (Äang sá»­a chá»¯a)
  Widget _buildRepairingView(BuildContext context, RescueProvider rescue) {
    final quote = rescue.activeQuote;
    final totalAmount = quote?['totalAmount'] as num? ?? 0;
    final formattedTotal = NumberFormat('#,##0', 'vi_VN').format(totalAmount);
    final lines = (quote?['lines'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Äang sá»­a chá»¯a xe mÃ¡y',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thá»£ Ä‘ang thá»±c hiá»‡n sá»­a chá»¯a xe mÃ¡y cá»§a báº¡n theo bÃ¡o giÃ¡ Ä‘Ã£ duyá»‡t.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        
        // Repair Progress UI Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withValues(alpha: 0.15)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: _wrenchRotation,
                    child: const Icon(Icons.build_circle_outlined, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TIáº¾N TRÃŒNH Sá»¬A CHá»®A',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.green[900],
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...lines.map((l) {
                final name = l['itemName'] as String? ?? 'Sá»­a chá»¯a';
                final isPart = l['itemType'] == 'PART';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        isPart ? Icons.settings : Icons.build,
                        color: Colors.green[700],
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 16),
        _buildPriceRow('Tá»•ng cá»™ng hÃ³a Ä‘Æ¡n', '$formattedTotalÄ‘', isBoldValue: true),
      ],
    );
  }

  // 5. COMPLETED (HoÃ n thÃ nh sá»­a chá»¯a -> Thanh toÃ¡n)
  Widget _buildCompletedView(BuildContext context, RescueProvider rescue) {
    final quote = rescue.activeQuote;
    final totalAmount = quote?['totalAmount'] as num? ?? 0;
    final formattedTotal = NumberFormat('#,##0', 'vi_VN').format(totalAmount);
    final orderId = rescue.currentOrderId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thanh toÃ¡n hÃ³a Ä‘Æ¡n cá»©u há»™',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thá»£ Ä‘Ã£ hoÃ n thÃ nh cÃ´ng viá»‡c. HÃ£y thanh toÃ¡n Ä‘á»ƒ hoÃ n táº¥t.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sá»‘ tiá»n cáº§n thanh toÃ¡n',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              '$formattedTotalÄ‘',
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
            'Chá»n phÆ°Æ¡ng thá»©c thanh toÃ¡n',
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
                          'Tiá»n máº·t',
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
                          'Chuyá»ƒn khoáº£n',
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
            text: _isProcessing ? 'Äang xá»­ lÃ½...' : 'Tiáº¿n hÃ nh thanh toÃ¡n',
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
              text: _isProcessing ? 'Äang xÃ¡c nháº­n...' : 'TÃ´i Ä‘Ã£ chuyá»ƒn khoáº£n thÃ nh cÃ´ng',
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
                    'Äang chá» Ä‘Æ°a tiá»n máº·t',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'HÃ£y gá»­i tiá»n máº·t trá»±c tiáº¿p cho thá»£ sá»­a xe. Sau khi giao tiá»n, báº¥m nÃºt xÃ¡c nháº­n bÃªn dÆ°á»›i.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton(
              text: _isProcessing ? 'Äang xÃ¡c nháº­n...' : 'XÃ¡c nháº­n Ä‘Ã£ tráº£ tiá»n',
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
            child: const Text('Thay Ä‘á»•i phÆ°Æ¡ng thá»©c thanh toÃ¡n', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ],
    );
  }

  // 6. PAID (ÄÃ£ thanh toÃ¡n -> ThÃ nh cÃ´ng - Code UI hoÃ n chá»‰nh)
  Widget _buildPaidView(BuildContext context, RescueProvider rescue) {
    final quote = rescue.activeQuote ?? {};
    final totalAmount = quote['totalAmount'] as num? ?? 0;
    final formattedTotal = NumberFormat('#,##0', 'vi_VN').format(totalAmount);
    final match = rescue.matchedMechanic ?? {};
    final mechanicName = match['mechanicName'] as String? ?? 'Thá»£ cá»©u há»™';
    
    final intent = rescue.paymentIntent ?? {};
    final txCode = intent['paymentCode'] as String? ?? 'ORD-COMPLETED';
    final methodLabel = _selectedPaymentMethod == 'CASH' ? 'Tiá»n máº·t' : 'Chuyá»ƒn khoáº£n';
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    return Column(
      children: [
        // Glowing Success Badge (Replacing PNG mockup)
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withValues(alpha: 0.1),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Center(
            child: Icon(Icons.check_circle, size: 52, color: Colors.green),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Cá»©u há»™ thÃ nh cÃ´ng!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'ÄÆ¡n cá»©u há»™ cá»§a báº¡n Ä‘Ã£ Ä‘Æ°á»£c thanh toÃ¡n vÃ  hoÃ n táº¥t thÃ nh cÃ´ng. Cáº£m Æ¡n báº¡n Ä‘Ã£ sá»­ dá»¥ng dá»‹ch vá»¥ cá»§a SOSBike!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 18),
        
        // Transaction Summary Card
        Container(
          width: double.infinity,
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
                'CHI TIáº¾T HÃ“A ÄÆ N',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
              ),
              const SizedBox(height: 10),
              _buildSummaryField('MÃ£ giao dá»‹ch', txCode),
              _buildSummaryField('Thá»£ sá»­a chá»¯a', mechanicName),
              _buildSummaryField('PhÆ°Æ¡ng thá»©c', methodLabel),
              _buildSummaryField('Thá»i gian', dateStr),
              const Divider(height: 20, color: Color(0xFFEBEBEB)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tá»•ng thanh toÃ¡n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('$formattedTotalÄ‘', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          text: 'Trá»Ÿ vá» trang chá»§',
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

  Widget _buildSummaryField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  // Common Header/Card Helper Widgets
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

  Widget _buildQuoteLinesCard(List<dynamic> lines, num travelFee, num nightSurcharge, num membershipDiscountAmount) {
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
            'Chi tiáº¿t cÃ¡c háº¡ng má»¥c:',
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
            String typeName = 'Dá»‹ch vá»¥';
            if (type == 'PART') {
              typeColor = Colors.orange;
              typeName = 'Phá»¥ tÃ¹ng';
            } else if (type == 'LABOR') {
              typeColor = Colors.purple;
              typeName = 'CÃ´ng thá»£';
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
                        Text('${qty}x ${currencyFormatter.format(price)}Ä‘', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('${currencyFormatter.format(total)}Ä‘', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
          const Divider(height: 20, color: Color(0xFFEBEBEB)),
          _buildQuoteSummaryRow('PhÃ­ di chuyá»ƒn', '${currencyFormatter.format(travelFee)}Ä‘'),
          if (nightSurcharge > 0) ...[
            const SizedBox(height: 6),
            _buildQuoteSummaryRow('Phá»¥ phÃ­ Ä‘Ãªm muá»™n', '${currencyFormatter.format(nightSurcharge)}Ä‘'),
          ],
          if (membershipDiscountAmount > 0) ...[
            const SizedBox(height: 6),
      _buildQuoteSummaryRow('Nền tảng tài trợ', '-${currencyFormatter.format(membershipDiscountAmount)}đ'),
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

    final bankName = intent['bankBin'] as String? ?? 'MB Bank (QuÃ¢n Äá»™i)';
    final accountName = intent['bankAccountName'] as String? ?? 'SOSBIKE SERVICE CO.';
    final accountNumber = intent['bankAccountNumber'] as String? ?? '8888 8888 8888';
    final qrContent = intent['qrContent'] as String?;

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
            'Chuyá»ƒn khoáº£n NgÃ¢n hÃ ng',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
          ),
          const SizedBox(height: 12),
          // QR Image / Card
          Container(
            height: 150,
            width: 150,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: qrContent != null && qrContent.trim().isNotEmpty
                ? Image.network(
                    'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(qrContent)}',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2_rounded, size: 40, color: AppColors.primary),
                            const SizedBox(height: 4),
                            const Text(
                              'Lá»—i táº£i QR',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                        ),
                      );
                    },
                  )
                : Icon(Icons.qr_code, size: 100, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          _buildBankInfoRow('NgÃ¢n hÃ ng', bankName),
          _buildBankInfoRow('Chá»§ tÃ i khoáº£n', accountName),
          _buildBankInfoRow('Sá»‘ tÃ i khoáº£n', accountNumber, isCopyable: true),
          _buildBankInfoRow('Sá»‘ tiá»n', '$formattedAmtÄ‘', isHighlight: true),
          _buildBankInfoRow('Ná»™i dung chuyá»ƒn khoáº£n', code, isCopyable: true),
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
          GestureDetector(
            onTap: isCopyable
                ? () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ÄÃ£ sao chÃ©p: $value'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            child: Row(
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

  // Core Actions
  Future<void> _handleApproveQuote(RescueProvider rescue, String orderId) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      await rescue.approveOrderQuote(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ÄÃ£ xÃ¡c nháº­n Ä‘á»“ng Ã½ bÃ¡o giÃ¡. Thá»£ Ä‘ang tiáº¿n hÃ nh sá»­a xe.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lá»—i xÃ¡c nháº­n bÃ¡o giÃ¡: $e'), backgroundColor: Colors.red),
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

  Future<void> _handlePaymentStart(RescueProvider rescue, String orderId) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final intent = await rescue.createRescueOrderPayment(orderId, _selectedPaymentMethod);
      if (intent != null) {
        if (_selectedPaymentMethod == 'CASH') {
          // Cash payment does not require user confirmation.
          // Confirm payment immediately!
          final paymentId = intent['paymentId'] as String?;
          if (paymentId != null) {
            await rescue.confirmRescueOrderPayment(paymentId, 'CASH_MOCK_TX');
          }
        } else {
          setState(() {
            _paymentIntentCreated = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lá»—i táº¡o thanh toÃ¡n: $e'), backgroundColor: Colors.red),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lá»—i xÃ¡c nháº­n thanh toÃ¡n: $e'), backgroundColor: Colors.red),
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
          title: const Text('XÃ¡c nháº­n há»§y'),
          content: const Text('Báº¡n cÃ³ cháº¯c cháº¯n muá»‘n há»§y Ä‘áº·t thá»£ cá»©u há»™ nÃ y khÃ´ng?'),
          actions: <Widget>[
            TextButton(
              child: const Text('KhÃ´ng'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('CÃ³, há»§y Ä‘áº·t thá»£', style: TextStyle(color: Colors.red)),
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

