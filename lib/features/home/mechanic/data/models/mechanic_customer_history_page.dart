import 'package:fe_moblie_flutter/features/home/mechanic/data/models/mechanic_customer_history_entry.dart';

class MechanicCustomerHistoryPage {
  const MechanicCustomerHistoryPage({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.items,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final List<MechanicCustomerHistoryEntry> items;

  factory MechanicCustomerHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return MechanicCustomerHistoryPage(
      page: _toInt(json['page']),
      pageSize: _toInt(json['pageSize']),
      totalCount: _toInt(json['totalCount']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => MechanicCustomerHistoryEntry.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
