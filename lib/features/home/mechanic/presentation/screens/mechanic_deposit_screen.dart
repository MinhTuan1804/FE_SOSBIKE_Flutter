import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';
import 'mechanic_wallet_shared.dart';

/// Màn **Nạp tiền** vào ví SOSBIKE.
/// Flow: nhập số tiền → xem QR / thông tin chuyển khoản → kết quả.
class MechanicDepositScreen extends StatefulWidget {
  const MechanicDepositScreen({super.key, this.currentBalance = 0});

  final int currentBalance;

  @override
  State<MechanicDepositScreen> createState() => _MechanicDepositScreenState();
}

enum _DepositStep { enterAmount, qrCode, processing, success, failure }

class _MechanicDepositScreenState extends State<MechanicDepositScreen> {
  _DepositStep _step = _DepositStep.enterAmount;
  int _amount = 0;
  String? _paymentId;
  String? _qrContent;
  String? _checkoutUrl;
  String? _paymentCode;
  String? _bankBin;
  String? _bankAccountNumber;
  String? _bankAccountName;

  // Auto-polling: tự động check trạng thái mỗi 5 giây khi đang ở màn QR
  Timer? _pollingTimer;
  bool _isPolling = false;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted || _paymentId == null || _isPolling) return;
      if (_step != _DepositStep.qrCode) {
        _pollingTimer?.cancel();
        return;
      }
      _isPolling = true;
      try {
        final provider = context.read<MechanicWalletProvider>();
        final status = await provider.checkPaymentStatus(_paymentId!);
        if (!mounted) return;
        if (status?.toUpperCase() == 'PAID' || status?.toUpperCase() == 'SUCCESS') {
          _pollingTimer?.cancel();
          setState(() => _step = _DepositStep.success);
        }
      } finally {
        _isPolling = false;
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _startDepositFlow(int amount) async {
    setState(() {
      _amount = amount;
      _step = _DepositStep.processing;
    });

    final provider = context.read<MechanicWalletProvider>();
    final result = await provider.createPaymentIntent(amount);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _paymentId = result['paymentId'] as String?;
        _qrContent = result['qrContent'] as String?;
        _checkoutUrl = result['checkoutUrl'] as String?;
        _paymentCode = result['paymentCode'] as String?;
        _bankBin = result['bankBin'] as String?;
        _bankAccountNumber = result['bankAccountNumber'] as String?;
        _bankAccountName = result['bankAccountName'] as String?;
        _step = _DepositStep.qrCode;
      });
      // Bắt đầu auto-polling sau khi có payment
      _startPolling();
    } else {
      setState(() {
        _step = _DepositStep.failure;
      });
    }
  }

  Future<void> _confirmDeposit() async {
    if (_paymentId == null) {
      setState(() => _step = _DepositStep.failure);
      return;
    }

    _stopPolling();
    setState(() => _step = _DepositStep.processing);

    final provider = context.read<MechanicWalletProvider>();
    final status = await provider.checkPaymentStatus(_paymentId!);

    if (!mounted) return;

    if (status?.toUpperCase() == 'PAID' || status?.toUpperCase() == 'SUCCESS') {
      setState(() => _step = _DepositStep.success);
    } else {
      setState(() => _step = _DepositStep.qrCode);
      // Tiếp tục polling sau khi quay lại màn QR
      _startPolling();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hệ thống chưa nhận được thanh toán. Đang tự động kiểm tra...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: switch (_step) {
        _DepositStep.enterAmount => WalletEnterAmountScreen(
            key: const ValueKey('enter'),
            title: 'Nạp tiền',
            subtitle: 'Nạp vào ví SOSBIKE',
            icon: Icons.savings_outlined,
            accentColor: AppColors.primary,
            onBack: () => Navigator.of(context).pop(),
            onNext: _startDepositFlow,
            quickAmounts: const [50000, 100000, 200000, 500000, 1000000, 2000000],
          ),
        _DepositStep.qrCode => _QrCodeScreen(
            key: const ValueKey('qr'),
            amount: _amount,
            qrContent: _qrContent,
            checkoutUrl: _checkoutUrl,
            paymentCode: _paymentCode,
            bankBin: _bankBin,
            bankAccountNumber: _bankAccountNumber,
            bankAccountName: _bankAccountName,
            onBack: () => setState(() => _step = _DepositStep.enterAmount),
            onConfirm: _confirmDeposit,
          ),
        _DepositStep.processing => const WalletProcessingScreen(
            key: ValueKey('processing'),
            message: 'Đang xử lý...',
          ),
        _DepositStep.success => WalletResultScreen(
            key: const ValueKey('success'),
            isSuccess: true,
            title: 'Nạp tiền thành công!',
            subtitle: 'Số dư ví đã được cộng thêm.',
            amount: _amount,
            amountLabel: '+${fmtWalletAmount(_amount)}đ',
            amountColor: const Color(0xFF22C55E),
            onDone: () => Navigator.of(context).pop(true),
          ),
        _DepositStep.failure => WalletResultScreen(
            key: const ValueKey('failure'),
            isSuccess: false,
            title: 'Nạp tiền thất bại',
            subtitle: context.read<MechanicWalletProvider>().errorMessage ?? 'Không khởi tạo được giao dịch.\nVui lòng thử lại.',
            amount: _amount,
            amountLabel: '${fmtWalletAmount(_amount)}đ',
            amountColor: AppColors.primary,
            onRetry: () => setState(() => _step = _DepositStep.enterAmount),
            onDone: () => Navigator.of(context).pop(false),
          ),
      },
    );
  }
}

// ─── QR Code Screen ───────────────────────────────────────────────────────────

class _QrCodeScreen extends StatelessWidget {
  const _QrCodeScreen({
    super.key,
    required this.amount,
    required this.onBack,
    required this.onConfirm,
    this.qrContent,
    this.checkoutUrl,
    this.paymentCode,
    this.bankBin,
    this.bankAccountNumber,
    this.bankAccountName,
  });

  final int amount;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  final String? qrContent;
  final String? checkoutUrl;
  final String? paymentCode;
  final String? bankBin;
  final String? bankAccountNumber;
  final String? bankAccountName;

  @override
  Widget build(BuildContext context) {
    final String? qrData = (qrContent != null && qrContent!.isNotEmpty) ? qrContent : checkoutUrl;
    final hasQrData = qrData != null && qrData.isNotEmpty;
    final hasPayOS = checkoutUrl != null && checkoutUrl!.startsWith('http');

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: Column(
        children: [
          // ── Gradient header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7A1010), AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const Expanded(
                          child: Text(
                            'Quét mã QR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.savings_outlined,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Số tiền nạp',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 11)),
                                Text('+${fmtWalletAmount(amount)}đ',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WalletSectionTitle(label: 'Mã QR thanh toán'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Text('Quét mã QR để thanh toán',
                            style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
                        const SizedBox(height: 14),
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.primary, width: 3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: hasQrData
                                ? Image.network(
                                    'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(qrData)}',
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(child: Icon(Icons.error_outline, color: AppColors.primary));
                                    },
                                  )
                                : Stack(
                                    children: [
                                      ..._qrCorners(),
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Center(
                                                child: Text('SOS',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 13)),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text('QR sẽ tải từ API',
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 9)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (hasPayOS) ...[
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(checkoutUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                            label: const Text('Mở link thanh toán PayOS', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(hasQrData ? 'Nhấn nút để mở ứng dụng ngân hàng/web' : 'Hoặc chuyển khoản thủ công',
                            style:
                                TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const WalletSectionTitle(label: 'Thông tin chuyển khoản'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1010),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      children: [
                        if (bankBin != null) ...[
                          _BankInfoRow(label: 'Ngân hàng (BIN)', value: bankBin!),
                          const Divider(color: Color(0xFF3A1A1A), height: 20),
                        ],
                        if (bankAccountNumber != null) ...[
                          _BankInfoRow(
                              label: 'Số tài khoản',
                              value: bankAccountNumber!,
                              canCopy: true),
                          const Divider(color: Color(0xFF3A1A1A), height: 20),
                        ],
                        if (bankAccountName != null) ...[
                          _BankInfoRow(
                              label: 'Chủ tài khoản', value: bankAccountName!),
                          const Divider(color: Color(0xFF3A1A1A), height: 20),
                        ],
                        _BankInfoRow(
                            label: 'Số tiền',
                            value: '${fmtWalletAmount(amount)}đ',
                            valueColor: const Color(0xFF22C55E)),
                        const Divider(color: Color(0xFF3A1A1A), height: 20),
                        _BankInfoRow(
                            label: 'Nội dung CK',
                            value: paymentCode != null ? 'SOSBIKE $paymentCode' : 'SOSBIKE NAP VI',
                            canCopy: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Color(0xFFFBBF24), size: 15),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sau khi chuyển khoản, nhấn "Tôi đã chuyển tiền" để xác nhận. Số dư sẽ được cộng trong vài phút.',
                            style: TextStyle(
                                color: const Color(0xFFFBBF24)
                                    .withValues(alpha: 0.9),
                                fontSize: 11.5,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Fixed bottom button ──
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0A0A),
          border: Border(top: BorderSide(color: Color(0xFF2A1010))),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Tôi đã chuyển tiền',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ),
      ),
    );
  }

  static List<Widget> _qrCorners() {
    const size = 24.0;
    const thickness = 3.0;
    const color = AppColors.primary;
    final corners = <Widget>[];
    for (final pos in ['TL', 'TR', 'BL', 'BR']) {
      final isTop = pos.startsWith('T');
      final isLeft = pos.endsWith('L');
      corners.add(Positioned(
        top: isTop ? 8 : null,
        bottom: isTop ? null : 8,
        left: isLeft ? 8 : null,
        right: isLeft ? null : 8,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
                isTop: isTop,
                isLeft: isLeft,
                color: color,
                thickness: thickness),
          ),
        ),
      ));
    }
    return corners;
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter(
      {required this.isTop,
      required this.isLeft,
      required this.color,
      required this.thickness});

  final bool isTop;
  final bool isLeft;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    canvas.drawLine(Offset(x, y), Offset(isLeft ? size.width : 0, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, isTop ? size.height : 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BankInfoRow extends StatelessWidget {
  const _BankInfoRow(
      {required this.label,
      required this.value,
      this.canCopy = false,
      this.valueColor});

  final String label;
  final String value;
  final bool canCopy;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: valueColor ?? Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700)),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Đã sao chép: $value'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: const Icon(Icons.copy_rounded,
                      color: AppColors.primary, size: 14),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
