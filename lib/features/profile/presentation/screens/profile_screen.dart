import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fe_moblie_flutter/features/home/shared/presentation/widgets/main_bottom_nav_bar.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/screens/add_vehicle_screen.dart';
import 'package:fe_moblie_flutter/features/profile/presentation/providers/vehicle_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe_moblie_flutter/core/navigation/auth_navigation.dart';
import 'package:fe_moblie_flutter/core/theme/app_colors.dart';
import 'package:fe_moblie_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:fe_moblie_flutter/core/widgets/page_loader.dart';
import 'package:fe_moblie_flutter/features/home/mechanic/presentation/screens/mechanic_setup_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _bgColor = Color(0xFFF9F9F9); // Nền xám nhạt

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().fetchMyVehicles();
      context.read<AuthProvider>().fetchMyProfile(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vehicleProvider = context.watch<VehicleProvider>();
    final isVerified = auth.profile?.mechanic?.isVerified ?? false;

    return Scaffold(
      backgroundColor: _bgColor,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _SettingsMenu(auth: auth, context: context),
        ],
      ),
      body: Stack(
        children: [
          // Khối nền đỏ phía trên
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(color: AppColors.primary),
          ),
          
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16), // Khoảng cách trước thẻ đè lên nền đỏ

                // 1. Thẻ Header Profile (Đè lên nền đỏ)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar với icon edit
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildAvatarImage(auth.avatarUrl),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Tên & ID
                      Text(
                        auth.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Nút Edit Profile
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PageLoader(child: EditProfileScreen()),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Chỉnh sửa thông tin cá nhân',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Phần Thông tin cá nhân
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thông tin cá nhân',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        title: auth.phoneNumber ?? 'Chưa cập nhật', 
                        subtitle: 'Số điện thoại',
                        isVerified: auth.isPhoneVerified,
                      ),
                      const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFEEEEEE)),
                       _InfoRow(
                        icon: Icons.email_outlined,
                        title: (auth.email != null && auth.email!.isNotEmpty) ? auth.email! : 'Chưa cập nhật', 
                        subtitle: 'Email',
                        isVerified: (auth.email != null && auth.email!.isNotEmpty)
                            ? auth.profile?.isEmailVerified ?? false
                            : null,
                        onVerify: (auth.email != null && auth.email!.isNotEmpty)
                            ? () => _showEmailVerificationDialog(context, auth.email!)
                            : null,
                      ),
                      const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFEEEEEE)),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        title: (auth.currentAddress != null && auth.currentAddress!.isNotEmpty) ? auth.currentAddress! : 'Chưa cập nhật', 
                        subtitle: 'Địa chỉ hiện tại',
                      ),
                      const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFEEEEEE)),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _InfoRow(
                                icon: Icons.female,
                                title: _formatGender(auth.gender),
                                subtitle: 'Giới tính',
                                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
                              ),
                            ),
                            const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                            Expanded(
                              child: _InfoRow(
                                icon: Icons.cake_outlined,
                                title: auth.dateOfBirth ?? 'Chưa cập nhật',
                                subtitle: 'Ngày sinh',
                                padding: const EdgeInsets.only(left: 8, top: 16, bottom: 16, right: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── SECTION: Hồ sơ & Giấy tờ thợ (luôn hiển thị với mechanic) ──
                if (auth.userType?.toUpperCase() == 'MECHANIC') ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hồ sơ & Giấy tờ thợ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Icon(Icons.assignment_ind_outlined, color: AppColors.primary, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? Colors.green.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isVerified ? Icons.verified_outlined : Icons.assignment_ind_outlined,
                            color: isVerified ? Colors.green : AppColors.primary,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          isVerified ? 'Hồ sơ đã được xác thực' : 'Hoàn thiện hồ sơ & Xác thực thợ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isVerified ? Colors.green[700] : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          isVerified
                              ? 'Tài khoản của bạn đã được Admin SOSBIKE duyệt'
                              : 'Khu vực hoạt động, ảnh CCCD, chứng chỉ nghề & ngân hàng',
                          style: TextStyle(
                            fontSize: 12,
                            color: isVerified ? Colors.green[400] : Colors.grey,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: isVerified ? Colors.green[300] : Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MechanicSetupProfileScreen(),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<AuthProvider>().fetchMyProfile(silent: true);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],


                // ── SECTION: Phương tiện của tôi (luôn hiển thị, khác nhau theo loại tài khoản) ──
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Phương tiện của tôi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // Chỉ customer mới có nút thêm xe, mechanic quản lý xe qua hồ sơ thợ
                      if (auth.userType?.toUpperCase() != 'MECHANIC')
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PageLoader(child: AddVehicleScreen()),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                context.read<VehicleProvider>().fetchMyVehicles();
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Mechanic: hiển thị xe đăng ký trong hồ sơ thợ (model, biển số, đời xe)
                if (auth.userType?.toUpperCase() == 'MECHANIC') ...[
                  if (auth.profile?.mechanic?.licensePlate != null &&
                      auth.profile!.mechanic!.licensePlate.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // initialTab: 2 → mở thẳng tab "Phương tiện"
                            builder: (context) => const MechanicSetupProfileScreen(initialTab: 2),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<AuthProvider>().fetchMyProfile(silent: true);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Ảnh xe (full width, có gradient overlay) ──
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Stack(
                                children: [
                                  // Ảnh xe
                                  if (auth.profile!.mechanic!.vehiclePhotoUrl != null &&
                                      auth.profile!.mechanic!.vehiclePhotoUrl!.isNotEmpty)
                                    CachedNetworkImage(
                                      imageUrl: auth.profile!.mechanic!.vehiclePhotoUrl!,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        height: 180,
                                        color: const Color(0xFFF5F5F5),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => const _VehiclePhotoPlaceholder(type: 'OTHER'),
                                    )
                                  else
                                    const _VehiclePhotoPlaceholder(type: 'OTHER'),

                                  // Gradient overlay từ dưới lên
                                  Positioned(
                                    left: 0, right: 0, bottom: 0,
                                    child: Container(
                                      height: 90,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.75),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Tên xe trên gradient
                                  Positioned(
                                    left: 16, right: 16, bottom: 12,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                auth.profile!.mechanic!.vehicleModel ?? 'Xe máy thợ',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                auth.profile!.mechanic!.licensePlate,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Badge loại xe
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Xe thợ chuyên dụng',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Chi tiết xe ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Row 1: Năm SX + Màu xe
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'Đời xe',
                                          value: auth.profile!.mechanic!.vehicleGeneration != null &&
                                                  auth.profile!.mechanic!.vehicleGeneration!.isNotEmpty
                                              ? auth.profile!.mechanic!.vehicleGeneration!
                                              : 'Chưa có',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.palette_outlined,
                                          label: 'Màu xe',
                                          value: auth.profile!.mechanic!.color != null &&
                                                  auth.profile!.mechanic!.color!.isNotEmpty
                                              ? auth.profile!.mechanic!.color!
                                              : 'Chưa có',
                                          colorDot: _parseColor(auth.profile!.mechanic!.color),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Row 2: GPLX + Biển số
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.badge_outlined,
                                          label: 'Số GPLX',
                                          value: auth.profile!.mechanic!.driverLicenseNumber != null &&
                                                  auth.profile!.mechanic!.driverLicenseNumber!.isNotEmpty
                                              ? auth.profile!.mechanic!.driverLicenseNumber!
                                              : 'Chưa có',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.confirmation_number_outlined,
                                          label: 'Biển số',
                                          value: auth.profile!.mechanic!.licensePlate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Chưa cấu hình phương tiện hoạt động. Vui lòng hoàn thiện hồ sơ thợ.',
                        style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ),

                // Customer: hiển thị danh sách xe thông thường
                ] else ...[
                  if (vehicleProvider.isLoading)
                    const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  else if (vehicleProvider.vehicles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PageLoader(child: AddVehicleScreen()),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              context.read<VehicleProvider>().fetchMyVehicles();
                            }
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Thêm thông tin xe'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else
                    ...vehicleProvider.vehicles.map<Widget>((v) {
                      final hasPhoto = v.photourl != null && v.photourl!.isNotEmpty;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Ảnh xe (full width, có gradient overlay) ──
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Stack(
                                children: [
                                  // Ảnh xe
                                  if (hasPhoto)
                                    CachedNetworkImage(
                                      imageUrl: v.photourl!,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        height: 180,
                                        color: const Color(0xFFF5F5F5),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => _VehiclePhotoPlaceholder(type: v.vehicletype),
                                    )
                                  else
                                    _VehiclePhotoPlaceholder(type: v.vehicletype),

                                  // Gradient overlay từ dưới lên
                                  Positioned(
                                    left: 0, right: 0, bottom: 0,
                                    child: Container(
                                      height: 90,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.75),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Tên xe trên gradient
                                  Positioned(
                                    left: 16, right: 16, bottom: 12,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${v.brand} ${v.model}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                v.licenseplate,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Badge loại xe
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _formatVehicleType(v.vehicletype),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Chi tiết xe ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Row 1: Năm SX + Màu xe
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'Năm SX',
                                          value: v.yearofmanufacture != null
                                              ? '${v.yearofmanufacture}'
                                              : 'Chưa có',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.palette_outlined,
                                          label: 'Màu xe',
                                          value: v.color?.isNotEmpty == true
                                              ? v.color!
                                              : 'Chưa có',
                                          colorDot: _parseColor(v.color),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Row 2: Số km + Biển số
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.speed_outlined,
                                          label: 'Số km',
                                          value: v.currentmileage != null
                                              ? '${_formatMileage(v.currentmileage!)} km'
                                              : 'Chưa có',
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _VehicleDetailChip(
                                          icon: Icons.confirmation_number_outlined,
                                          label: 'Biển số',
                                          value: v.licenseplate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                ],


                const SizedBox(height: 120), // Khoảng trống cho thanh điều hướng
              ],
            ),
          ),
          
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.primary,
              clipBehavior: Clip.none,
              child: MainBottomNavBar(
                current: MainNavTab.orders,
                onChanged: (t) => Navigator.pop(context, t),
                userType: auth.userType,
                showActive: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String? avatarUrl) {
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return Image.asset(
        'assets/images/main/avatar_placeholder.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Icon(
            Icons.person,
            color: Colors.grey,
            size: 50,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Image.asset(
        'assets/images/main/avatar_placeholder.png',
        fit: BoxFit.cover,
      ),
      errorWidget: (_, __, ___) => Image.asset(
        'assets/images/main/avatar_placeholder.png',
        fit: BoxFit.cover,
      ),
    );
  }

  String _formatVehicleType(String typeCode) {
    switch (typeCode.toUpperCase()) {
      case 'SCOOTER':
        return 'Xe tay ga';
      case 'MANUAL':
        return 'Xe số';
      case 'ELECTRIC':
        return 'Xe máy điện';
      case 'OTHER':
        return 'Khác';
      default:
        return typeCode;
    }
  }

  String _formatGender(String? genderCode) {
    if (genderCode == null || genderCode.isEmpty) return 'Chưa cập nhật';
    switch (genderCode.toUpperCase()) {
      case 'MALE':
        return 'Nam';
      case 'FEMALE':
        return 'Nữ';
      case 'OTHER':
        return 'Khác';
      default:
        return genderCode;
    }
  }

  Color? _parseColor(String? colorName) {
    if (colorName == null || colorName.isEmpty) return null;
    switch (colorName.toLowerCase()) {
      case 'đen': case 'black':  return Colors.black87;
      case 'trắng': case 'white': return Colors.white;
      case 'đỏ': case 'red':    return Colors.red;
      case 'xanh lam': case 'blue': return Colors.blue;
      case 'xanh lá': case 'green': return Colors.green;
      case 'vàng': case 'yellow': return Colors.amber;
      case 'cam': case 'orange': return Colors.orange;
      case 'xám': case 'grey': case 'gray': return Colors.grey;
      case 'bạc': case 'silver': return const Color(0xFFC0C0C0);
      case 'nâu': case 'brown': return Colors.brown;
      case 'tím': case 'purple': return Colors.purple;
      case 'hồng': case 'pink': return Colors.pink;
      default: return null;
    }
  }

  String _formatMileage(int km) {
    if (km >= 1000) {
      return '${(km / 1000).toStringAsFixed(1)}k';
    }
    return '$km';
  }

  void _showEmailVerificationDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailLinkVerificationDialog(email: email),
    );
  }
}

class EmailLinkVerificationDialog extends StatefulWidget {
  const EmailLinkVerificationDialog({super.key, required this.email});
  final String email;

  @override
  State<EmailLinkVerificationDialog> createState() => _EmailLinkVerificationDialogState();
}

class _EmailLinkVerificationDialogState extends State<EmailLinkVerificationDialog> {
  int _cooldown = 30;
  Timer? _cooldownTimer;
  bool _isSending = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _sendLink();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldown = 30;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _cooldown--;
        });
      }
    });
  }

  Future<void> _sendLink() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _errorMsg = null;
    });

    final success = await context.read<AuthProvider>().sendEmailVerification();
    if (mounted) {
      setState(() {
        _isSending = false;
      });
      if (success) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liên kết xác thực đã được gửi.')),
        );
      } else {
        setState(() {
          _errorMsg = context.read<AuthProvider>().errorMessage ?? 'Không thể gửi email xác thực.';
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isSending = true;
    });
    final auth = context.read<AuthProvider>();
    final profile = await auth.fetchMyProfile(silent: true);
    if (mounted) {
      setState(() {
        _isSending = false;
      });
      if (profile != null && profile.isEmailVerified) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác thực Email thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email chưa được xác thực. Vui lòng kiểm tra hộp thư của bạn.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Xác thực Email',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Chúng tôi đã gửi một liên kết xác thực đến địa chỉ email:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Vui lòng mở hộp thư email của bạn, nhấp vào liên kết xác thực (nút "Xác nhận Email của bạn") và sau đó quay lại đây nhấn nút dưới để kiểm tra.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (_errorMsg != null) ...[
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _isSending ? null : _checkVerificationStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Tôi đã xác nhận', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: (_cooldown > 0 || _isSending) ? null : _sendLink,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                _cooldown > 0
                ? 'Gửi lại email sau ${_cooldown}s'
                : 'Gửi lại email',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isVerified,
    this.padding = const EdgeInsets.all(16),
    this.onVerify,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool? isVerified;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isVerified != null) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isVerified! ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isVerified! ? 'ĐÃ XÁC THỰC' : 'CHƯA XÁC THỰC',
                          style: TextStyle(
                            color: isVerified! ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isVerified! && onVerify != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onVerify,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Xác nhận',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget placeholder khi xe chưa có ảnh ─────────────────────────────────
class _VehiclePhotoPlaceholder extends StatelessWidget {
  const _VehiclePhotoPlaceholder({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isMotorbike = !type.toUpperCase().contains('CAR');
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C1C1E),
            const Color(0xFF2C2C2E),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMotorbike ? Icons.two_wheeler_outlined : Icons.directions_car_outlined,
            color: Colors.white24,
            size: 56,
          ),
          const SizedBox(height: 8),
          const Text(
            'Chưa có ảnh xe',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Widget chip thông tin chi tiết xe ─────────────────────────────────────
class _VehicleDetailChip extends StatelessWidget {
  const _VehicleDetailChip({
    required this.icon,
    required this.label,
    required this.value,
    this.colorDot,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? colorDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (colorDot != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: colorDot,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 0.5),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsMenu extends StatefulWidget {
  const _SettingsMenu({
    required this.auth,
    required this.context,
  });

  final AuthProvider auth;
  final BuildContext context;

  @override
  State<_SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<_SettingsMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
      offset: const Offset(0, 40),
      onSelected: (value) async {
        if (value == 'logout') {
          await _handleLogout(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppColors.primary, size: 20),
              SizedBox(width: 12),
              Text(
                'Đăng xuất',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) navigateToLogin();
    }
  }
}
