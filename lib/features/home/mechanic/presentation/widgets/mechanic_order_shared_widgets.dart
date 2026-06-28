import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/data/models/incoming_rescue_request.dart';
import 'package:fe_moblie_flutter/core/utils/encoding_utils.dart';

class MechanicOrderCustomerHeader extends StatelessWidget {
  const MechanicOrderCustomerHeader({
    super.key,
    required this.request,
  });

  final IncomingRescueRequest request;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(avatarUrl: request.avatarUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Khách hàng',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                request.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            request.serviceTypeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

class MechanicOrderAddressBox extends StatelessWidget {
  const MechanicOrderAddressBox({
    super.key,
    required this.fullAddress,
    required this.distanceLabel,
  });

  final String fullAddress;
  final String distanceLabel;

  @override
  Widget build(BuildContext context) {
    final decodedAddress = EncodingUtils.fixVietnameseEncoding(fullAddress);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  decodedAddress,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                    height: 1.3,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            distanceLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class MechanicOrderContactRow extends StatelessWidget {
  const MechanicOrderContactRow({
    super.key,
    required this.phoneNumber,
    this.onCall,
    this.onChat,
  });

  final String phoneNumber;
  final VoidCallback? onCall;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            phoneNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ),
        _ContactIconButton(
          icon: Icons.phone_rounded,
          color: const Color(0xFF16A34A),
          onTap: onCall,
        ),
        const SizedBox(width: 8),
        _ContactIconButton(
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF16A34A),
          onTap: onChat,
        ),
      ],
    );
  }
}

class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: ClipOval(
        child: url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
            : Image.asset(
                'assets/images/main/avatar_placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary),
              ),
      ),
    );
  }
}

class MechanicOrderBottomSheet extends StatelessWidget {
  const MechanicOrderBottomSheet({
    super.key,
    required this.child,
    this.scrollController,
    this.pinnedFooter,
    this.onDoubleTapCollapse,
  });

  final Widget child;
  final ScrollController? scrollController;
  final Widget? pinnedFooter;
  final VoidCallback? onDoubleTapCollapse;

  @override
  Widget build(BuildContext context) {
    final handle = GestureDetector(
      onDoubleTap: onDoubleTapCollapse,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );

    final decoration = BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    );

    if (scrollController != null) {
      return Container(
        decoration: decoration,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (pinnedFooter == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  handle,
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      children: [child],
                    ),
                  ),
                ],
              );
            }

            final h = constraints.maxHeight;
            const handleH = 32.0;
            final bottomSafe = MediaQuery.paddingOf(context).bottom;
            final footerBlockH = pinnedFooter != null ? 44.0 + 16.0 + bottomSafe : 0.0;
            final showFooter = pinnedFooter != null && h >= handleH + footerBlockH;
            final showBody = h >= handleH + footerBlockH + 48;

            if (!showFooter) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [handle],
              );
            }

            if (!showBody) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  handle,
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 12 + bottomSafe),
                    child: pinnedFooter!,
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                handle,
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(14, 0, 14, pinnedFooter != null ? 4 : 12),
                    children: [child],
                  ),
                ),
                if (pinnedFooter != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 12 + bottomSafe),
                    child: pinnedFooter!,
                  ),
              ],
            );
          },
        ),
      );
    }

    if (pinnedFooter != null) {
      return Container(
        decoration: decoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            handle,
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
              child: child,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 4, 14, 12 + MediaQuery.paddingOf(context).bottom),
              child: pinnedFooter!,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [handle, child],
      ),
    );
  }
}
