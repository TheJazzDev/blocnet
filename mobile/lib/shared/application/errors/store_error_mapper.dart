import 'package:blocnet/services/api/api_error.dart';

class StoreErrorMapper {
  const StoreErrorMapper();

  String map(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    return describeApiError(error, fallback: fallback);
  }
}
