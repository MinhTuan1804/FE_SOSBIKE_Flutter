class MechanicWalletTransaction {
  const MechanicWalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.isCredit,
    required this.createdAt,
    this.description,
    this.transactionType = '',
  });

  final String id;
  final String title;
  final String? description;
  final int amount;
  final bool isCredit;
  final String transactionType;
  final DateTime createdAt;

  factory MechanicWalletTransaction.fromJson(Map<String, dynamic> json) {
    return MechanicWalletTransaction(
      id: json['transactionId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Giao dịch ví',
      description: json['description']?.toString(),
      amount: _toInt(json['amount']),
      isCredit: json['isCredit'] == true,
      transactionType: json['transactionType']?.toString() ?? '',
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

class MechanicWalletData {
  const MechanicWalletData({
    required this.balance,
    required this.transactions,
    this.currency = 'VND',
  });

  final int balance;
  final String currency;
  final List<MechanicWalletTransaction> transactions;

  String get balanceLabel {
    final formatted = balance.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1) ?? ''}.',
        );
    return '$formattedđ';
  }

  factory MechanicWalletData.fromJson(Map<String, dynamic> json) {
    final rawTx = json['recentTransactions'];
    return MechanicWalletData(
      balance: MechanicWalletTransaction._toInt(json['balance']),
      currency: json['currency']?.toString() ?? 'VND',
      transactions: rawTx is List
          ? rawTx
              .whereType<Map>()
              .map((e) => MechanicWalletTransaction.fromJson(Map<String, dynamic>.from(e)))
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
