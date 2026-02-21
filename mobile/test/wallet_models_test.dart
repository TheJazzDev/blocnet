import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WalletSnapshot', () {
    test('parses nested wallet summary payload', () {
      final snapshot = WalletSnapshot.fromApi({
        'wallet': {
          'status': 'ready',
          'address': '0x1234567890abcdef1234567890abcdef12345678',
        },
        'balances': {
          'available': '12.50',
          'pending': '1.00',
          'locked': '0.25',
        },
        'kyc': {
          'status': 'approved',
          'tier': 'pro',
        },
      });

      expect(snapshot.walletStatus, 'ready');
      expect(
          snapshot.walletAddress, '0x1234567890abcdef1234567890abcdef12345678');
      expect(snapshot.available, '12.50');
      expect(snapshot.pending, '1.00');
      expect(snapshot.locked, '0.25');
      expect(snapshot.kycStatus, 'approved');
      expect(snapshot.kycTier, 'pro');
    });
  });

  group('WalletWithdrawalRequest', () {
    test('parses withdrawal response and optional fields', () {
      final withdrawal = WalletWithdrawalRequest.fromApi({
        'id': 'wd-1',
        'status': 'pending_review',
        'toAddress': '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd',
        'amount': '5',
        'feeAmount': '0.1',
        'netAmount': '4.9',
        'reason': 'user request',
        'requestedAt': '2026-02-20T12:00:00.000Z',
      });

      expect(withdrawal.id, 'wd-1');
      expect(withdrawal.status, 'pending_review');
      expect(
          withdrawal.toAddress, '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd');
      expect(withdrawal.amount, '5');
      expect(withdrawal.feeAmount, '0.1');
      expect(withdrawal.netAmount, '4.9');
      expect(withdrawal.reason, 'user request');
      expect(
          withdrawal.requestedAt, DateTime.parse('2026-02-20T12:00:00.000Z'));
      expect(withdrawal.reviewedAt, isNull);
      expect(withdrawal.confirmedAt, isNull);
    });
  });
}
