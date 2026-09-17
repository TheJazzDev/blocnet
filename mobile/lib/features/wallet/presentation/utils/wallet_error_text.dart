import 'dart:async';
import 'dart:io';

import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/services/wallet/wallet_store.dart';

/// A send or withdrawal error as a sentence a member can act on.
///
/// A 4xx from the API carries a message written for members ("You cannot
/// send BNP to this member"), so it is shown as is. Anything else — server
/// faults, timeouts, exceptions — would surface internals, so it becomes a
/// plain sentence instead.
String walletErrorText(WalletStore store, Object error) {
  if (error is ApiException) {
    final code = error.statusCode ?? 0;
    if (code >= 400 && code < 500 && code != 401) {
      return describeApiError(error, fallback: walletGenericErrorText);
    }
    if (code == 401) return 'Your session expired. Sign in again.';
    if (code == 0) return walletOfflineText;
    return walletGenericErrorText;
  }
  if (error is TimeoutException || error is SocketException) {
    return walletOfflineText;
  }
  return walletGenericErrorText;
}

const String walletOfflineText =
    "Couldn't reach Blocnet. Check your connection and try again.";

const String walletGenericErrorText = 'Something went wrong. Try again.';
