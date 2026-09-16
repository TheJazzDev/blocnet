import 'package:blocnet/features/wallet/data/models/wallet_models.dart';
import 'package:blocnet/features/wallet/presentation/utils/wallet_headline.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _asset(
  String code, {
  String available = '0',
  String usdValue = '0',
  String priceSource = 'fallback',
}) {
  return {
    'asset': code,
    'symbol': code,
    'available': available,
    'usdValue': usdValue,
    'usdPrice': '0',
    'priceSource': priceSource,
  };
}

WalletSnapshot _snapshot(List<Map<String, dynamic>> assets) {
  return WalletSnapshot.fromApi({
    'wallet': {'status': 'ready', 'address': '0xabc'},
    'assets': assets,
    // The backend total also counts fallback prices; the headline must not.
    'totals': {'usdValue': '999'},
  });
}

void main() {
  group('WalletHeadline', () {
    test('no wallet yet reads as zero dollars, not pre-launch', () {
      final headline = WalletHeadline.from(null);
      expect(headline.amount, r'$0.00');
      expect(headline.note, isNull);
    });

    test('empty balances with no prices read as zero dollars', () {
      final headline = WalletHeadline.from(_snapshot([
        _asset('BNT'),
        _asset('BNB'),
        _asset('USDT'),
      ]));
      expect(headline.amount, r'$0.00');
      expect(headline.otherHoldings, isNull);
      expect(headline.note, isNull);
    });

    test('held tokens without prices lead with the real holdings', () {
      final headline = WalletHeadline.from(_snapshot([
        _asset('BNT'),
        _asset('BNB', available: '0.02'),
        _asset('USDT', available: '10'),
      ]));
      expect(headline.amount, '0.02 BNB');
      expect(headline.otherHoldings, '+ 10 USDT');
      expect(headline.note, isNot(contains('BNT')));
      expect(headline.amount, isNot(contains('Pre-launch')));
    });

    test('only BNT is described as pending', () {
      final headline = WalletHeadline.from(_snapshot([
        _asset('BNT', available: '125'),
      ]));
      expect(headline.amount, '125 BNT');
      expect(headline.note, 'BNT price pending until it launches on BSC.');
    });

    test('live prices give a USD total of live-priced assets only', () {
      final headline = WalletHeadline.from(_snapshot([
        _asset('BNT', available: '125', usdValue: '50'),
        _asset('BNB', available: '0.1', usdValue: '60', priceSource: 'live'),
        _asset('USDT', available: '10', usdValue: '10', priceSource: 'live'),
      ]));
      expect(headline.amount, r'$70.00');
      expect(headline.otherHoldings, isNull);
      expect(headline.note, contains('Excludes 125 BNT'));
      expect(headline.note, contains('BNT price pending'));
    });

    test('a fully priced wallet carries no caveat', () {
      final headline = WalletHeadline.from(_snapshot([
        _asset('BNT'),
        _asset('USDT', available: '10', usdValue: '10', priceSource: 'live'),
      ]));
      expect(headline.amount, r'$10.00');
      expect(headline.note, isNull);
    });
  });

  test('unpriced asset labels keep pre-launch for BNT only', () {
    WalletAssetBalance asset(String code) =>
        WalletAssetBalance.fromApi(_asset(code));
    expect(walletUnpricedLabel(asset('BNT')), 'Pre-launch');
    expect(walletUnpricedLabel(asset('USDT')), 'No USD price');
    expect(walletUnpricedLabel(asset('BNB')), 'No USD price');
  });
}
