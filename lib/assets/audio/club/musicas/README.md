# Músicas Esmeraldinas

Coloque aqui os MP3 das músicas esmeraldinas (fora do hino) conforme forem
chegando, e adicione uma entrada nova em
`lib/features/club/data/club_songs_data.dart` para cada uma:

```dart
ClubSong(
  id: 'nome_da_musica',
  title: 'Nome da música',
  artist: 'Artista/identificação',
  category: ClubSongCategory.esmeraldina,
  lyrics: '''
  LETRA AQUI
  ''',
  audioAsset: 'lib/assets/audio/club/musicas/nome_da_musica.mp3',
),
```

O restante da interface (lista, player, página da letra) funciona sozinho —
não é preciso criar widget ou tela nova para cada música.
