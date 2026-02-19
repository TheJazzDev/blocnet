class WalletSnapshot {
  WalletSnapshot({
    required this.walletStatus,
    required this.walletAddress,
    required this.available,
    required this.pending,
    required this.locked,
    required this.kycStatus,
    required this.kycTier,
  });

  final String walletStatus;
  final String? walletAddress;
  final String available;
  final String pending;
  final String locked;
  final String kycStatus;
  final String kycTier;

  factory WalletSnapshot.fromApi(Map<String, dynamic> json) {
    final wallet = (json['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
    final balances = (json['balances'] as Map?)?.cast<String, dynamic>() ?? {};
    final kyc = (json['kyc'] as Map?)?.cast<String, dynamic>() ?? {};

    return WalletSnapshot(
      walletStatus: wallet['status']?.toString() ?? 'provisioning',
      walletAddress: wallet['address']?.toString(),
      available: balances['available']?.toString() ?? '0',
      pending: balances['pending']?.toString() ?? '0',
      locked: balances['locked']?.toString() ?? '0',
      kycStatus: kyc['status']?.toString() ?? 'not_submitted',
      kycTier: kyc['tier']?.toString() ?? 'basic',
    );
  }
}

class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.direction,
    required this.reason,
    required this.amount,
    required this.feeAmount,
    required this.createdAt,
  });

  final String id;
  final String direction;
  final String reason;
  final String amount;
  final String feeAmount;
  final DateTime? createdAt;

  factory WalletTransaction.fromApi(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'internal',
      reason: json['reason']?.toString() ?? 'unknown',
      amount: json['amount']?.toString() ?? '0',
      feeAmount: json['feeAmount']?.toString() ?? '0',
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }
}
