class UserProfileDto {
  const UserProfileDto({
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    required this.userType,
    this.email,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.currentAddress,
    this.mechanic,
    this.wallet,
  });

  final String userId;
  final String phoneNumber;
  final String fullName;
  final String userType;
  final String? email;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? currentAddress;
  final MechanicProfileDto? mechanic;
  final WalletProfileDto? wallet;

  bool get isMechanic => userType.toUpperCase() == 'MECHANIC';

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final mechanicJson = json['mechanic'] as Map<String, dynamic>?;
    final walletJson = json['wallet'] as Map<String, dynamic>?;
    DateTime? dob;
    final dobRaw = json['dateOfBirth'] ?? json['dateofbirth'];
    if (dobRaw is String && dobRaw.isNotEmpty) {
      dob = DateTime.tryParse(dobRaw);
    }

    return UserProfileDto(
      userId: '${json['userId'] ?? json['userid'] ?? ''}',
      phoneNumber: '${json['phoneNumber'] ?? json['phonenumber'] ?? ''}',
      fullName: '${json['fullName'] ?? json['fullname'] ?? ''}',
      userType: '${json['userType'] ?? json['usertype'] ?? 'CUSTOMER'}',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatarurl'] as String?,
      dateOfBirth: dob,
      gender: json['gender'] as String?,
      currentAddress: json['currentAddress'] as String? ?? json['currentaddress'] as String?,
      mechanic: mechanicJson == null ? null : MechanicProfileDto.fromJson(mechanicJson),
      wallet: walletJson == null ? null : WalletProfileDto.fromJson(walletJson),
    );
  }
}

class MechanicProfileDto {
  const MechanicProfileDto({
    required this.identityCard,
    required this.licensePlate,
    this.vehicleModel,
    this.vehicleGeneration,
    this.driverLicenseNumber,
    this.vehicleRegistrationUrl,
    this.vehicleInsuranceUrl,
  });

  final String identityCard;
  final String licensePlate;
  final String? vehicleModel;
  final String? vehicleGeneration;
  final String? driverLicenseNumber;
  final String? vehicleRegistrationUrl;
  final String? vehicleInsuranceUrl;

  factory MechanicProfileDto.fromJson(Map<String, dynamic> json) {
    return MechanicProfileDto(
      identityCard: '${json['identityCard'] ?? json['identitycard'] ?? ''}',
      licensePlate: '${json['licensePlate'] ?? json['licenseplate'] ?? ''}',
      vehicleModel: json['vehicleModel'] as String? ?? json['vehiclemodel'] as String?,
      vehicleGeneration:
          json['vehicleGeneration'] as String? ?? json['vehiclegeneration'] as String?,
      driverLicenseNumber:
          json['driverLicenseNumber'] as String? ?? json['driverlicensenumber'] as String?,
      vehicleRegistrationUrl: json['vehicleRegistrationUrl'] as String? ??
          json['vehicleregistrationurl'] as String?,
      vehicleInsuranceUrl:
          json['vehicleInsuranceUrl'] as String? ?? json['vehicleinsuranceurl'] as String?,
    );
  }
}

class WalletProfileDto {
  const WalletProfileDto({
    this.balance,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
  });

  final num? balance;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;

  factory WalletProfileDto.fromJson(Map<String, dynamic> json) {
    return WalletProfileDto(
      balance: json['balance'] as num?,
      bankName: json['bankName'] as String? ?? json['bankname'] as String?,
      bankAccountNumber:
          json['bankAccountNumber'] as String? ?? json['bankaccountnumber'] as String?,
      bankAccountHolder:
          json['bankAccountHolder'] as String? ?? json['bankaccountholder'] as String?,
    );
  }
}
