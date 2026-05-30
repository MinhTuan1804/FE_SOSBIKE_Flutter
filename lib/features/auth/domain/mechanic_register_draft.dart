import 'package:image_picker/image_picker.dart';

/// Dữ liệu form đăng ký thợ qua 5 bước.
/// Các trường ngân hàng / giấy tờ là optional — có thể cập nhật sau trong hồ sơ.
class MechanicRegisterDraft {
  const MechanicRegisterDraft({
    required this.phoneNumber,
    required this.fullName,
    required this.identityCard,
    required this.dateOfBirth,
    required this.currentAddress,
    this.email,
    // Nghề nghiệp
    this.specialties = const [],
    this.yearsOfExperience,
    this.professionalDescription,
    this.isAvailableNow = true,
    // Khu vực
    this.province,
    this.district,
    this.serviceRadiusKm,
    this.hasHomeService,
    // Xác thực
    this.cccdFrontFile,
    this.cccdBackFile,
    this.portraitFile,
    this.certificateFile,
    // Thông tin cửa hàng (tuỳ chọn)
    this.shopName,
    this.shopAddress,
    // Thanh toán (tuỳ chọn, cập nhật sau)
    this.bankCode,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
  });

  final String phoneNumber;
  final String fullName;
  final String identityCard;
  final DateTime dateOfBirth;
  final String currentAddress;
  final String? email;

  // ── Nghề nghiệp ──────────────────────────────────────────────────────────
  final List<String> specialties;
  final int? yearsOfExperience;
  final String? professionalDescription;
  final bool isAvailableNow;

  // ── Khu vực nhận việc ────────────────────────────────────────────────────
  final String? province;
  final String? district;
  final int? serviceRadiusKm;
  final bool? hasHomeService;

  // ── Xác thực thợ ─────────────────────────────────────────────────────────
  final XFile? cccdFrontFile;
  final XFile? cccdBackFile;
  final XFile? portraitFile;
  final XFile? certificateFile;

  // ── Cửa hàng (tuỳ chọn) ──────────────────────────────────────────────────
  final String? shopName;
  final String? shopAddress;

  // ── Thanh toán (tuỳ chọn) ─────────────────────────────────────────────────
  final String? bankCode;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
}
