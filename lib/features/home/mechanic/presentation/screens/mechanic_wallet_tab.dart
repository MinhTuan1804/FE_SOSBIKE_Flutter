import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_wallet_models.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/providers/mechanic_wallet_provider.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_income_tab.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_priority_package_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicWalletProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MechanicWalletProvider>();
    final data = provider.data;

    if (provider.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

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
                : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: provider.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    children: [
                      _WalletCard(balanceLabel: wallet.balanceLabel),
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
}

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
  const _WalletCard({required this.balanceLabel});

  final String balanceLabel;

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
            children: const [
              Expanded(child: _WalletAction(icon: Icons.savings_outlined, label: 'Nạp tiền')),
              SizedBox(width: 8),
              Expanded(child: _WalletAction(icon: Icons.payments_outlined, label: 'Rút tiền')),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {},
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
