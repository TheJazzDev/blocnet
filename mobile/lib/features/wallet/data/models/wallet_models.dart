class WalletAssetBalance {
  WalletAssetBalance({
    required this.asset,
    required this.symbol,
    required this.name,
    required this.network,
    required this.assetKind,
    required this.available,
    required this.pending,
    required this.locked,
    required this.usdPrice,
    required this.usdValue,
    required this.priceSource,
  });

  final String asset;
  final String symbol;
  final String name;
  final String network;
  final String assetKind;
  final String available;
  final String pending;
  final String locked;
  final String usdPrice;
  final String usdValue;
  final String priceSource;

  bool get isNative => assetKind.toLowerCase() == 'native';
  bool get isErc20 => assetKind.toLowerCase() == 'erc20';

  factory WalletAssetBalance.fromApi(Map<String, dynamic> json) {
    return WalletAssetBalance(
      asset: json['asset']?.toString().toUpperCase() ?? 'BNT',
      symbol: json['symbol']?.toString().toUpperCase() ?? 'BNT',
      name: json['name']?.toString() ?? 'Blocnet',
      network: json['network']?.toString() ?? 'BSC',
      assetKind: json['assetKind']?.toString() ?? 'erc20',
      available: json['available']?.toString() ?? '0',
      pending: json['pending']?.toString() ?? '0',
      locked: json['locked']?.toString() ?? '0',
      usdPrice: json['usdPrice']?.toString() ?? '0',
      usdValue: json['usdValue']?.toString() ?? '0',
      priceSource: json['priceSource']?.toString() ?? 'fallback',
    );
  }
}

class WalletSnapshot {
  WalletSnapshot({
    required this.walletStatus,
    required this.walletAddress,
    required this.walletChainEnvironment,
    required this.walletChainId,
    required this.available,
    required this.pending,
    required this.locked,
    required this.kycStatus,
    required this.kycTier,
    required this.assets,
    required this.totalUsdValue,
    required this.supportedAssets,
    required this.transferEnabledAssets,
    required this.withdrawalEnabledAssets,
  });

  final String walletStatus;
  final String? walletAddress;
  final String walletChainEnvironment;
  final int? walletChainId;
  final String available;
  final String pending;
  final String locked;
  final String kycStatus;
  final String kycTier;
  final List<WalletAssetBalance> assets;
  final String totalUsdValue;
  final List<String> supportedAssets;
  final List<String> transferEnabledAssets;
  final List<String> withdrawalEnabledAssets;

  WalletAssetBalance? get primaryAsset => assets.isEmpty ? null : assets.first;

  WalletAssetBalance? findAsset(String assetCode) {
    final code = assetCode.toUpperCase();
    for (final item in assets) {
      if (item.asset.toUpperCase() == code) {
        return item;
      }
    }
    return null;
  }

  bool isTransferEnabledFor(String assetCode) {
    if (transferEnabledAssets.isEmpty) {
      return assetCode.toUpperCase() == 'BNT';
    }
    return transferEnabledAssets.contains(assetCode.toUpperCase());
  }

  bool isWithdrawalEnabledFor(String assetCode) {
    if (withdrawalEnabledAssets.isEmpty) {
      return assetCode.toUpperCase() == 'BNT';
    }
    return withdrawalEnabledAssets.contains(assetCode.toUpperCase());
  }

  factory WalletSnapshot.fromApi(Map<String, dynamic> json) {
    final wallet = (json['wallet'] as Map?)?.cast<String, dynamic>() ?? {};
    final balances = (json['balances'] as Map?)?.cast<String, dynamic>() ?? {};
    final kyc = (json['kyc'] as Map?)?.cast<String, dynamic>() ?? {};
    final totals = (json['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    final features = (json['features'] as Map?)?.cast<String, dynamic>() ?? {};

    final assets = (json['assets'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(WalletAssetBalance.fromApi)
        .toList();

    final bntAsset = assets.cast<WalletAssetBalance?>().firstWhere(
          (asset) => asset?.asset.toUpperCase() == 'BNT',
          orElse: () => null,
        );

    List<String> readAssetCodes(Object? value) {
      if (value is! List) {
        return const [];
      }
      return value
          .map((entry) => entry.toString().toUpperCase())
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList();
    }

    final supportedAssets = readAssetCodes(features['supportedAssets']);
    final transferEnabledAssets =
        readAssetCodes(features['transferEnabledAssets']);
    final withdrawalEnabledAssets =
        readAssetCodes(features['withdrawalEnabledAssets']);

    return WalletSnapshot(
      walletStatus: wallet['status']?.toString() ?? 'provisioning',
      walletAddress: wallet['address']?.toString(),
      walletChainEnvironment:
          wallet['chainEnvironment']?.toString() ?? 'testnet',
      walletChainId: wallet['chainId'] is num
          ? (wallet['chainId'] as num).toInt()
          : int.tryParse(wallet['chainId']?.toString() ?? ''),
      available: balances['available']?.toString() ??
          bntAsset?.available ??
          (assets.isNotEmpty ? assets.first.available : '0'),
      pending: balances['pending']?.toString() ?? bntAsset?.pending ?? '0',
      locked: balances['locked']?.toString() ?? bntAsset?.locked ?? '0',
      kycStatus: kyc['status']?.toString() ?? 'not_submitted',
      kycTier: kyc['tier']?.toString() ?? 'basic',
      assets: assets,
      totalUsdValue: totals['usdValue']?.toString() ?? '0',
      supportedAssets: supportedAssets,
      transferEnabledAssets: transferEnabledAssets,
      withdrawalEnabledAssets: withdrawalEnabledAssets,
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
    required this.asset,
    required this.referenceId,
    required this.metadata,
    required this.debit,
    required this.credit,
    required this.counterparty,
    required this.createdAt,
  });

  final String id;
  final String direction;
  final String reason;
  final String amount;
  final String feeAmount;
  final String asset;
  final String? referenceId;
  final Map<String, dynamic>? metadata;
  final WalletTransactionParty? debit;
  final WalletTransactionParty? credit;
  final WalletTransactionCounterparty? counterparty;
  final DateTime? createdAt;

  bool get isOutgoing => direction == 'outgoing';
  bool get isIncoming => direction == 'incoming';

  String? metadataString(String key) {
    final value = metadata?[key];
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  int? metadataInt(String key) {
    final value = metadata?[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory WalletTransaction.fromApi(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    Map<String, dynamic>? parseMap(Object? raw) {
      if (raw is Map) {
        return raw.map((key, value) => MapEntry(key.toString(), value));
      }
      return null;
    }

    final debitMap = parseMap(json['debit']);
    final creditMap = parseMap(json['credit']);
    final counterpartyMap = parseMap(json['counterparty']);

    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'internal',
      reason: json['reason']?.toString() ?? 'unknown',
      amount: json['amount']?.toString() ?? '0',
      feeAmount: json['feeAmount']?.toString() ?? '0',
      asset: json['asset']?.toString().toUpperCase() ?? 'BNT',
      referenceId: json['referenceId']?.toString(),
      metadata: parseMap(json['metadata']),
      debit: debitMap == null ? null : WalletTransactionParty.fromApi(debitMap),
      credit:
          creditMap == null ? null : WalletTransactionParty.fromApi(creditMap),
      counterparty: counterpartyMap == null
          ? null
          : WalletTransactionCounterparty.fromApi(counterpartyMap),
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }
}

class WalletTransactionParty {
  WalletTransactionParty({
    required this.userId,
    required this.accountType,
  });

  final String? userId;
  final String accountType;

  factory WalletTransactionParty.fromApi(Map<String, dynamic> json) {
    return WalletTransactionParty(
      userId: json['userId']?.toString(),
      accountType: json['accountType']?.toString() ?? 'user',
    );
  }
}

class WalletTransactionCounterparty {
  WalletTransactionCounterparty({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.walletAddress,
  });

  final String? userId;
  final String? username;
  final String? displayName;
  final String? walletAddress;

  String? get preferredLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return '@${username!.trim()}';
    }
    return null;
  }

  factory WalletTransactionCounterparty.fromApi(Map<String, dynamic> json) {
    return WalletTransactionCounterparty(
      userId: json['userId']?.toString(),
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      walletAddress: json['walletAddress']?.toString(),
    );
  }
}

class WalletWithdrawalRequest {
  WalletWithdrawalRequest({
    required this.id,
    required this.status,
    required this.toAddress,
    required this.amount,
    required this.feeAmount,
    required this.netAmount,
    required this.reason,
    required this.rejectReason,
    required this.failureReason,
    required this.broadcastTxHash,
    required this.asset,
    required this.requestedAt,
    required this.reviewedAt,
    required this.confirmedAt,
  });

  final String id;
  final String status;
  final String toAddress;
  final String amount;
  final String feeAmount;
  final String netAmount;
  final String reason;
  final String? rejectReason;
  final String? failureReason;
  final String? broadcastTxHash;
  final String asset;
  final DateTime? requestedAt;
  final DateTime? reviewedAt;
  final DateTime? confirmedAt;

  factory WalletWithdrawalRequest.fromApi(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final raw = json[key]?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return WalletWithdrawalRequest(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending_review',
      toAddress: json['toAddress']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      feeAmount: json['feeAmount']?.toString() ?? '0',
      netAmount: json['netAmount']?.toString() ?? '0',
      reason: json['reason']?.toString() ?? '',
      rejectReason: json['rejectReason']?.toString(),
      failureReason: json['failureReason']?.toString(),
      broadcastTxHash: json['broadcastTxHash']?.toString(),
      asset: json['asset']?.toString().toUpperCase() ?? 'BNT',
      requestedAt: parseDate('requestedAt'),
      reviewedAt: parseDate('reviewedAt'),
      confirmedAt: parseDate('confirmedAt'),
    );
  }
}
