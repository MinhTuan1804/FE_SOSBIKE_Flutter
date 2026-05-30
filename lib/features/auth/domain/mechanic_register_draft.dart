import 'package:image_picker/image_picker.dart';

/// Dữ liệu form đăng ký thợ trước bước mật khẩu.
class MechanicRegisterDraft {
  const MechanicRegisterDraft({
    required this.phoneNumber,
    required this.fullName,
    required this.identityCard,
    required this.dateOfBirth,
    required this.currentAddress,
    required this.licensePlate,
    required this.vehicleModel,
    required this.vehicleGeneration,
    required this.driverLicenseNumber,
    this.email,
    this.bankCode,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.portraitFile,
    this.vehicleRegistrationFile,
    this.vehicleInsuranceFile,
  });

  final String phoneNumber;
  final String fullName;
  final String identityCard;
  final DateTime dateOfBirth;
  final String currentAddress;
  final String? email;
  final String licensePlate;
  final String vehicleModel;
  final String vehicleGeneration;
  final String driverLicenseNumber;
  final String? bankCode;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final XFile? portraitFile;
  final XFile? vehicleRegistrationFile;
  final XFile? vehicleInsuranceFile;
}
