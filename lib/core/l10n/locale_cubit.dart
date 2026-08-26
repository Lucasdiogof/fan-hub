import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/locale_preference.dart';

/// Idioma escolhido pelo usuário. `null` = seguir o idioma do aparelho
/// (comportamento padrão do Flutter quando `MaterialApp.locale` é nulo).
class LocaleCubit extends Cubit<Locale?> {
  LocaleCubit() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final code = await LocalePreference.getCode();
    if (code != null) emit(Locale(code));
  }

  Future<void> setLocale(Locale? locale) async {
    await LocalePreference.setCode(locale?.languageCode);
    emit(locale);
  }
}
