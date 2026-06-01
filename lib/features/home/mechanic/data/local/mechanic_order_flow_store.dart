import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu bước flow đơn đang dở để thợ quay lại từ Lịch sử.
class MechanicOrderFlowSnapshot {
  const MechanicOrderFlowSnapshot({
    required this.orderId,
    required this.flowStep,
    this.selectedServiceIds = const [],
    this.sparePartJson = const [],
  });

  final String orderId;
  final String flowStep;
  final List<String> selectedServiceIds;
  final List<Map<String, dynamic>> sparePartJson;

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'flowStep': flowStep,
        'selectedServiceIds': selectedServiceIds,
        'sparePartJson': sparePartJson,
      };

  factory MechanicOrderFlowSnapshot.fromJson(Map<String, dynamic> json) {
    return MechanicOrderFlowSnapshot(
      orderId: json['orderId']?.toString() ?? '',
      flowStep: json['flowStep']?.toString() ?? 'accept',
      selectedServiceIds: (json['selectedServiceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sparePartJson: (json['sparePartJson'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }
}

class MechanicOrderFlowStore {
  MechanicOrderFlowStore._();

  static const _key = 'mechanic_order_flow_snapshot';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> save(MechanicOrderFlowSnapshot snapshot) async {
    await _storage.write(key: _key, value: jsonEncode(snapshot.toJson()));
  }

  static Future<MechanicOrderFlowSnapshot?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return MechanicOrderFlowSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
