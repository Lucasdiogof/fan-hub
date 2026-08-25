enum PlayerPosition {
  gol,
  zag,
  ld,
  le,
  ald,
  ale,
  vol,
  mc,
  mei,
  pd,
  pe,
  sa,
  ata,
}

extension PlayerPositionLabel on PlayerPosition {
  String get short => switch (this) {
    PlayerPosition.gol => 'GOL',
    PlayerPosition.zag => 'ZAG',
    PlayerPosition.ld => 'LD',
    PlayerPosition.le => 'LE',
    PlayerPosition.ald => 'ALD',
    PlayerPosition.ale => 'ALE',
    PlayerPosition.vol => 'VOL',
    PlayerPosition.mc => 'MC',
    PlayerPosition.mei => 'MEI',
    PlayerPosition.pd => 'PD',
    PlayerPosition.pe => 'PE',
    PlayerPosition.sa => 'SA',
    PlayerPosition.ata => 'ATA',
  };

  String get full => switch (this) {
    PlayerPosition.gol => 'Goleiro',
    PlayerPosition.zag => 'Zagueiro',
    PlayerPosition.ld => 'Lateral-direito',
    PlayerPosition.le => 'Lateral-esquerdo',
    PlayerPosition.ald => 'Ala-direito',
    PlayerPosition.ale => 'Ala-esquerdo',
    PlayerPosition.vol => 'Volante',
    PlayerPosition.mc => 'Meio-campista',
    PlayerPosition.mei => 'Meia',
    PlayerPosition.pd => 'Ponta-direita',
    PlayerPosition.pe => 'Ponta-esquerda',
    PlayerPosition.sa => 'Segundo atacante',
    PlayerPosition.ata => 'Atacante',
  };
}

PlayerPosition? playerPositionFromCode(String code) {
  for (final position in PlayerPosition.values) {
    if (position.name == code) return position;
  }
  return null;
}
