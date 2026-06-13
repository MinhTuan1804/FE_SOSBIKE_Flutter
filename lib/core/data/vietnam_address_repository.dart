import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:fe_moblie_flutter/core/data/models/vietnam_address_selection.dart';
import 'package:fe_moblie_flutter/core/data/models/vietnam_admin_unit.dart';

/// Nguồn dữ liệu tĩnh từ https://provinces.open-api.vn (bundled JSON).
class VietnamAddressRepository {
  VietnamAddressRepository._();

  static final VietnamAddressRepository instance = VietnamAddressRepository._();

  static const _assetPath = 'assets/data/vietnam/admin_units.json';

  List<VietnamProvince>? _provinces;
  Future<List<VietnamProvince>>? _loading;

  Future<List<VietnamProvince>> loadProvinces() {
    if (_provinces != null) return Future.value(_provinces!);
    _loading ??= _loadFromAsset();
    return _loading!;
  }

  Future<List<VietnamProvince>> _loadFromAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(raw) as List<dynamic>;

    _provinces = list.map((item) {
      final map = item as Map<String, dynamic>;
      final districts = (map['districts'] as List<dynamic>? ?? [])
          .map((d) {
            final dm = d as Map<String, dynamic>;
            final wards = (dm['wards'] as List<dynamic>? ?? [])
                .map(
                  (w) => VietnamWard(
                    code: w['code'] as int,
                    name: w['name'] as String,
                    districtCode: dm['code'] as int,
                  ),
                )
                .toList();
            return VietnamDistrict(
              code: dm['code'] as int,
              name: dm['name'] as String,
              provinceCode: map['code'] as int,
              wards: wards,
            );
          })
          .toList();

      return VietnamProvince(
        code: map['code'] as int,
        name: map['name'] as String,
        districts: districts,
      );
    }).toList();

    return _provinces!;
  }

  List<VietnamDistrict> districtsOf(int provinceCode) {
    final province = _provinces?.firstWhere(
      (p) => p.code == provinceCode,
      orElse: () => const VietnamProvince(code: -1, name: '', districts: []),
    );
    return province?.districts ?? const [];
  }

  List<VietnamWard> wardsOf(int districtCode) {
    for (final province in _provinces ?? const <VietnamProvince>[]) {
      for (final district in province.districts) {
        if (district.code == districtCode) return district.wards;
      }
    }
    return const [];
  }

  VietnamAddressSelection? parseAddress(String? raw) {
    if (raw == null || raw.trim().isEmpty || _provinces == null) return null;

    final parts = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return null;

    VietnamProvince? province;
    VietnamDistrict? district;
    VietnamWard? ward;
    String? street;

    for (var i = parts.length - 1; i >= 0; i--) {
      province ??= _matchProvince(parts[i]);
      if (province != null) {
        if (i > 0) district ??= _matchDistrict(parts[i - 1], province);
        if (district != null && i > 1) ward ??= _matchWard(parts[i - 2], district);
        break;
      }
    }

    if (province == null) return VietnamAddressSelection(streetDetail: raw.trim());

    final used = <String>{
      province.name,
      if (district != null) district.name,
      if (ward != null) ward.name,
    };
    final streetParts = parts.where((p) => !_matchesAnyNormalized(p, used)).toList();
    if (streetParts.isNotEmpty) street = streetParts.join(', ');

    return VietnamAddressSelection(
      provinceCode: province.code,
      provinceName: province.name,
      districtCode: district?.code,
      districtName: district?.name,
      wardCode: ward?.code,
      wardName: ward?.name,
      streetDetail: street,
    );
  }

  VietnamProvince? _matchProvince(String value) {
    final target = _normalize(value);
    for (final p in _provinces!) {
      final name = _normalize(p.name);
      if (name == target || name.contains(target) || target.contains(name)) {
        return p;
      }
    }
    return null;
  }

  VietnamDistrict? _matchDistrict(String value, VietnamProvince province) {
    final target = _normalize(value);
    for (final d in province.districts) {
      final name = _normalize(d.name);
      if (name == target || name.contains(target) || target.contains(name)) {
        return d;
      }
    }
    return null;
  }

  VietnamWard? _matchWard(String value, VietnamDistrict district) {
    final target = _normalize(value);
    for (final w in district.wards) {
      final name = _normalize(w.name);
      if (name == target || name.contains(target) || target.contains(name)) {
        return w;
      }
    }
    return null;
  }

  bool _matchesAnyNormalized(String value, Set<String> names) {
    final target = _normalize(value);
    for (final name in names) {
      final n = _normalize(name);
      if (n == target || n.contains(target) || target.contains(n)) return true;
    }
    return false;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('thành phố', '')
        .replaceAll('thanh pho', '')
        .replaceAll('tỉnh', '')
        .replaceAll('tinh', '')
        .replaceAll('quận', '')
        .replaceAll('quan', '')
        .replaceAll('huyện', '')
        .replaceAll('huyen', '')
        .replaceAll('thị xã', '')
        .replaceAll('thi xa', '')
        .replaceAll('phường', '')
        .replaceAll('phuong', '')
        .replaceAll('xã', '')
        .replaceAll('xa', '')
        .replaceAll('thị trấn', '')
        .replaceAll('thi tran', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
