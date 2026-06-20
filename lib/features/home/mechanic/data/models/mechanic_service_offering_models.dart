class MechanicServiceOfferingDto {
  const MechanicServiceOfferingDto({
    required this.mechanicServiceId,
    required this.serviceName,
    required this.laborFee,
    required this.status,
    required this.requestedAt,
    this.description,
    this.rejectionReason,
    this.reviewedAt,
    this.catalogServiceId,
  });

  final int mechanicServiceId;
  final String serviceName;
  final String? description;
  final int laborFee;
  final String status;
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final int? catalogServiceId;

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  factory MechanicServiceOfferingDto.fromJson(Map<String, dynamic> json) {
    return MechanicServiceOfferingDto(
      mechanicServiceId: (json['mechanicServiceId'] as num).toInt(),
      serviceName: json['serviceName'] as String? ?? '',
      description: json['description'] as String?,
      laborFee: (json['laborFee'] as num).round(),
      status: json['status'] as String? ?? 'PENDING',
      rejectionReason: json['rejectionReason'] as String?,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      reviewedAt: json['reviewedAt'] != null ? DateTime.tryParse(json['reviewedAt'] as String) : null,
      catalogServiceId: json['catalogServiceId'] != null ? (json['catalogServiceId'] as num).toInt() : null,
    );
  }
}

class CreateMechanicServicePayload {
  const CreateMechanicServicePayload({
    required this.serviceName,
    required this.laborFee,
    this.description,
  });

  final String serviceName;
  final int laborFee;
  final String? description;

  Map<String, dynamic> toJson() => {
        'serviceName': serviceName,
        'laborFee': laborFee,
        if (description != null && description!.isNotEmpty) 'description': description,
      };
}
