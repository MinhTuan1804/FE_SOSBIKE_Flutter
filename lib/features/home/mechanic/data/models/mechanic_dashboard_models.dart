class MechanicDashboardData {
  const MechanicDashboardData({
    required this.todayRevenue,
    required this.todayOrderCount,
    required this.todayRating,
    required this.overallRating,
    required this.recentTrips,
  });

  final double todayRevenue;
  final int todayOrderCount;
  final double todayRating;
  final double overallRating;
  final List<MechanicTripSummary> recentTrips;

  factory MechanicDashboardData.fromJson(Map<String, dynamic> json) {
    final trips = json['recentTrips'];
    return MechanicDashboardData(
      todayRevenue: _toDouble(json['todayRevenue']),
      todayOrderCount: _toInt(json['todayOrderCount']),
      todayRating: _toDouble(json['todayRating']),
      overallRating: _toDouble(json['overallRating']),
      recentTrips: trips is List
          ? trips
              .whereType<Map>()
              .map((item) => MechanicTripSummary.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Demo data matching Figma when API returns empty stats.
  static MechanicDashboardData get sample => MechanicDashboardData(
        todayRevenue: 500000,
        todayOrderCount: 5,
        todayRating: 4.8,
        overallRating: 4.8,
        recentTrips: [
          MechanicTripSummary(
            orderId: 'sample-1',
            status: 'COMPLETED',
            requestAddress: '45 Nguyễn Văn Linh, Q.7',
            totalAmount: 180000,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          MechanicTripSummary(
            orderId: 'sample-2',
            status: 'COMPLETED',
            requestAddress: '12 Lê Văn Việt, TP.Thủ Đức',
            totalAmount: 320000,
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      );

  bool get isEmptyStats =>
      todayRevenue == 0 && todayOrderCount == 0 && recentTrips.isEmpty;

  MechanicDashboardData withSampleIfEmpty() {
    if (!isEmptyStats) return this;
    return sample;
  }
}

class MechanicTripSummary {
  const MechanicTripSummary({
    required this.orderId,
    required this.status,
    required this.requestAddress,
    required this.totalAmount,
    required this.createdAt,
  });

  final String orderId;
  final String status;
  final String requestAddress;
  final double totalAmount;
  final DateTime createdAt;

  factory MechanicTripSummary.fromJson(Map<String, dynamic> json) {
    return MechanicTripSummary(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      requestAddress: json['requestAddress']?.toString() ?? '',
      totalAmount: MechanicDashboardData._toDouble(json['totalAmount']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
