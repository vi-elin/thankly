import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Formats an hour/minute for display, following each locale's usual time
/// convention: 24-hour ("15:00") for Ukrainian, 12-hour with AM/PM
/// ("3:00 PM") otherwise.
String formatTimeOfDay(BuildContext context, int hour, int minute) {
  final displayMinute = minute.toString().padLeft(2, '0');

  if (context.locale.languageCode == 'uk') {
    return '${hour.toString().padLeft(2, '0')}:$displayMinute';
  }

  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$displayMinute $period';
}
