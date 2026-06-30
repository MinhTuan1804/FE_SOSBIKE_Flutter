import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_repair_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_repair_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_title_bar.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_order_stepper.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/widgets/mechanic_flow_home_button.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/rescue_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';

class MechanicPaymentCompleteView extends StatefulWidget {
  const MechanicPaymentCompleteView({
    super.key,
    required this.orderId,
    required this.onFinish,
    required this.onGoHome,
  });

  final String orderId;
  final VoidCallback onFinish;
  final VoidCallback onGoHome;

  @override
  State<MechanicPaymentCompleteView> createState() => _MechanicPaymentCompleteViewState();
}

class _MechanicPaymentCompleteViewState extends State<MechanicPaymentCompleteView> {
  static final _currencyFormat = NumberFormat('#,##0', 'vi_VN');

  String _selectedMethod = 'CASH'; // 'CASH', 'TRANSFER'
  OrderQuoteDto? _quote;
  bool _isLoading = true;
  bool _isSettling = false;
  bool _isSettled = false;
  String? _errorMessage;

  // Receipt details returned from API after settlement
  double _grossAmount = 0.0;
  double _commissionAmount = 0.0;
  double _netAmount = 0.0;
  double _walletBalanceAfter = 0.0;

  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrderQuote();
    context.read<RescueProvider>().addListener(_onRescueStatusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final rescue = context.read<RescueProvider>();
        if (rescue.activeOrderStatus?.toUpperCase() == 'PAID') {
          if (!_isSettled) {
            _handleAutoSettledOnline();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    try {
      context.read<RescueProvider>().removeListener(_onRescueStatusChanged);
    } catch (_) {}
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onRescueStatusChanged() {
    if (!mounted) return;
    final rescue = context.read<RescueProvider>();
    if (rescue.activeOrderStatus?.toUpperCase() == 'PAID') {
      if (!_isSettled) {
        _handleAutoSettledOnline();
      }
    }
  }

  Future<void> _handleAutoSettledOnline() async {
    setState(() {
      _isSettling = true;
      _errorMessage = null;
    });

    final repairProvider = context.read<MechanicRepairProvider>();
    final walletProvider = context.read<MechanicWalletProvider>();
    final rescueProvider = context.read<RescueProvider>();

    if (_quote == null) {
      final quote = await repairProvider.getQuote(widget.orderId);
      if (quote != null) {
        _quote = quote;
      }
    }

    final gross = _quote?.totalAmount ?? 0.0;
    final commission = gross * 0.2;
    final net = gross - commission;

    await walletProvider.load(force: true);

    if (mounted) {
      setState(() {
        _isSettling = false;
        _isSettled = true;
        _selectedMethod = 'TRANSFER';
        _grossAmount = gross;
        _commissionAmount = commission;
        _netAmount = net;
        _walletBalanceAfter = walletProvider.data?.balance.toDouble() ?? 0.0;
      });

      // Clear active order state
      await repairProvider.clearActiveOrderState();

      // Clear rescue status
      rescueProvider.clearActiveOrderStatus();
    }
  }

  Future<void> _loadOrderQuote() async {
    if (widget.orderId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<MechanicRepairProvider>();
    final quote = await provider.getQuote(widget.orderId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (quote != null) {
          _quote = quote;
          _amountCtrl.text = quote.totalAmount.round().toString();
        } else {
          _errorMessage = provider.errorMessage ?? 'Không lấy được thông tin hóa đơn.';
        }
      });
    }
  }

  Future<void> _confirmSettleCash() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? (_quote?.totalAmount ?? 0.0);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền mặt hợp lệ.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.monetization_on_rounded, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Xác nhận tiền mặt', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Khách đã thanh toán ${_currencyFormat.format(amount)}đ tiền mặt cho bạn?',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _settleCashFlow(amount);
    }
  }

  Future<void> _settleCashFlow(double amount) async {
    setState(() {
      _isSettling = true;
      _errorMessage = null;
    });

    final provider = context.read<MechanicRepairProvider>();
    final result = await provider.settleCashOrder(amount);

    if (mounted) {
      setState(() {
        _isSettling = false;
        if (result != null) {
          _isSettled = true;
          _grossAmount = amount;
          _commissionAmount = (result['commissionAmount'] as num?)?.toDouble() ?? (amount * 0.2);
          _netAmount = _grossAmount - _commissionAmount;
          _walletBalanceAfter = (result['walletNewBalance'] as num?)?.toDouble() ?? 0.0;
        } else {
          _errorMessage = provider.errorMessage ?? 'Quyết toán tiền mặt thất bại.';
        }
      });
    }
  }

  Widget _buildMethodButton({
    required String method,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final active = _selectedMethod == method;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: active ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _isSettled ? null : () => setState(() => _selectedMethod = method),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? color : const Color(0xFFE5E7EB),
                  width: active ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: active ? color : const Color(0xFF6B7280), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color: active ? color : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMaxH = constraints.maxHeight * kMechanicFlowSheetRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MechanicFlowTitleBar(
              title: _isSettled ? 'Thành công' : 'Thanh toán đơn',
              includeTopSafeArea: true,
              onGoHome: widget.onGoHome,
            ),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF9FAFB),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _errorMessage != null && !_isSettled
                        ? _buildErrorView()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: _isSettled ? _buildReceiptView() : _buildPaymentSelectorView(),
                            ),
                          ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: sheetMaxH),
              child: MechanicOrderFlowSheetBody(
                title: _isSettled ? 'Quyết toán thành công!' : 'Kiểm tra thanh toán.',
                activeStep: 3,
                subtitle: _isSettled
                    ? 'Đơn hàng cứu hộ đã hoàn thành quyết toán và lưu vào sổ quỹ.'
                    : 'Hãy hướng dẫn khách thanh toán hoặc xác nhận nhận tiền mặt bên trên.',
                action: Center(
                  child: Material(
                    color: _isSettled ? const Color(0xFF16A34A) : const Color(0xFF9CA3AF),
                    shape: const CircleBorder(),
                    elevation: _isSettled ? 8 : 0,
                    shadowColor: const Color(0xFF16A34A).withValues(alpha: 0.5),
                    child: InkWell(
                      onTap: _isSettled ? widget.onFinish : null,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 54),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrderQuote,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSelectorView() {
    final quoteTotal = _quote?.totalAmount ?? 0.0;
    return Column(
      key: const ValueKey('selector_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total box
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              const Text(
                'Tổng tiền khách cần trả:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                '${_currencyFormat.format(quoteTotal)}đ',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Chọn phương thức thanh toán:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildMethodButton(
              method: 'CASH',
              label: 'Tiền mặt',
              icon: Icons.payments_rounded,
              color: const Color(0xFF16A34A),
            ),
            _buildMethodButton(
              method: 'TRANSFER',
              label: 'Chuyển khoản',
              icon: Icons.account_balance_rounded,
              color: const Color(0xFF2563EB),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Selected method details area
        if (_selectedMethod == 'CASH') _buildCashSection(quoteTotal),
        if (_selectedMethod == 'TRANSFER') _buildTransferSection(),
      ],
    );
  }

  Widget _buildCashSection(double quoteTotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Xác nhận số tiền mặt đã nhận:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  suffixText: 'VNĐ',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSettling ? null : _confirmSettleCash,
                icon: _isSettling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text(
                  'Xác nhận đã nhận tiền',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransferSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Icon(
                Icons.qr_code_2_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Chờ khách hàng thanh toán',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 8),
          Text(
            'Khách hàng quét mã QR PayOS hoặc chuyển khoản ngân hàng trên ứng dụng của họ.\n'
            'Hệ thống sẽ tự động quyết toán và cộng tiền vào ví của bạn ngay khi giao dịch thành công.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 24),
          TextButton.icon(
            onPressed: _isLoading ? null : _loadOrderQuote,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Kiểm tra lại trạng thái',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptView() {
    return Container(
      key: const ValueKey('receipt_view'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 54),
                SizedBox(height: 8),
                Text(
                  'Đơn hoàn thành',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
          const _DashedDivider(),
          _receiptRow(
            'Mã đơn hàng',
            widget.orderId.length >= 8
                ? '#${widget.orderId.substring(0, 8).toUpperCase()}'
                : '#${widget.orderId.toUpperCase()}',
            isBold: true,
          ),
          _receiptRow('Phương thức', _selectedMethod == 'CASH' ? 'Tiền mặt' : _selectedMethod == 'QR' ? 'QR PayOS' : 'Chuyển khoản'),
          const _DashedDivider(),
          const Text(
            'Chi tiết doanh thu:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          _receiptRow('Tiền khách trả', '+${_currencyFormat.format(_grossAmount)}đ', color: const Color(0xFF16A34A)),
          _receiptRow('Phí hoa hồng Platform (20%)', '-${_currencyFormat.format(_commissionAmount)}đ', color: const Color(0xFFEF4444)),
          const _DashedDivider(),
          _receiptRow(
            'Ví thợ ghi nhận (thực nhận)',
            '+${_currencyFormat.format(_netAmount)}đ',
            isBold: true,
            color: const Color(0xFF16A34A),
            fontSize: 15,
          ),
          const _DashedDivider(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Số dư ví hiện tại:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                ),
                Text(
                  '${_currencyFormat.format(_walletBalanceAfter)}đ',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, color: const Color(0xFF6B7280)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const dashWidth = 6.0;
          const dashSpace = 4.0;
          final dashCount = (width / (dashWidth + dashSpace)).floor();
          return Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return const SizedBox(
                width: dashWidth,
                height: 1.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFD1D5DB)),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
