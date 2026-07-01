import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/customer/presentation/providers/customer_review_provider.dart';

class CustomerReviewMechanicScreen extends StatefulWidget {
  const CustomerReviewMechanicScreen({
    super.key,
    required this.orderId,
    required this.mechanicName,
    this.mechanicAvatarUrl,
  });

  final String orderId;
  final String mechanicName;
  final String? mechanicAvatarUrl;

  @override
  State<CustomerReviewMechanicScreen> createState() => _CustomerReviewMechanicScreenState();
}

class _CustomerReviewMechanicScreenState extends State<CustomerReviewMechanicScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerReviewProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Đánh giá thợ'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MechanicHeader(
                mechanicName: widget.mechanicName,
                avatarUrl: widget.mechanicAvatarUrl,
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Đánh giá trải nghiệm',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thợ phục vụ bạn thế nào?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final selected = starValue <= _rating;
                        return InkWell(
                          onTap: provider.isSubmitting
                              ? null
                              : () {
                                  setState(() {
                                    _rating = starValue;
                                  });
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFFFF3CD) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? const Color(0xFFF59E0B) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Icon(
                              selected ? Icons.star_rounded : Icons.star_border_rounded,
                              color: selected ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF),
                              size: 30,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Nhận xét thêm',
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  enabled: !provider.isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Viết vài lời về thái độ phục vụ, tốc độ, giá cả...',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                    ),
                  ),
                ),
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.isSubmitting
                      ? null
                      : () async {
                          final ok = await context.read<CustomerReviewProvider>().submitReview(
                                orderId: widget.orderId,
                                rating: _rating,
                                comment: _commentController.text.trim(),
                              );
                          if (!mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã gửi đánh giá thành công.')),
                            );
                            Navigator.of(context).pop(true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: provider.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Gửi đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MechanicHeader extends StatelessWidget {
  const _MechanicHeader({
    required this.mechanicName,
    this.avatarUrl,
  });

  final String mechanicName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC02020), Color(0xFF9E1818)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            backgroundImage: url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
            child: url.isEmpty ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá thợ của bạn',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  mechanicName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
