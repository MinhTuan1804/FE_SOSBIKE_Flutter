import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_wallet_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_income_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_priority_package_screen.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_deposit_screen.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_withdraw_screen.dart';

enum _WalletSection { wallet, income }

/// Tab **Ví quản lí** — Ví SOSBIKE + giao dịch gần đây (Figma).
class MechanicWalletTab extends StatefulWidget {
  const MechanicWalletTab({super.key});

  @override
  State<MechanicWalletTab> createState() => _MechanicWalletTabState();
}

class _MechanicWalletTabState extends State<MechanicWalletTab> {
  _WalletSection _section = _WalletSection.wallet;
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Bank setup controllers
  String? _bankName;
  final _bankAccCtrl = TextEditingController();
  final _bankHolderCtrl = TextEditingController();

  // PIN code verification & setup state
  String _pinSetupStep = 'enter'; // 'enter' or 'confirm'
  String _tempPin = '';
  final List<int> _enteredPin = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicWalletProvider>().load();
    });
  }

  @override
  void dispose() {
    _bankAccCtrl.dispose();
    _bankHolderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicWalletProvider>();
    final auth = context.watch<AuthProvider>();
    final data = provider.data;

    if (provider.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    // Check PIN setup state
    if (provider.hasPin == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (provider.hasPin == false) {
      return _buildPinSetupView(provider);
    }

    if (!provider.isPinUnlocked) {
      return _buildPinUnlockView(provider);
    }

    // PIN is unlocked, now check if bank account is linked
    final walletProfile = auth.profile?.wallet;
    final hasBank = walletProfile != null &&
        walletProfile.bankName != null &&
        walletProfile.bankName!.isNotEmpty &&
        walletProfile.bankAccountNumber != null &&
        walletProfile.bankAccountNumber!.isNotEmpty &&
        walletProfile.bankAccountHolder != null &&
        walletProfile.bankAccountHolder!.isNotEmpty;

    final wallet = data ?? MechanicWalletData.sample;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 10),
          child: Text(
            'Ví, Thu Nhập',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _SectionToggle(
            section: _section,
            onChanged: (value) => setState(() => _section = value),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _section == _WalletSection.income
                ? const MechanicIncomeTab()
                : !hasBank
                    ? _buildBankSetupView(auth)
                    : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: provider.refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                        children: [
                          _WalletCard(balanceLabel: wallet.balanceLabel, balance: wallet.balance),
                          const SizedBox(height: 12),
                          _PriorityPackageBanner(
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => const MechanicPriorityPackageScreen(initialIndex: 1),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDateFilter(context, provider),
                          const SizedBox(height: 16),
                          if (wallet.withdrawRequests.isNotEmpty) ...[
                            const Text(
                              'Yêu cầu rút tiền',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...wallet.withdrawRequests.map(
                              (req) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _WithdrawRequestTile(req: req, dateFormat: _dateFormat),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Text(
                            'Giao dịch gần đây',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (wallet.transactions.isEmpty)
                            const _EmptyTransactions()
                          else
                            ...wallet.transactions.map(
                              (tx) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _TransactionTile(tx: tx, dateFormat: _dateFormat),
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  // ── PIN Setup Screen ───────────────────────────────────────────────────────
  Widget _buildPinSetupView(MechanicWalletProvider provider) {
    final titleText = _pinSetupStep == 'enter'
        ? 'Thiết lập mã PIN rút tiền'
        : 'Xác nhận mã PIN';
    final subtitleText = _pinSetupStep == 'enter'
        ? 'Vui lòng thiết lập mã PIN 6 số để bảo mật ví của bạn.'
        : 'Nhập lại mã PIN vừa thiết lập để xác nhận.';

    return Container(
      color: const Color(0xFF8B1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security_outlined, color: Colors.white, size: 64),
          const SizedBox(height: 24),
          Text(
            titleText,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            subtitleText,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // PIN indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? Colors.white : Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          _buildNumericKeypad(onKeyTap: (val) async {
            if (_enteredPin.length < 6) {
              setState(() {
                _enteredPin.add(val);
              });
            }
            if (_enteredPin.length == 6) {
              final pinStr = _enteredPin.join();
              if (_pinSetupStep == 'enter') {
                _tempPin = pinStr;
                setState(() {
                  _pinSetupStep = 'confirm';
                  _enteredPin.clear();
                });
              } else {
                if (pinStr == _tempPin) {
                  final ok = await provider.setupWalletPin(pinStr);
                  if (ok) {
                    setState(() {
                      _enteredPin.clear();
                      _tempPin = '';
                      _pinSetupStep = 'enter';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thiết lập mã PIN thành công.')),
                    );
                  } else {
                    setState(() {
                      _enteredPin.clear();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.errorMessage ?? 'Không thiết lập được mã PIN.')),
                    );
                  }
                } else {
                  setState(() {
                    _enteredPin.clear();
                    _pinSetupStep = 'enter';
                    _tempPin = '';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mã PIN xác nhận không trùng khớp. Vui lòng nhập lại.')),
                  );
                }
              }
            }
          }, onBackspace: () {
            if (_enteredPin.isNotEmpty) {
              setState(() {
                _enteredPin.removeLast();
              });
            }
          }),
        ],
      ),
    );
  }

  // ── PIN Unlock / Entry Screen ──────────────────────────────────────────────
  Widget _buildPinUnlockView(MechanicWalletProvider provider) {
    return Container(
      color: const Color(0xFF8B1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Nhập mã PIN',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Vui lòng nhập mã PIN ví gồm 6 chữ số.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? Colors.white : Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              );
            }),
          ),
          const SizedBox(height: 48),
          _buildNumericKeypad(onKeyTap: (val) async {
            if (_enteredPin.length < 6) {
              setState(() {
                _enteredPin.add(val);
              });
            }
            if (_enteredPin.length == 6) {
              final pinStr = _enteredPin.join();
              final ok = await provider.verifyWalletPin(pinStr);
              if (ok) {
                setState(() {
                  _enteredPin.clear();
                });
              } else {
                setState(() {
                  _enteredPin.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mã PIN không chính xác. Vui lòng nhập lại.')),
                );
              }
            }
          }, onBackspace: () {
            if (_enteredPin.isNotEmpty) {
              setState(() {
                _enteredPin.removeLast();
              });
            }
          }),
        ],
      ),
    );
  }

  // ── Custom Numeric Keypad ──────────────────────────────────────────────────
  Widget _buildNumericKeypad({
    required Function(int) onKeyTap,
    required VoidCallback onBackspace,
  }) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var col = 1; col <= 3; col++) ...[
                _buildKeypadButton(
                  value: row * 3 + col,
                  onTap: () => onKeyTap(row * 3 + col),
                ),
              ]
            ],
          ),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72), // Empty placeholder
            _buildKeypadButton(
              value: 0,
              onTap: () => onKeyTap(0),
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 26),
                onPressed: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton({required int value, required VoidCallback onTap}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Text(
              '$value',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ── Bank Setup Form View ───────────────────────────────────────────────────
  Widget _buildBankSetupView(AuthProvider auth) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_outlined, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Liên kết tài khoản ngân hàng',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng điền thông tin tài khoản ngân hàng của bạn để có thể nhận tiền rút từ ví.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Ngân hàng *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _bankName,
            isExpanded: true,
            decoration: _dropDeco('Chọn ngân hàng nhận tiền'),
            items: _kBanks
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _bankName = v),
          ),
          const SizedBox(height: 16),
          _field('Số tài khoản *', _bankAccCtrl, hint: 'Nhập số tài khoản', digitsOnly: true),
          _field('Tên chủ tài khoản *', _bankHolderCtrl, hint: 'Nhập tên chủ tài khoản (viết hoa không dấu)'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final bankAcc = _bankAccCtrl.text.trim();
              final bankHolder = _bankHolderCtrl.text.trim().toUpperCase();
              if (_bankName == null || bankAcc.length < 6 || bankHolder.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin tài khoản ngân hàng.')),
                );
                return;
              }

              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );

              final ok = await auth.saveMyProfile(
                fullName: auth.displayName,
                bankName: _bankName,
                bankAccountNumber: bankAcc,
                bankAccountHolder: bankHolder,
              );

              if (!mounted) return;
              Navigator.of(context).pop(); // Close spinner

              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Liên kết tài khoản ngân hàng thành công.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(auth.errorMessage ?? 'Có lỗi xảy ra, vui lòng thử lại.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Xác nhận liên kết',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Styling Helpers for Bank form ──────────────────────────────────────────
  InputDecoration _dropDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  InputDecoration _textDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    bool digitsOnly = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
              inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
              decoration: _textDeco(hint ?? ''),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      );

  Widget _buildDateFilter(BuildContext context, MechanicWalletProvider provider) {
    final start = provider.startDate;
    final end = provider.endDate;
    final hasFilter = start != null && end != null;

    final rangeText = hasFilter
        ? '${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}'
        : 'Tất cả thời gian';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFilter ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: hasFilter ? AppColors.primary : const Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _selectDateRange(context, provider),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian giao dịch',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rangeText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: hasFilter ? AppColors.primary : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Color(0xFF9CA3AF), size: 20),
              onPressed: () => provider.clearDateRange(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context, MechanicWalletProvider provider) async {
    final now = DateTime.now();
    final initialRange = provider.startDate != null && provider.endDate != null
        ? DateTimeRange(start: provider.startDate!, end: provider.endDate!)
        : null;

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }
}

const _kBanks = [
  'Vietcombank', 'Techcombank', 'VietinBank', 'BIDV', 'Agribank',
  'MB Bank', 'ACB', 'Sacombank', 'TPBank', 'VPBank',
  'SHB', 'HDBank', 'SeABank', 'VIB', 'OCB', 'MSB',
];

class _SectionToggle extends StatelessWidget {
  const _SectionToggle({required this.section, required this.onChanged});

  final _WalletSection section;
  final ValueChanged<_WalletSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'Ví',
              selected: section == _WalletSection.wallet,
              onTap: () => onChanged(_WalletSection.wallet),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'Thu Nhập',
              selected: section == _WalletSection.income,
              onTap: () => onChanged(_WalletSection.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 36,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balanceLabel, required this.balance});

  final String balanceLabel;
  final int balance;

  int get _balanceInt => balance;

  @override
  Widget build(BuildContext context) {
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
                'Ví SOSBIKE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VND',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Số Dư',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            balanceLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WalletAction(
                  icon: Icons.savings_outlined,
                  label: 'Nạp tiền',
                  onTap: () async {
                    final provider = context.read<MechanicWalletProvider>();
                    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => MechanicDepositScreen(currentBalance: _balanceInt),
                        fullscreenDialog: true,
                      ),
                    );
                    if (result == true && context.mounted) {
                      provider.refresh();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WalletAction(
                  icon: Icons.payments_outlined,
                  label: 'Rút tiền',
                  onTap: () async {
                    final provider = context.read<MechanicWalletProvider>();
                    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => MechanicWithdrawScreen(currentBalance: _balanceInt),
                        fullscreenDialog: true,
                      ),
                    );
                    if (result == true && context.mounted) {
                      provider.refresh();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityPackageBanner extends StatelessWidget {
  const _PriorityPackageBanner({required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                ),
                child: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Gói Ưu Tiên',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx, required this.dateFormat});

  final MechanicWalletTransaction tx;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final color = tx.isCredit ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              tx.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF111827)),
                ),
                if (tx.isPending) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Chờ xử lý',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  tx.description ?? dateFormat.format(tx.createdAt.toLocal()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tx.amountLabel,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Chưa có giao dịch nào.',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _WithdrawRequestTile extends StatelessWidget {
  const _WithdrawRequestTile({required this.req, required this.dateFormat});

  final MechanicWithdrawRequest req;
  final DateFormat dateFormat;

  Color _statusColor(String status) => switch (status.toUpperCase()) {
        'PENDING' => const Color(0xFFF59E0B),
        'APPROVED' => const Color(0xFF3B82F6),
        'REJECTED' => const Color(0xFFDC2626),
        'COMPLETED' => const Color(0xFF16A34A),
        _ => const Color(0xFF6B7280),
      };

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(req.status);
    final subtitle = req.status.toUpperCase() == 'REJECTED' && req.rejectionReason != null
        ? req.rejectionReason!
        : '${req.bankName} · ${req.maskedAccount}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.account_balance_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        req.amountLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                ),
                if (req.status.toUpperCase() == 'PENDING') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.access_time_rounded, size: 11, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        'Duyệt tiền có thể mất 5-10 phút',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(req.requestedAt.toLocal()),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
