import 'package:image_picker/image_picker.dart';

/// Dữ liệu form đăng ký thợ (chỉ bước cơ bản).
/// Các thông tin nâng cao (chuyên môn, khu vực, xác thực, ngân hàng) được hoàn thiện sau trong app.
/// Bán kính & "sửa tận nơi" do thuật toán quét đơn bên BE quyết định.
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
    // Khu vực (dùng cho thuật toán quét đơn)
    this.province,
    this.district,
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

  // ── Khu vực nhận việc (thuật toán quét đơn tự động) ───────────────────────
  final String? province;
  final String? district;

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
