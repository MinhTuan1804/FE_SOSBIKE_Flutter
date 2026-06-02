import 'package:fe_moblie_flutter/features/home/customer/data/models/customer_order_history_entry.dart';

class CustomerOrderHistoryPage {
  const CustomerOrderHistoryPage({
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.items,
  });

  final int page;
  final int pageSize;
  final int totalCount;
  final List<CustomerOrderHistoryEntry> items;

  factory CustomerOrderHistoryPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return CustomerOrderHistoryPage(
      page: _toInt(json['page']),
      pageSize: _toInt(json['pageSize']),
      totalCount: _toInt(json['totalCount']),
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => CustomerOrderHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
