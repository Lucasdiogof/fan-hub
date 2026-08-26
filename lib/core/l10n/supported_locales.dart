import 'package:flutter/material.dart';

/// Idiomas que o app oferece no seletor, na ordem em que aparecem.
const kSupportedLocales = <Locale>[
  Locale('pt'),
  Locale('en'),
  Locale('es'),
];

/// Nome de cada idioma no próprio idioma (endônimo) — não é traduzido, é o
/// padrão de seletores de idioma (o usuário reconhece "Español" mesmo com a
/// interface em português).
String languageEndonym(String code) => switch (code) {
  'pt' => 'Português',
  'en' => 'English',
  'es' => 'Español',
  _ => code,
};
