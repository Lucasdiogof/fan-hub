import 'package:intl/intl.dart';
import 'package:goias_app/l10n/app_localizations.dart';

String _pad(int value) => value.toString().padLeft(2, '0');

String shortDateLabel(DateTime date, String locale) {
  final month = DateFormat('MMM', locale).format(date).toUpperCase();
  return '${_pad(date.day)} $month';
}

String longDateLabel(DateTime date, AppLocalizations l10n, String locale) {
  final month = DateFormat('MMMM', locale).format(date);
  return l10n.datePrepositionFull(date.day, month);
}

String weekdayLabel(DateTime date, String locale) =>
    DateFormat('EEEE', locale).format(date).toUpperCase();

String weekdayShortLabel(DateTime date, String locale) =>
    DateFormat('EEE', locale).format(date).toUpperCase();

String timeLabel(DateTime date) => '${_pad(date.hour)}:${_pad(date.minute)}';

String fullDateLabel(DateTime date) =>
    '${_pad(date.day)}/${_pad(date.month)}/${date.year}';

String timeAgoLabel(DateTime date, AppLocalizations l10n) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return l10n.dateMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.dateHoursAgo(diff.inHours);
  return l10n.dateDaysAgo(diff.inDays);
}
