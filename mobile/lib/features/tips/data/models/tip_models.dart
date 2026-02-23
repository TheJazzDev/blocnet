class TipCurrencyFeePolicy {
  const TipCurrencyFeePolicy({
    required this.feeBps,
    required this.minTipAtomic,
    required this.minTip,
    required this.maxTipAtomic,
    required this.maxTip,
    required this.minFeeAtomic,
    required this.minFee,
    required this.maxFeeAtomic,
    required this.maxFee,
    required this.senderPaysFee,
    required this.isActive,
  });

  final int feeBps;
  final String minTipAtomic;
  final String minTip;
  final String? maxTipAtomic;
  final String? maxTip;
  final String minFeeAtomic;
  final String minFee;
  final String? maxFeeAtomic;
  final String? maxFee;
  final bool senderPaysFee;
  final bool isActive;

  factory TipCurrencyFeePolicy.fromApi(Map<String, dynamic> json) {
    return TipCurrencyFeePolicy(
      feeBps: int.tryParse(json['feeBps']?.toString() ?? '') ?? 0,
      minTipAtomic: json['minTipAtomic']?.toString() ?? '0',
      minTip: json['minTip']?.toString() ?? '0',
      maxTipAtomic: json['maxTipAtomic']?.toString(),
      maxTip: json['maxTip']?.toString(),
      minFeeAtomic: json['minFeeAtomic']?.toString() ?? '0',
      minFee: json['minFee']?.toString() ?? '0',
      maxFeeAtomic: json['maxFeeAtomic']?.toString(),
      maxFee: json['maxFee']?.toString(),
      senderPaysFee: json['senderPaysFee'] == true,
      isActive: json['isActive'] == true,
    );
  }
}

class TipCurrency {
  const TipCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.kind,
    required this.isEnabled,
    required this.isActiveTippingCurrency,
    required this.feePolicy,
  });

  final String code;
  final String name;
  final String symbol;
  final int decimals;
  final String kind;
  final bool isEnabled;
  final bool isActiveTippingCurrency;
  final TipCurrencyFeePolicy? feePolicy;

  factory TipCurrency.fromApi(Map<String, dynamic> json) {
    final rawPolicy = json['feePolicy'];
    return TipCurrency(
      code: json['code']?.toString() ?? 'MCR',
      name: json['name']?.toString() ?? 'Mine Credits',
      symbol: json['symbol']?.toString() ?? 'MCR',
      decimals: int.tryParse(json['decimals']?.toString() ?? '') ?? 3,
      kind: json['kind']?.toString() ?? 'points',
      isEnabled: json['isEnabled'] == true,
      isActiveTippingCurrency: json['isActiveTippingCurrency'] == true,
      feePolicy: rawPolicy is Map<String, dynamic>
          ? TipCurrencyFeePolicy.fromApi(rawPolicy)
          : null,
    );
  }
}

class TipBalance {
  const TipBalance({
    required this.currency,
    required this.balanceAtomic,
    required this.balance,
  });

  final TipCurrency currency;
  final String balanceAtomic;
  final String balance;

  factory TipBalance.fromApi(Map<String, dynamic> json) {
    final rawCurrency =
        (json['currency'] as Map?)?.cast<String, dynamic>() ?? {};
    return TipBalance(
      currency: TipCurrency.fromApi(rawCurrency),
      balanceAtomic: json['balanceAtomic']?.toString() ?? '0',
      balance: json['balance']?.toString() ?? '0',
    );
  }
}

class TipOverview {
  const TipOverview({
    required this.activeCurrency,
    required this.balances,
  });

  final TipCurrency activeCurrency;
  final List<TipBalance> balances;

  TipBalance? findBalance(String code) {
    final normalized = code.trim().toUpperCase();
    for (final row in balances) {
      if (row.currency.code.toUpperCase() == normalized) return row;
    }
    return null;
  }

  factory TipOverview.fromApi(Map<String, dynamic> json) {
    final activeRaw =
        (json['activeCurrency'] as Map?)?.cast<String, dynamic>() ?? {};
    final balancesRaw =
        (json['balances'] as List?)?.cast<dynamic>() ?? const [];

    return TipOverview(
      activeCurrency: TipCurrency.fromApi(activeRaw),
      balances: balancesRaw
          .whereType<Map>()
          .map((row) => TipBalance.fromApi(row.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}

class TipUserPreview {
  const TipUserPreview({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  factory TipUserPreview.fromApi(Map<String, dynamic> json) {
    return TipUserPreview(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString(),
      displayName: json['displayName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class TipTransaction {
  const TipTransaction({
    required this.id,
    required this.type,
    required this.direction,
    required this.currency,
    required this.amountAtomic,
    required this.amount,
    required this.feeAtomic,
    required this.fee,
    required this.totalDebitAtomic,
    required this.totalDebit,
    required this.sender,
    required this.recipient,
    required this.note,
    required this.contextType,
    required this.contextId,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String direction;
  final TipCurrency currency;
  final String amountAtomic;
  final String amount;
  final String feeAtomic;
  final String fee;
  final String totalDebitAtomic;
  final String totalDebit;
  final TipUserPreview sender;
  final TipUserPreview recipient;
  final String? note;
  final String? contextType;
  final String? contextId;
  final DateTime createdAt;

  factory TipTransaction.fromApi(Map<String, dynamic> json) {
    final rawCurrency =
        (json['currency'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawSender = (json['sender'] as Map?)?.cast<String, dynamic>() ?? {};
    final rawRecipient =
        (json['recipient'] as Map?)?.cast<String, dynamic>() ?? {};

    return TipTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'tip',
      direction: json['direction']?.toString() ?? 'neutral',
      currency: TipCurrency.fromApi(rawCurrency),
      amountAtomic: json['amountAtomic']?.toString() ?? '0',
      amount: json['amount']?.toString() ?? '0',
      feeAtomic: json['feeAtomic']?.toString() ?? '0',
      fee: json['fee']?.toString() ?? '0',
      totalDebitAtomic: json['totalDebitAtomic']?.toString() ?? '0',
      totalDebit: json['totalDebit']?.toString() ?? '0',
      sender: TipUserPreview.fromApi(rawSender),
      recipient: TipUserPreview.fromApi(rawRecipient),
      note: json['note']?.toString(),
      contextType: json['contextType']?.toString(),
      contextId: json['contextId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class TipHistoryResponse {
  const TipHistoryResponse({
    required this.data,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<TipTransaction> data;
  final int total;
  final int limit;
  final int offset;

  factory TipHistoryResponse.fromApi(Map<String, dynamic> json) {
    final rows = (json['data'] as List?)?.cast<dynamic>() ?? const [];
    return TipHistoryResponse(
      data: rows
          .whereType<Map>()
          .map((row) => TipTransaction.fromApi(row.cast<String, dynamic>()))
          .toList(growable: false),
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      limit: int.tryParse(json['limit']?.toString() ?? '') ?? 20,
      offset: int.tryParse(json['offset']?.toString() ?? '') ?? 0,
    );
  }
}

class TipRecipient {
  const TipRecipient({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isHunterHint = false,
  });

  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool isHunterHint;

  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) {
      return handle.startsWith('@') ? handle : '@$handle';
    }
    return userId;
  }
}
