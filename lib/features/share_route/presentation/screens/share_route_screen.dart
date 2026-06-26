import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/core/widgets/coming_soon_overlay.dart';

class ShareRouteScreen extends StatefulWidget {
  const ShareRouteScreen({super.key});

  @override
  State<ShareRouteScreen> createState() => _ShareRouteScreenState();
}

class _ShareRouteScreenState extends State<ShareRouteScreen> {
  // Mock contacts list matching the UI in Chia_se_lo_trinh.png
  final List<ContactModel> _recentContacts = [
    ContactModel(
      name: 'Trần Thị Bống',
      avatarUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=100&auto=format&fit=crop&q=60',
      initials: 'TB',
    ),
  ];

  final List<ContactModel> _otherContacts = [
    ContactModel(
      name: 'Lê Minh Tuấn',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=60',
      initials: 'LT',
    ),
    ContactModel(
      name: 'Trần Khánh Linh',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=60',
      initials: 'KL',
    ),
    ContactModel(
      name: 'Trần Nhật Duy',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=60',
      initials: 'ND',
    ),
    ContactModel(
      name: 'Lê Thọ',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop&q=60',
      initials: 'T',
    ),
    ContactModel(
      name: 'Phương Thảo',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop&q=60',
      initials: 'PT',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ComingSoonOverlay(
      featureName: 'Chia sẻ lộ trình',
      message: 'Tính năng chia sẻ lộ trình với bạn bè sẽ sớm được ra mắt.',
      blockInteraction: true,
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Map Background on the Top Portion
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.45,
            child: Container(
              color: Colors.grey[900],
              child: Image.asset(
                'assets/images/main/map_card.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.map_outlined, color: Colors.white30, size: 80),
                ),
              ),
            ),
          ),

          // Main content on top of map
          Column(
            children: [
              // Red Header
              Container(
                padding: EdgeInsets.only(top: topPadding + 8, bottom: 16, left: 16, right: 16),
                color: AppColors.primary,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.primary,
                          size: 30,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Chia sẻ lộ trình',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Balance back button
                  ],
                ),
              ),

              const Spacer(),

              // Bottom Sheet content
              Container(
                height: screenHeight * 0.58,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B0505), Color(0xFF0F0202)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handlebar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // "Bạn muốn gửi đến ai?" Search bar mock
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              'Bạn muốn gửi đến ai?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Contacts List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        children: [
                          // Recently Shared
                          const Text(
                            'Đã chia sẻ gần đây',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._recentContacts.map((c) => _buildContactItem(c)),

                          const SizedBox(height: 20),

                          // Others
                          const Text(
                            'Khác',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._otherContacts.map((c) => _buildContactItem(c)),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildContactItem(ContactModel contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
              border: Border.all(color: Colors.white10, width: 1.5),
            ),
            child: ClipOval(
              child: Image.network(
                contact.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    contact.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Text(
              contact.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Send Button — coming soon
          ComingSoonTapBlocker(
            featureName: 'Chia sẻ lộ trình',
            message: 'Tính năng chia sẻ lộ trình với bạn bè sẽ sớm được ra mắt.',
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                minimumSize: const Size(64, 40),
              ),
              child: const Text(
                'Gửi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContactModel {
  final String name;
  final String avatarUrl;
  final String initials;

  ContactModel({
    required this.name,
    required this.avatarUrl,
    required this.initials,
  });
}
