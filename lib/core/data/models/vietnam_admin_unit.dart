class VietnamProvince {
  const VietnamProvince({
    required this.code,
    required this.name,
    required this.districts,
  });

  final int code;
  final String name;
  final List<VietnamDistrict> districts;
}

class VietnamDistrict {
  const VietnamDistrict({
    required this.code,
    required this.name,
    required this.provinceCode,
    required this.wards,
  });

  final int code;
  final String name;
  final int provinceCode;
  final List<VietnamWard> wards;
}

class VietnamWard {
  const VietnamWard({
    required this.code,
    required this.name,
    required this.districtCode,
  });

  final int code;
  final String name;
  final int districtCode;
}
