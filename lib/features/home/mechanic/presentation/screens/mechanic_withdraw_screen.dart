import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'mechanic_deposit_screen.dart'
    show _EnterAmountScreen, _ProcessingScreen, _ResultScreen, _fmtAmount;

// ─── Entry ────────────────────────────────────────────────────────────────────

/// Màn **Rút tiền** về tài khoản ngân hàng.
/// Flow: nhập số tiền → xác nhận TK ngân hàng → nhập OTP → kết quả.
class MechanicWithdrawScreen extends StatefulWidget {
  const MechanicWithdrawScreen({super.key, this.currentBalance = 0});

  final int currentBalance;

  @override
  State<MechanicWithdrawScreen> createState() => _MechanicWithdrawScreenState();
}

enum _WithdrawStep { enterAmount, confirmBank, otp, processing, success, failure }

class _MechanicWithdrawScreenState extends State<MechanicWithdrawScreen> {
  _WithdrawStep _step = _WithdrawStep.enterAmount;
  int _amount = 0;

  void _goToBank(int amount) => setState(() {
        _amount = amount;
        _step = _WithdrawStep.confirmBank;
      });

  void _goToOtp() => setState(() => _step = _WithdrawStep.otp);

  Future<void> _confirmOtp() async {
    setState(() => _step = _WithdrawStep.processing);
    // TODO: gọi API POST /api/wallet/withdraw
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _step = _WithdrawStep.success);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final bankName = profile?.wallet?.bankName ?? '';
    final bankAccount = profile?.wallet?.bankAccountNumber ?? '';
    final bankHolder = profile?.wallet?.bankAccountHolder ?? '';

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
        _WithdrawStep.enterAmount => _EnterAmountScreen(
            key: const ValueKey('enter'),
            title: 'Rút tiền',
            subtitle: 'Nhập số tiền muốn rút về tài khoản ngân hàng',
            icon: Icons.payments_outlined,
            accentColor: const Color(0xFF10B981),
            onBack: () => Navigator.of(context).pop(),
            onNext: _goToBank,
            quickAmounts: const [100000, 200000, 500000, 1000000, 2000000, 5000000],
          ),
        _WithdrawStep.confirmBank => _ConfirmBankScreen(
            key: const ValueKey('bank'),
            amount: _amount,
            bankName: bankName,
            bankAccount: bankAccount,
            bankHolder: bankHolder,
            balance: widget.currentBalance,
            onBack: () => setState(() => _step = _WithdrawStep.enterAmount),
            onConfirm: _goToOtp,
          ),
        _WithdrawStep.otp => _OtpScreen(
            key: const ValueKey('otp'),
            amount: _amount,
            onBack: () => setState(() => _step = _WithdrawStep.confirmBank),
            onConfirm: _confirmOtp,
          ),
        _WithdrawStep.processing => const _ProcessingScreen(
            key: ValueKey('processing'),
            message: 'Đang xử lý yêu cầu rút tiền...',
          ),
        _WithdrawStep.success => _ResultScreen(
            key: const ValueKey('success'),
            isSuccess: true,
            title: 'Rút tiền thành công!',
            subtitle: 'Tiền đang được chuyển về tài khoản của bạn.',
            amount: _amount,
            amountLabel: '-${_fmtAmount(_amount)}đ',
            amountColor: const Color(0xFF10B981),
            onDone: () => Navigator.of(context).pop(true),
          ),
        _WithdrawStep.failure => _ResultScreen(
            key: const ValueKey('failure'),
            isSuccess: false,
            title: 'Rút tiền thất bại',
            subtitle: 'Không thể xử lý yêu cầu.\nVui lòng kiểm tra và thử lại.',
            amount: _amount,
            amountLabel: _fmtAmount(_amount) + 'đ',
            amountColor: const Color(0xFFEF4444),
            onRetry: () => setState(() => _step = _WithdrawStep.enterAmount),
            onDone: () => Navigator.of(context).pop(false),
          ),
      },
    );
  }
}

// ─── Confirm Bank ─────────────────────────────────────────────────────────────

class _ConfirmBankScreen extends StatelessWidget {
  const _ConfirmBankScreen({
    super.key,
    required this.amount,
    required this.bankName,
    required this.bankAccount,
    required this.bankHolder,
    required this.balance,
    required this.onBack,
    required this.onConfirm,
  });

  final int amount;
  final String bankName;
  final String bankAccount;
  final String bankHolder;
  final int balance;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  bool get _hasBankInfo => bankName.isNotEmpty && bankAccount.isNotEmpty;
  bool get _sufficient => balance >= amount;

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
          'Xác nhận tài khoản',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Số tiền rút',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '-${_fmtAmount(amount)}đ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Số dư hiện tại',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
                      ),
                      Text(
                        '${_fmtAmount(balance)}đ',
                        style: TextStyle(
                          color: _sufficient
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bank account info
            const _SectionHeader(label: 'Tài khoản nhận tiền'),
            const SizedBox(height: 10),

            if (_hasBankInfo)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2530),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.account_balance_rounded,
                      label: 'Ngân hàng',
                      value: bankName,
                    ),
                    const Divider(color: Color(0xFF2A3A4A), height: 18),
                    _InfoRow(
                      icon: Icons.credit_card_rounded,
                      label: 'Số tài khoản',
                      value: bankAccount,
                    ),
                    const Divider(color: Color(0xFF2A3A4A), height: 18),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Chủ tài khoản',
                      value: bankHolder.isNotEmpty ? bankHolder : '---',
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2530),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFBBF24), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bạn chưa liên kết tài khoản ngân hàng.\nVào hồ sơ để thêm thông tin ngân hàng.',
                        style: TextStyle(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_sufficient && _hasBankInfo) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Số dư không đủ để rút ${_fmtAmount(amount)}đ.',
                        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Order summary
            const _SectionHeader(label: 'Tóm tắt giao dịch'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2530),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _SummaryRow(label: 'Số tiền rút', value: '${_fmtAmount(amount)}đ'),
                  const SizedBox(height: 6),
                  _SummaryRow(label: 'Phí giao dịch', value: 'Miễn phí'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Color(0xFF2A3A4A)),
                  ),
                  _SummaryRow(
                    label: 'Thực nhận',
                    value: '${_fmtAmount(amount)}đ',
                    isBold: true,
                    valueColor: const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: (_hasBankInfo && _sufficient) ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor: const Color(0xFF1E2E3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Tiếp tục',
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
}

// ─── OTP Screen ───────────────────────────────────────────────────────────────

class _OtpScreen extends StatefulWidget {
  const _OtpScreen({
    super.key,
    required this.amount,
    required this.onBack,
    required this.onConfirm,
  });

  final int amount;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  State<_OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<_OtpScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool get _complete => _ctrls.every((c) => c.text.isNotEmpty);

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onDigit(int index, String value) {
    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onBackspace(int index) {
    if (_ctrls[index].text.isEmpty && index > 0) {
      _ctrls[index - 1].clear();
      _nodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Xác nhận OTP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFF10B981), size: 28),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhập mã OTP',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Mã OTP đã được gửi về số điện thoại đăng ký của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            const SizedBox(height: 8),
            // Amount reminder
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2530),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Rút ${_fmtAmount(widget.amount)}đ',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _ctrls[i].text.isNotEmpty
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFF1A2530),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _ctrls[i].text.isNotEmpty
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2A3A4A),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _ctrls[i].text.isNotEmpty
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2A3A4A),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF10B981),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (v) => _onDigit(i, v),
                    onTapOutside: (_) {},
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã gửi lại mã OTP'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Gửi lại mã OTP',
                  style: TextStyle(
                    color: const Color(0xFF10B981).withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _complete ? widget.onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  disabledBackgroundColor: const Color(0xFF1E2E3E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  'Xác nhận rút tiền',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared mini-widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 13,
            decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label,
      required this.value,
      this.isBold = false,
      this.valueColor});

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isBold ? Colors.white : Colors.white.withValues(alpha: 0.55),
                fontSize: isBold ? 13 : 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? (isBold ? Colors.white : Colors.white.withValues(alpha: 0.85)),
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600)),
      ],
    );
  }
}
