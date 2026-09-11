import 'package:equatable/equatable.dart';

/// Preferências de notificação — 2 categorias NUNCA misturadas:
///
/// * "Jogos ao vivo" — master toggle (`liveMatchesEnabled`) + 6
///   sub-preferências, uma por evento canônico de partida (início, gol do
///   clube, gol adversário, intervalo, início do 2º tempo, fim de jogo).
///   Se o master estiver OFF, nenhum dos 6 é enviado, mesmo que a
///   sub-preferência individual esteja ON (regra do backend, ver
///   `preferenceColumnsFor` em `_shared/recipient_eligibility.ts`).
/// * "Ingressos e check-in" (`ticketsEnabled`) — categoria própria e
///   independente, nunca depende do master de jogos ao vivo.
///
/// Sem linha no Supabase é tratado como tudo habilitado (opt-out
/// explícito, nunca opt-in silencioso) — ver
/// `SupabaseNotificationRepository.getPreferences`.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.liveMatchesEnabled = true,
    this.kickoffEnabled = true,
    this.goalForEnabled = true,
    this.goalAgainstEnabled = true,
    this.halfTimeEnabled = true,
    this.secondHalfStartedEnabled = true,
    this.fullTimeEnabled = true,
    this.ticketsEnabled = true,
  });

  final bool liveMatchesEnabled;
  final bool kickoffEnabled;
  final bool goalForEnabled;
  final bool goalAgainstEnabled;
  final bool halfTimeEnabled;
  final bool secondHalfStartedEnabled;
  final bool fullTimeEnabled;
  final bool ticketsEnabled;

  NotificationPreferences copyWith({
    bool? liveMatchesEnabled,
    bool? kickoffEnabled,
    bool? goalForEnabled,
    bool? goalAgainstEnabled,
    bool? halfTimeEnabled,
    bool? secondHalfStartedEnabled,
    bool? fullTimeEnabled,
    bool? ticketsEnabled,
  }) {
    return NotificationPreferences(
      liveMatchesEnabled: liveMatchesEnabled ?? this.liveMatchesEnabled,
      kickoffEnabled: kickoffEnabled ?? this.kickoffEnabled,
      goalForEnabled: goalForEnabled ?? this.goalForEnabled,
      goalAgainstEnabled: goalAgainstEnabled ?? this.goalAgainstEnabled,
      halfTimeEnabled: halfTimeEnabled ?? this.halfTimeEnabled,
      secondHalfStartedEnabled:
          secondHalfStartedEnabled ?? this.secondHalfStartedEnabled,
      fullTimeEnabled: fullTimeEnabled ?? this.fullTimeEnabled,
      ticketsEnabled: ticketsEnabled ?? this.ticketsEnabled,
    );
  }

  @override
  List<Object?> get props => [
    liveMatchesEnabled,
    kickoffEnabled,
    goalForEnabled,
    goalAgainstEnabled,
    halfTimeEnabled,
    secondHalfStartedEnabled,
    fullTimeEnabled,
    ticketsEnabled,
  ];
}
