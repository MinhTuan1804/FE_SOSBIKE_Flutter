class IncomingRescueRequest {
  const IncomingRescueRequest({
    required this.customerName,
    required this.address,
    required this.fullAddress,
    required this.distanceMeters,
    required this.serviceTypeLabel,
    required this.phoneNumber,
    this.avatarUrl,
    this.latitude,
    this.longitude,
  });

  final String customerName;
  final String address;
  final String fullAddress;
  final double distanceMeters;
  final String serviceTypeLabel;
  final String phoneNumber;
  final String? avatarUrl;
  final double? latitude;
  final double? longitude;

  String get distanceLabel {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
    return '${distanceMeters.toStringAsFixed(1).replaceAll('.', ',')}m';
  }

  static const sample = IncomingRescueRequest(
    customerName: 'Khánh Linh',
    address: 'Chung cư petroland, Bình Trưng.',
    fullAddress: 'Chung cư Petroland, đường 62, phường Bình Trưng, Thành phố Thủ Đức.',
    distanceMeters: 400.3,
    serviceTypeLabel: 'LƯU ĐỘNG',
    phoneNumber: '0123456789',
  );
}
