/// Status de UMA fase — nunca inferido pelo nome da fase (spec item 8):
/// `active` quando tem confronto/rodada em aberto, `completed` quando tudo
/// já terminou, `upcoming` quando nada começou ainda.
enum StageStatus { upcoming, active, completed }
