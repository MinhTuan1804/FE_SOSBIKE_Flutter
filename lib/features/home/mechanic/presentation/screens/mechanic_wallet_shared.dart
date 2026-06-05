import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';

// ─── Shared helper ────────────────────────────────────────────────────────────

String fmtWalletAmount(int v) => v
    .toString()
    .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

// ─── Section title (matches checkout style) ───────────────────────────────────

class WalletSectionTitle extends StatelessWidget {
  const WalletSectionTitle({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ─── Enter Amount ─────────────────────────────────────────────────────────────

class WalletEnterAmountScreen extends StatefulWidget {
  const WalletEnterAmountScreen({
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
  State<WalletEnterAmountScreen> createState() => _WalletEnterAmountScreenState();
}

class _WalletEnterAmountScreenState extends State<WalletEnterAmountScreen> {
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
    _ctrl.text = fmtWalletAmount(amount);
    setState(() => _parsed = amount);
  }

  bool get _valid => _parsed >= 10000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
      body: Column(
        children: [
          // ── Gradient header (giống checkout) ──
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
                        Expanded(
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                  // Amount summary pill
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.15),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Icon(widget.icon,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.subtitle,
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  _parsed > 0
                                      ? '${fmtWalletAmount(_parsed)}đ'
                                      : 'Nhập số tiền bên dưới',
                                  style: TextStyle(
                                    color: _valid
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.45),
                                    fontSize: _valid ? 20 : 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
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
                  WalletSectionTitle(label: 'Số tiền ${widget.title.toLowerCase()}'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1010),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _valid
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : const Color(0xFF3A1A1A),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Số tiền (VND)',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11)),
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
                          const Text('Tối thiểu 10.000đ',
                              style: TextStyle(
                                  color: AppColors.primary, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const WalletSectionTitle(label: 'Chọn nhanh'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.quickAmounts.map((amt) {
                      final selected = _parsed == amt;
                      return GestureDetector(
                        onTap: () => _selectQuick(amt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : const Color(0xFF2A1010),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFF3A1A1A),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '+${fmtWalletAmount(amt)}đ',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
            onPressed: _valid ? () => widget.onNext(_parsed) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFF3A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Tiếp tục',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
        ),
      ),
    );
  }
}

// ─── Processing ───────────────────────────────────────────────────────────────

class WalletProcessingScreen extends StatefulWidget {
  const WalletProcessingScreen({super.key, required this.message});

  final String message;

  @override
  State<WalletProcessingScreen> createState() => _WalletProcessingScreenState();
}

class _WalletProcessingScreenState extends State<WalletProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
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
      backgroundColor: const Color(0xFF1A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A1010), Color(0xFF2D0808)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(widget.message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Vui lòng không tắt ứng dụng...',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Result ───────────────────────────────────────────────────────────────────

class WalletResultScreen extends StatefulWidget {
  const WalletResultScreen({
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
  State<WalletResultScreen> createState() => _WalletResultScreenState();
}

class _WalletResultScreenState extends State<WalletResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        widget.isSuccess ? const Color(0xFF22C55E) : AppColors.primary;
    final fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    final scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A0A),
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
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isSuccess
                          ? Icons.check_circle_outline_rounded
                          : Icons.cancel_outlined,
                      color: iconColor,
                      size: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: fade,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: fade,
                child: Text(widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                        height: 1.5)),
              ),
              const SizedBox(height: 32),
              if (widget.isSuccess)
                FadeTransition(
                  opacity: fade,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1010),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: iconColor.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Số tiền',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 13)),
                            Text(widget.amountLabel,
                                style: TextStyle(
                                    color: widget.amountColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFF3A1A1A)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Thời gian',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 13)),
                            Text(_nowLabel(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
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
                              style: TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15)),
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
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          widget.isSuccess ? 'Về trang ví' : 'Đóng',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
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
