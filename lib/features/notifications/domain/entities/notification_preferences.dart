import 'package:equatable/equatable.dart';

/// Só as 2 chaves da V1 — "Partidas do Goiás" (gol + resultado final) e
/// "Ingressos e check-in" (as 2 formas do mesmo aviso de 48h antes do
/// kickoff, decidido no backend por status de sócio). Sem linha no
/// Supabase é tratado como tudo habilitado (opt-out explícito, nunca
/// opt-in silencioso) — ver `SupabaseNotificationRepository.getPreferences`.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.matchesEnabled = true,
    this.ticketsEnabled = true,
  });

  final bool matchesEnabled;
  final bool ticketsEnabled;

  NotificationPreferences copyWith({
    bool? matchesEnabled,
    bool? ticketsEnabled,
  }) {
    return NotificationPreferences(
      matchesEnabled: matchesEnabled ?? this.matchesEnabled,
      ticketsEnabled: ticketsEnabled ?? this.ticketsEnabled,
    );
  }

  @override
  List<Object?> get props => [matchesEnabled, ticketsEnabled];
}
