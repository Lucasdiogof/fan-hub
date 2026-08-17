const _months = [
  'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN',
  'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ',
];

const _weekdays = [
  'SEGUNDA', 'TERÇA', 'QUARTA', 'QUINTA', 'SEXTA', 'SÁBADO', 'DOMINGO',
];

const _weekdaysShort = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];

const _fullMonths = [
  'JANEIRO', 'FEVEREIRO', 'MARÇO', 'ABRIL', 'MAIO', 'JUNHO',
  'JULHO', 'AGOSTO', 'SETEMBRO', 'OUTUBRO', 'NOVEMBRO', 'DEZEMBRO',
];

String monthLabel(DateTime date) => _fullMonths[date.month - 1];

String _pad(int value) => value.toString().padLeft(2, '0');

String shortDateLabel(DateTime date) => '${_pad(date.day)} ${_months[date.month - 1]}';

String weekdayLabel(DateTime date) => _weekdays[date.weekday - 1];

String weekdayShortLabel(DateTime date) => _weekdaysShort[date.weekday - 1];

String timeLabel(DateTime date) => '${_pad(date.hour)}:${_pad(date.minute)}';

String timeAgoLabel(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
  if (diff.inHours < 24) return '${diff.inHours}h atrás';
  final days = diff.inDays;
  return '$days ${days == 1 ? 'dia' : 'dias'} atrás';
}
