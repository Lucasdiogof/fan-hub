import 'package:goias_app/features/match/domain/entities/match.dart';

/// Traduz os códigos curtos de status da API-Football (`NS`, `FT`, `1H`...)
/// pro domínio do app. A UI nunca deve ver essas strings — só [MatchStatus].
class ApiFootballMatchStatusMapper {
  const ApiFootballMatchStatusMapper._();

  static MatchStatus map(String shortCode) {
    switch (shortCode) {
      case 'TBD':
      case 'NS':
        return MatchStatus.scheduled;
      case '1H':
      case '2H':
      case 'ET':
      case 'BT':
      case 'P':
      case 'LIVE':
        return MatchStatus.live;
      case 'HT':
        return MatchStatus.halftime;
      case 'FT':
      case 'AET':
      case 'PEN':
      case 'AWD':
      case 'WO':
        return MatchStatus.finished;
      case 'PST':
        return MatchStatus.postponed;
      case 'CANC':
        return MatchStatus.cancelled;
      case 'ABD':
      case 'SUSP':
      case 'INT':
        return MatchStatus.suspended;
      default:
        return MatchStatus.unknown;
    }
  }
}
