/// Grade de 7 colunas (domingo a sábado) do mês de [month] — só o dia
/// importa em [month] (`day` é ignorado). `null` nas células antes do dia 1
/// e depois do último dia do mês: nunca mostra número de mês vizinho, só
/// espaço vazio (mesmo visual do mockup de referência).
List<DateTime?> monthGridDays(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  // DateTime.weekday: segunda=1 ... domingo=7. Semana começa domingo, então
  // domingo (7) precisa virar 0 células em branco antes do dia 1.
  final leadingBlanks = firstDay.weekday % 7;
  final days = <DateTime?>[
    for (var i = 0; i < leadingBlanks; i++) null,
    for (var day = 1; day <= daysInMonth; day++)
      DateTime(month.year, month.month, day),
  ];
  final trailingBlanks = (7 - days.length % 7) % 7;
  days.addAll(List<DateTime?>.filled(trailingBlanks, null));
  return days;
}

DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month);

DateTime addMonths(DateTime month, int delta) =>
    DateTime(month.year, month.month + delta);
