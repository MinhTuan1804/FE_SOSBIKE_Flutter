import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'mechanic_wallet_shared.dart';

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
              .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: switch (_step) {
        _WithdrawStep.enterAmount => WalletEnterAmountScreen(
            key: const ValueKey('enter'),
            title: 'Rút tiền',
            subtitle: 'Rút về tài khoản ngân hàng',
            icon: Icons.payments_outlined,
            accentColor: AppColors.primary,
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
        _WithdrawStep.processing => const WalletProcessingScreen(
            key: ValueKey('processing'),
            message: 'Đang xử lý yêu cầu rút tiền...',
          ),
        _WithdrawStep.success => WalletResultScreen(
            key: const ValueKey('success'),
            isSuccess: true,
            title: 'Rút tiền thành công!',
            subtitle: 'Tiền đang được chuyển về tài khoản của bạn.',
            amount: _amount,
            amountLabel: '-${fmtWalletAmount(_amount)}đ',
            amountColor: const Color(0xFF22C55E),
            onDone: () => Navigator.of(context).pop(true),
          ),
        _WithdrawStep.failure => WalletResultScreen(
            key: const ValueKey('failure'),
            isSuccess: false,
            title: 'Rút tiền thất bại',
            subtitle: 'Không thể xử lý yêu cầu.\nVui lòng kiểm tra và thử lại.',
            amount: _amount,
            amountLabel: '${fmtWalletAmount(_amount)}đ',
            amountColor: AppColors.primary,
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
                            'Xác nhận tài khoản',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900),
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
                            child: const Icon(Icons.payments_outlined,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Số tiền rút',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 11)),
                                Text('-${fmtWalletAmount(amount)}đ',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Số dư',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.65),
                                      fontSize: 10)),
                              Text('${fmtWalletAmount(balance)}đ',
                                  style: TextStyle(
                                    color: _sufficient
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : const Color(0xFFFFCC00),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
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
                  const WalletSectionTitle(label: 'Tài khoản nhận tiền'),
                  const SizedBox(height: 10),
                  if (_hasBankInfo)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1010),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                              icon: Icons.account_balance_rounded,
                              label: 'Ngân hàng',
                              value: bankName),
                          const Divider(color: Color(0xFF3A1A1A), height: 18),
                          _InfoRow(
                              icon: Icons.credit_card_rounded,
                              label: 'Số tài khoản',
                              value: bankAccount),
                          const Divider(color: Color(0xFF3A1A1A), height: 18),
                          _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Chủ tài khoản',
                              value: bankHolder.isNotEmpty ? bankHolder : '---'),
                        ],
                      ),
                    )
                  else
                    _NoBankCard(amount: amount, onLinked: onConfirm),

                  if (!_sufficient && _hasBankInfo) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Số dư không đủ để rút ${fmtWalletAmount(amount)}đ.',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const WalletSectionTitle(label: 'Tóm tắt giao dịch'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1010),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                            label: 'Số tiền rút',
                            value: '${fmtWalletAmount(amount)}đ'),
                        const SizedBox(height: 6),
                        const _SummaryRow(
                            label: 'Phí giao dịch', value: 'Miễn phí'),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFF3A1A1A)),
                        ),
                        _SummaryRow(
                          label: 'Thực nhận',
                          value: '${fmtWalletAmount(amount)}đ',
                          isBold: true,
                          valueColor: const Color(0xFF22C55E),
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
            onPressed: (_hasBankInfo && _sufficient) ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFF3A1A1A),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              !_hasBankInfo
                  ? 'Liên kết ngân hàng trước'
                  : !_sufficient
                      ? 'Số dư không đủ'
                      : 'Tiếp tục',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
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
    for (final c in _ctrls) { c.dispose(); }
    for (final n in _nodes) { n.dispose(); }
    super.dispose();
  }

  void _onDigit(int index, String value) {
    if (value.length == 1 && index < 5) _nodes[index + 1].requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const Expanded(
                          child: Text(
                            'Xác nhận OTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900),
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
                            child: const Icon(Icons.lock_outline_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Xác nhận giao dịch',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 11)),
                                Text('Rút ${fmtWalletAmount(widget.amount)}đ',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WalletSectionTitle(label: 'Nhập mã OTP'),
                  const SizedBox(height: 8),
                  Text(
                    'Mã OTP đã được gửi về số điện thoại đăng ký của bạn',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13),
                  ),
                  const SizedBox(height: 28),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: _ctrls[i].text.isNotEmpty
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : const Color(0xFF2A1010),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _ctrls[i].text.isNotEmpty
                                      ? AppColors.primary
                                      : const Color(0xFF3A1A1A)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: _ctrls[i].text.isNotEmpty
                                      ? AppColors.primary
                                      : const Color(0xFF3A1A1A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2),
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
                                behavior: SnackBarBehavior.floating));
                      },
                      child: const Text('Gửi lại mã OTP',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
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
            onPressed: _complete ? widget.onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFF3A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Xác nhận rút tiền',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}

// ─── Mini widgets ─────────────────────────────────────────────────────────────

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
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12))),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });
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
                color: isBold
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
                fontSize: isBold ? 13 : 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: valueColor ??
                    (isBold
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.85)),
                fontSize: isBold ? 14 : 12,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w600)),
      ],
    );
  }
}

// ─── No Bank Card ──────────────────────────────────────────────────────────────

class _NoBankCard extends StatelessWidget {
  const _NoBankCard({required this.amount, required this.onLinked});
  final int amount;
  final VoidCallback onLinked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1010),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Chưa liên kết ngân hàng',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bạn cần liên kết tài khoản ngân hàng để rút tiền.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => _showLinkSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Liên kết ngân hàng',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLinkSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkBankSheet(onSaved: onLinked),
    );
  }
}

// ─── Link Bank Sheet ──────────────────────────────────────────────────────────

class _LinkBankSheet extends StatefulWidget {
  const _LinkBankSheet({required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<_LinkBankSheet> createState() => _LinkBankSheetState();
}

class _LinkBankSheetState extends State<_LinkBankSheet> {
  final _bankNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  bool _saving = false;

  static const _banks = [
    'Vietcombank', 'VietinBank', 'BIDV', 'Agribank',
    'Techcombank', 'MB Bank', 'ACB', 'VPBank',
    'TPBank', 'Sacombank', 'HDBank', 'SHB',
  ];

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountCtrl.dispose();
    _holderCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _bankNameCtrl.text.isNotEmpty &&
      _accountCtrl.text.isNotEmpty &&
      _holderCtrl.text.isNotEmpty;

  Future<void> _save() async {
    if (!_valid) return;
    setState(() => _saving = true);
    try {
      final auth = context.read<AuthProvider>();
      final existingName = auth.profile?.fullName ?? '';
      final ok = await auth.saveMyProfile(
        fullName: existingName,
        bankName: _bankNameCtrl.text.trim(),
        bankAccountNumber: _accountCtrl.text.trim(),
        bankAccountHolder: _holderCtrl.text.trim().toUpperCase(),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Liên kết ngân hàng thành công!'),
          behavior: SnackBarBehavior.floating,
        ));
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Không thể lưu. Vui lòng thử lại.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã có lỗi xảy ra.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF3A1A1A))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A1A1A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7A1010), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Liên kết tài khoản ngân hàng',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900)),
                        Text('Thông tin sẽ được mã hóa bảo mật',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Fields
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bank name dropdown
                  _SheetLabel(label: 'Ngân hàng'),
                  const SizedBox(height: 6),
                  _buildDropdown(),
                  const SizedBox(height: 14),

                  _SheetLabel(label: 'Số tài khoản'),
                  const SizedBox(height: 6),
                  _buildField(
                    ctrl: _accountCtrl,
                    hint: 'VD: 0123456789',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),

                  _SheetLabel(label: 'Tên chủ tài khoản'),
                  const SizedBox(height: 6),
                  _buildField(
                    ctrl: _holderCtrl,
                    hint: 'VD: NGUYEN VAN A',
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving
                          ? null
                          : (_valid ? _save : null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: const Color(0xFF3A1A1A),
                        foregroundColor: Colors.white,
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Xác nhận liên kết',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
      hint: Text('Chọn ngân hàng',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35), fontSize: 14)),
      dropdownColor: const Color(0xFF2A1010),
      style: const TextStyle(color: Colors.white, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2A1010),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A1A1A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A1A1A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: _banks
          .map((b) => DropdownMenuItem(
                value: b,
                child: Text(b),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() => _bankNameCtrl.text = v);
        }
      },
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF2A1010),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A1A1A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A1A1A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 12,
          fontWeight: FontWeight.w700),
    );
  }
}
