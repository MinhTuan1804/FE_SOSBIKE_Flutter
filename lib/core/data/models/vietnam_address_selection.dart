class VietnamAddressSelection {
  const VietnamAddressSelection({
    this.provinceCode,
    this.provinceName,
    this.districtCode,
    this.districtName,
    this.wardCode,
    this.wardName,
    this.streetDetail,
  });

  final int? provinceCode;
  final String? provinceName;
  final int? districtCode;
  final String? districtName;
  final int? wardCode;
  final String? wardName;
  final String? streetDetail;

  bool get hasProvince => provinceName != null && provinceName!.isNotEmpty;

  bool get hasDistrict => districtName != null && districtName!.isNotEmpty;

  bool get hasWard => wardName != null && wardName!.isNotEmpty;

  /// Địa chỉ đầy đủ: số nhà, phường, quận, tỉnh.
  String get formattedFullAddress {
    final parts = <String>[
      if (streetDetail != null && streetDetail!.trim().isNotEmpty) streetDetail!.trim(),
      if (wardName != null && wardName!.trim().isNotEmpty) wardName!.trim(),
      if (districtName != null && districtName!.trim().isNotEmpty) districtName!.trim(),
      if (provinceName != null && provinceName!.trim().isNotEmpty) provinceName!.trim(),
    ];
    return parts.join(', ');
  }

  /// Khu vực thợ: quận, tỉnh (giữ format BE hiện tại).
  String get formattedServiceArea {
    final parts = <String>[
      if (districtName != null && districtName!.trim().isNotEmpty) districtName!.trim(),
      if (provinceName != null && provinceName!.trim().isNotEmpty) provinceName!.trim(),
    ];
    return parts.join(', ');
  }

  VietnamAddressSelection copyWith({
    int? provinceCode,
    String? provinceName,
    int? districtCode,
    String? districtName,
    int? wardCode,
    String? wardName,
    String? streetDetail,
    bool clearDistrict = false,
    bool clearWard = false,
    bool clearStreet = false,
  }) {
    return VietnamAddressSelection(
      provinceCode: provinceCode ?? this.provinceCode,
      provinceName: provinceName ?? this.provinceName,
      districtCode: clearDistrict ? null : (districtCode ?? this.districtCode),
      districtName: clearDistrict ? null : (districtName ?? this.districtName),
      wardCode: clearWard ? null : (wardCode ?? this.wardCode),
      wardName: clearWard ? null : (wardName ?? this.wardName),
      streetDetail: clearStreet ? null : (streetDetail ?? this.streetDetail),
    );
  }
}
