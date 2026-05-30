import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

// ─── Entry ────────────────────────────────────────────────────────────────────

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

  void _goToQr(int amount) {
    setState(() {
      _amount = amount;
      _step = _DepositStep.qrCode;
    });
  }

  Future<void> _confirmDeposit() async {
    setState(() => _step = _DepositStep.processing);
    // TODO: gọi API POST /api/wallet/deposit
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _step = _DepositStep.success);
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
        _DepositStep.enterAmount => _EnterAmountScreen(
            key: const ValueKey('enter'),
            title: 'Nạp tiền',
            subtitle: 'Nhập số tiền muốn nạp vào ví',
            icon: Icons.savings_outlined,
            accentColor: const Color(0xFF3B82F6),
            onBack: () => Navigator.of(context).pop(),
            onNext: _goToQr,
            quickAmounts: const [50000, 100000, 200000, 500000, 1000000, 2000000],
          ),
        _DepositStep.qrCode => _QrCodeScreen(
            key: const ValueKey('qr'),
            amount: _amount,
            onBack: () => setState(() => _step = _DepositStep.enterAmount),
            onConfirm: _confirmDeposit,
          ),
        _DepositStep.processing => const _ProcessingScreen(
            key: ValueKey('processing'),
            message: 'Đang xác nhận thanh toán...',
          ),
        _DepositStep.success => _ResultScreen(
            key: const ValueKey('success'),
            isSuccess: true,
            title: 'Nạp tiền thành công!',
            subtitle: 'Số dư ví đã được cộng thêm.',
            amount: _amount,
            amountLabel: '+${_fmtAmount(_amount)}đ',
            amountColor: const Color(0xFF22C55E),
            onDone: () => Navigator.of(context).pop(true),
          ),
        _DepositStep.failure => _ResultScreen(
            key: const ValueKey('failure'),
            isSuccess: false,
            title: 'Nạp tiền thất bại',
            subtitle: 'Không xác nhận được giao dịch.\nVui lòng thử lại.',
            amount: _amount,
            amountLabel: _fmtAmount(_amount) + 'đ',
            amountColor: const Color(0xFFEF4444),
            onRetry: () => setState(() => _step = _DepositStep.enterAmount),
            onDone: () => Navigator.of(context).pop(false),
          ),
      },
    );
  }
}

// ─── Enter Amount ─────────────────────────────────────────────────────────────

class _EnterAmountScreen extends StatefulWidget {
  const _EnterAmountScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onBack,
    required this.onNext,
    required this.quickAmounts,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onBack;
  final ValueChanged<int> onNext;
  final List<int> quickAmounts;

  @override
  State<_EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<_EnterAmountScreen> {
  final _ctrl = TextEditingController();
  int _parsed = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onAmountChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    setState(() => _parsed = int.tryParse(digits) ?? 0);
  }

  void _selectQuick(int amount) {
    _ctrl.text = _fmtAmount(amount);
    setState(() => _parsed = amount);
  }

  bool get _valid => _parsed >= 10000;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: widget.onBack,
        ),
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon + subtitle
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.15),
                  border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Icon(widget.icon, color: accent, size: 30),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 28),

            // Amount input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2530),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _valid ? accent.withValues(alpha: 0.5) : const Color(0xFF2A3A4A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số tiền (VND)',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      color: _valid ? Colors.white : Colors.white70,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                      border: InputBorder.none,
                      suffixText: 'đ',
                      suffixStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onChanged: _onAmountChanged,
                  ),
                  if (_parsed > 0 && _parsed < 10000) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Tối thiểu 10.000đ',
                      style: TextStyle(color: const Color(0xFFEF4444), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick select
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.quickAmounts.map((amt) {
                return GestureDetector(
                  onTap: () => _selectQuick(amt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _parsed == amt
                          ? accent.withValues(alpha: 0.2)
                          : const Color(0xFF1A2530),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _parsed == amt
                            ? accent
                            : const Color(0xFF2A3A4A),
                      ),
                    ),
                    child: Text(
                      '+${_fmtAmount(amt)}đ',
                      style: TextStyle(
                        color: _parsed == amt ? accent : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _valid ? () => widget.onNext(_parsed) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: const Color(0xFF1E2E3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Tiếp tục',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
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
  });

  final int amount;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  // Thông tin tài khoản ngân hàng nhận nạp (mock — sẽ lấy từ API sau)
  static const _bankName = 'Vietcombank';
  static const _accountNumber = '1234567890';
  static const _accountHolder = 'CONG TY SOSBIKE';
  static const _transferNote = 'SOSBIKE NAP VI';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: onBack,
        ),
        title: const Text(
          'Quét mã QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2530),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.savings_outlined, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Số tiền nạp',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '+${_fmtAmount(amount)}đ',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // QR Placeholder
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Quét mã QR để thanh toán',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // QR visual (placeholder grid)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // Corner markers
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
                                  child: Text(
                                    'SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'QR sẽ tải từ API',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hoặc chuyển khoản thủ công',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bank info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2530),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A3A4A)),
              ),
              child: Column(
                children: [
                  _BankInfoRow(label: 'Ngân hàng', value: _bankName),
                  const Divider(color: Color(0xFF2A3A4A), height: 20),
                  _BankInfoRow(
                    label: 'Số tài khoản',
                    value: _accountNumber,
                    canCopy: true,
                  ),
                  const Divider(color: Color(0xFF2A3A4A), height: 20),
                  _BankInfoRow(label: 'Chủ tài khoản', value: _accountHolder),
                  const Divider(color: Color(0xFF2A3A4A), height: 20),
                  _BankInfoRow(
                    label: 'Số tiền',
                    value: '${_fmtAmount(amount)}đ',
                    valueColor: const Color(0xFF22C55E),
                  ),
                  const Divider(color: Color(0xFF2A3A4A), height: 20),
                  _BankInfoRow(
                    label: 'Nội dung CK',
                    value: '$_transferNote ${_fmtAmount(amount)}',
                    canCopy: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFFBBF24), size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sau khi chuyển khoản, nhấn "Tôi đã chuyển tiền" để xác nhận. Số dư sẽ được cộng trong vài phút.',
                      style: TextStyle(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Tôi đã chuyển tiền',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
              thickness: thickness,
            ),
          ),
        ),
      ));
    }
    return corners;
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.isTop,
    required this.isLeft,
    required this.color,
    required this.thickness,
  });

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
  const _BankInfoRow({
    required this.label,
    required this.value,
    this.canCopy = false,
    this.valueColor,
  });

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
          child: Text(
            label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép: $value'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, color: Color(0xFF3B82F6), size: 14),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _ProcessingScreen extends StatefulWidget {
  const _ProcessingScreen({super.key, required this.message});

  final String message;

  @override
  State<_ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<_ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.message,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng không tắt ứng dụng...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultScreen extends StatefulWidget {
  const _ResultScreen({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountLabel,
    required this.amountColor,
    this.onRetry,
    required this.onDone,
  });

  final bool isSuccess;
  final String title;
  final String subtitle;
  final int amount;
  final String amountLabel;
  final Color amountColor;
  final VoidCallback? onRetry;
  final VoidCallback onDone;

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isSuccess ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    final scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.25),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      color: iconColor,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: fade,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: fade,
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (widget.isSuccess)
                FadeTransition(
                  opacity: fade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2530),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số tiền',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                            ),
                            Text(
                              widget.amountLabel,
                              style: TextStyle(
                                color: widget.amountColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Thời gian',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                            ),
                            Text(
                              _nowLabel(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              FadeTransition(
                opacity: fade,
                child: Column(
                  children: [
                    if (!widget.isSuccess && widget.onRetry != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: widget.onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Thử lại',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: widget.onDone,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          widget.isSuccess ? 'Về trang ví' : 'Đóng',
                          style:
                              const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _nowLabel() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtAmount(int v) => v
    .toString()
    .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
