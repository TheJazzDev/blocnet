import 'package:intl/intl.dart';

String formatDateWithSuffix(DateTime date) {
  // Format the month and year
  final DateFormat monthYearFormat = DateFormat('MMM yyyy');
  String formattedDate = monthYearFormat.format(date);

  // Get the day of the month
  final int day = date.day;

  // Determine the suffix for the day
  String suffix;
  if (day >= 11 && day <= 13) {
    suffix = 'th';
  } else {
    switch (day % 10) {
      case 1:
        suffix = 'st';
        break;
      case 2:
        suffix = 'nd';
        break;
      case 3:
        suffix = 'rd';
        break;
      default:
        suffix = 'th';
        break;
    }
  }

  // Append the day with the suffix to the formatted date
  return '$day$suffix $formattedDate';
}
