class MechanicWalletTransaction {
  const MechanicWalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isCredit,
    required this.createdAt,
    this.description,
    this.transactionType = '',
    this.status,
  });

  final String id;
  final String title;
  final String? description;
  final int amount;
  final bool isCredit;
  final String transactionType;
  final String? status;
  final DateTime createdAt;

  bool get isPending => status?.toUpperCase() == 'PENDING';

  factory MechanicWalletTransaction.fromJson(Map<String, dynamic> json) {
    return MechanicWalletTransaction(
      id: json['transactionId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Giao dịch ví',
      description: json['description']?.toString(),
      amount: _toInt(json['amount']),
      isCredit: json['isCredit'] == true,
      transactionType: json['transactionType']?.toString() ?? '',
      status: json['status']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static int _toInt(Object? value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get amountLabel {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '${isCredit ? '+' : '-'}$formattedđ';
  }
}

class MechanicWithdrawRequest {
  const MechanicWithdrawRequest({
    required this.id,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.status,
    required this.requestedAt,
    this.rejectionReason,
    this.processedAt,
  });

  final String id;
  final int amount;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String status;
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? processedAt;

  factory MechanicWithdrawRequest.fromJson(Map<String, dynamic> json) {
    return MechanicWithdrawRequest(
      id: json['id']?.toString() ?? '',
      amount: MechanicWalletTransaction._toInt(json['amount']),
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      rejectionReason: json['rejectionReason']?.toString(),
      requestedAt: DateTime.tryParse(json['requestedAt']?.toString() ?? '') ?? DateTime.now(),
      processedAt: DateTime.tryParse(json['processedAt']?.toString() ?? ''),
    );
  }

  String get amountLabel {
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '-$formattedđ';
  }

  String get statusLabel => switch (status.toUpperCase()) {
        'PENDING' => 'Chờ duyệt',
        'APPROVED' => 'Đã duyệt',
        'REJECTED' => 'Từ chối',
        'COMPLETED' => 'Hoàn tất',
        _ => status,
      };

  String get maskedAccount {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }
}

class MechanicWalletData {
  const MechanicWalletData({
    required this.balance,
    required this.transactions,
    this.withdrawRequests = const [],
    this.currency = 'VND',
  });

  final int balance;
  final String currency;
  final List<MechanicWalletTransaction> transactions;
  final List<MechanicWithdrawRequest> withdrawRequests;

  String get balanceLabel {
    final formatted = balance.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }

  factory MechanicWalletData.fromJson(Map<String, dynamic> json) {
    final rawTx = json['recentTransactions'];
    final rawWithdraw = json['recentWithdrawRequests'];
    return MechanicWalletData(
      balance: MechanicWalletTransaction._toInt(json['balance']),
      currency: json['currency']?.toString() ?? 'VND',
      transactions: rawTx is List
          ? rawTx
              .whereType<Map>()
              .map((e) => MechanicWalletTransaction.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      withdrawRequests: rawWithdraw is List
          ? rawWithdraw
              .whereType<Map>()
              .map((e) => MechanicWithdrawRequest.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  static MechanicWalletData get sample => MechanicWalletData(
        balance: 9372000,
        transactions: [
          MechanicWalletTransaction(
            id: '1',
            title: 'Thu nhập sửa xe',
            description: 'Thu nhập đơn sửa xe #001',
            amount: 250000,
            isCredit: true,
            createdAt: DateTime(2026, 3, 15, 14, 35),
          ),
          MechanicWalletTransaction(
            id: '2',
            title: 'Nạp tiền',
            description: 'Nạp tiền ví',
            amount: 500000,
            isCredit: true,
            createdAt: DateTime(2026, 3, 14, 9, 10),
          ),
          MechanicWalletTransaction(
            id: '3',
            title: 'Rút tiền',
            description: 'Rút tiền về ngân hàng',
            amount: 200000,
            isCredit: false,
            createdAt: DateTime(2026, 3, 13, 18, 20),
          ),
        ],
      );
}
